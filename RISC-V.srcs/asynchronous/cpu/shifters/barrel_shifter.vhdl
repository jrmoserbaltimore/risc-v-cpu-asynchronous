-- vim: ts=4 sw=4 et
-- Barrel shifter
--
-- n-bit NCL barrel shifter with arithmetic right-shift
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.math_real."ceil";
use ieee.math_real."log2";
library async_ncl;
use async_ncl.ncl.all;

-- NCL 2:1 mux
--
-- Spurious outputs (glitch) happen if you use a non-NCL bit for
-- the shifter, so yes the MUX selector input has to be NCL.
--
--    Bit 1    Bit 0
--    |   |    |   |
--  ------------------
--  \                /-- NCL
--   \     OUT      /---Select
--     ------------
--         | |
--


-- Barrel shifter
--
-- Select bit of '1' selects the left (input) bit.
--
-- bit  4   3   2   1
--      |  -|  -|  -|-   --Arithmetic Shift
--      | | | | | | | | |
--      | | | | | | | AND
--      | | | | | | |  |
--      | | | | | | |  Sx   Sign-extend bit
--      | | | | | | |
--      | | | | | | | Sx
--      | | | | | | | |
--      MUX MUX MUX MUX--Select bit 0 (To all stage-1 MUX)
--      |  -|---+   |
--      | | |  -|---+
--      | | | | |  -|-+---Sx
--      | | | | | | | |
--      MUX MUX MUX MUX--Select bit 1 (To all stage-2 MUX)
--      |   |   |   |
--      |  -|-+-|-+-|-+---Sx
--      | | | | | | | |
--      MUX MUX MUX MUX--Select bit 2 (To all stage-3 MUX)
--       |   |   |   |
--
-- In theory, it's faster to take the first stage if the shift is
-- all off or all on, but that's more tests and gates.
--
-- Barrel shifter r2 only has to be log(xlen), e.g 5 for 32-bit,
-- 6 for 64-bit, 7 for 128-bit.
entity e_barrel_shifter_ncl is
-- Only feed this a power of 2!
    generic ( XLEN      : positive;
              BitWidths : positive);
    port(
        Din        : in  ncl_logic_vector(XLEN-1 downto 0);
        Shift   : in  ncl_logic_vector(integer(ceil(log2(real(XLEN))))-1 downto 0);
        ShRight    : in  ncl_logic;
        Arithmetic : in  ncl_logic;
        BitWidth   : in  ncl_logic_vector(BitWidths-1 downto 0);
        Dout       : out ncl_logic_vector(XLEN-1 downto 0)
    );
end e_barrel_shifter_ncl;

-- All computations require NCL-complete input signals and pass
-- NULL if any signal is incomplete.  This prevents invalid output.
--
-- This barrel shifter is reversible by using n muxes on input and
-- output to reverse the bit order (reverse input, shift left,
-- reverse output).
architecture barrel_shifter_ncl of e_barrel_shifter_ncl is
    type tree_array is array (Shift'HIGH downto SHIFT'LOW-1) of ncl_logic_vector(XLEN-1 downto 0);
    signal tree : tree_array := (others => (others => ('0', '0')));
    signal SignEx : ncl_logic;
    signal result : ncl_logic_vector(XLEN-1 downto 0);
begin
    
    -- This thing is actually inherently combinatorial
    barrel: process(all) is
    variable BWNumeric : integer := 0;
    variable MSBidx    : integer := XLEN-1;
    begin
        -- Find the bit divisor
        -- If the MSB in BitWidth is set, then use full width.
        -- If MSB-1 is set, half width.
        -- If MSB-2, quarter width.
        -- So on.
        --
        -- This works by returning 0, 1, and 2, respectively,
        -- for the three above.  2**0 = 1, 2**1 = 2, 2**2 = 4.
        -- This gives us both results. 
        for i in BitWidth'HIGH downto BitWidth'LOW loop
            if (BitWidth(i) = '1') then
                BWNumeric := BitWidth'HIGH - i;
                exit;
            end if;
        end loop;
        
        -- Figure out the index of the most significant bit
        --
        -- e.g. RV128I and we're doing a 32-bit shift:
        --   BitWidth = "001"
        --   BWHigh   = 2 - 0 = 2
        --   Din(((127+1) / (2^^2)) - 1)
        --     = Din((128 / 4) - 1)
        --     = Din(31)   -- i.e. (31 downto 0) 
        MSBidx := ((Din'HIGH+1) / (2**BWNumeric)) - 1;
 
        --  SignBit Arithmetic
        --        | |
        --        AND ShRight
        --          | |
        --          AND
        --           |
        --          All shifted-out MUXes
        --
        -- NULL if any of these are NULL, so incorporates the
        -- ShRight check.
        SignEx          <= Din(MSBidx) AND Arithmetic AND ShRight;

        if (ncl_is_null(BitWidth) OR ncl_is_null(SignEx)) then
             -- if we don't check this, we might just use BWNumeric
             -- as derived above erroneously and get bad results.
             -- Same if we never check Arithmetic and ShRight.
             --
             -- Until then we null the top of the tree, since no
             -- actual combinatorial circuit along the way CHECKS
             -- if BitWidth is null, and so will produce spurious
             -- non-null output otherwise.
             tree(-1) <= (others => ('0','0'));
        elsif (Shift(Shift'HIGH - BWNumeric) = '1') then
            -- If last shift bit is high, it shifts out to zero, so
            -- just set all output to zero.  Also true if arithmetic.
            --
            -- Fun fact: no matter what the input, this is the
            -- result; so it's actually reasonable to drop the
            -- Ready signal and tell the component sending the
            -- shift that you've received the data as soon as
            -- Shift() has that bit on.
            --
            -- This also applies in lower XLEN, such as when
            -- a 64-bit processor running in 32-bit mode 
            -- or calling a 32-bit shift sets bit 6 rather.
            -- For narrower BitWidth, this does exactly that,
            -- e.g. 1/4 width BWNumeric = 2, so instead of
            -- bit 8 in 128-bit, we check bit 6 (32-bit)
            --
            -- THIS IS A 0 OUTPUT, NOT A NULL OUTPUT.
            Dout <= (others => ncl_encode('0'));
        else
            if (ShRight = '0') then
                -- Put Din into the top of the tree to avoid breaking out special
                -- handling for the first row.  The "top" is basically tree(-1).
                tree(Shift'LOW-1) <= Din;
            elsif (ShRight = '1') then
                -- Put it in backwards.  This should just be a row of muxes.
                for j in Din'RANGE loop
                    
                    -- Assign Din(0) to tree(-1)(127)
                    -- Assign SignEx to tree(-1)(32) when we're using 32-bit
                    -- instructions or modes on 64-bit or 128-bit platforms
                    -- etc.
                    --
                    -- Accordingly, we want the most significant bit down.
                    tree(Shift'LOW-1)(Din'HIGH - j) <=      SignEx WHEN j > MSBidx
                                                       ELSE Din(j);
                end loop;
            end if;

            -- It's going to compute them all in parallel;
            -- combinatorial logic is not any faster by using
            -- j in MSBidx downto 0            
            for i in Shift'HIGH - BWNumeric downto Shift'LOW loop
                for j in Din'RANGE loop
                    if (j <= 2**i) then
                        -- Sign-extend
                        -- This will actually test the Arithmetic and
                        -- ShRight bits for non-NULL status.
                        tree(i)(j) <=    (tree(i-1)(j) AND NOT Shift(i))
                                            OR (SignEx AND Shift(i));
                    else
                        -- This part will NOT check Arithmetic or
                        -- ShRight, which can lead to spurious outputs in
                        -- contrived situations given valid input and handshake,
                        -- hence the explicit SignEx NULL check above. 
                        --
                        -- If shift bit not on, take this column;
                        -- if shift on, take the column 2**i to the right
                        tree(i)(j) <=    (tree(i-1)(j) AND NOT Shift(i))
                                            OR (tree(i-1)(j-2**i) AND Shift(i));
                    end if;
                end loop;
            end loop;
            if (ShRight = '0') then
                -- Shift left doesn't care about the rest of the register
                Dout <= tree(Shift'HIGH - BWNumeric);
            else
                -- We have to reverse the lowest bits below MSBidx.
                for j in MSBidx downto 0 loop
                    Dout(MSBidx - j) <= tree(Shift'HIGH - BWNumeric)(j);
                end loop;
            end if;
        end if;
    end process barrel;
end barrel_shifter_ncl;
