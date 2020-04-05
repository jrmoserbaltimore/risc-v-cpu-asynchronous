-- vim: ts=4 sw=4 et
-- Barrel shifter
--
-- n-bit NCL barrel shifter with arithmetic right-shift
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.math_real."ceil";
use ieee.math_real."log2";

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
    generic map ( n : positive );
    port(
        Din     : in  ncl_logic_vector(n-1 downto 0);
        Shift   : in  ncl_logic_vector(integer(ceil(log2(real(n))))-1 downto 0);
        ShRight : in  ncl_logic;
        Arithmetic : in ncl_logic;
        Dout    : out ncl_logic_vector(n-1 downto 0)
    );
end e_barrel_shifter_ncl;

-- All computations require NCL-complete input signals and pass
-- NULL if any signal is incomplete.  This prevents invalid output.
--
-- This barrel shifter is reversible by using n muxes on input and
-- output to reverse the bit order (reverse input, shift left,
-- reverse output).
architecture a_barrel_shifter_ncl of e_barrel_shifter_ncl is
    type tree_array is array (Shift'RANGE) of ncl_logic_vector(n-1 downto 0);
    signal tree : tree_array := (others => (H<='0', L<='0'));
    signal SignEx : ncl_logic;
begin
    --  SignBit Arithmetic
    --        | |
    --        AND ShRight
    --          | |
    --          AND
    --           |
    --          All shifted-out MUXes
    SignEx <= Din(Din'HIGH) AND Arithmetic AND ShRight;

    -- This thing is actually inherently combinatorial
    barrel: process(all) is
    begin
        if (Shift'HIGH = '1') then
            -- If last shift bit is high, it shifts out to zero, so
            -- just set all output to zero.  Also true if arithmetic.
            Dout <= (others <= (H <= '0', L <= '0'));
        else
            for i in Shift'RANGE loop
                for j in Din'RANGE loop
                    -- First row from Din
                    if (i = '0' and ShRight = '0') then
                        -- Shift left
                        if (j <= 2**i) then
                            -- SignEx is always zero here anyway.
                            -- SignEx
                            tree_array(i)(j) <=    (Din(j) AND NOT Shift(i))
                                                OR (SignEx AND Shift(i));
                        else
                            -- If shift bit not on, take this column;
                            -- if shift bit on, take the column 2**i right
                            tree_array(i)(j) <=    (Din(j) AND NOT Shift(i))
                                                OR (Din(j-2**i) AND Shift(i));
                        end if;
                    elsif (i = '0' and ShRight = '1') then
                        -- Shift right
                        if (j <= 2**i) then
                            -- First row from Din, reversed
                            -- Possibly sign-extend
                            tree_array(i)(j) <=    (Din(Din'HIGH - j)
                                                    AND NOT Shift(i))
                                                OR ((SignEx) AND Shift(i));
                        else
                            -- If shift bit not on, take this column;
                            -- if shift bit on, take the column 2**i to the right
                            tree_array(i)(j) <=    (Din(Din'HIGH - j)
                                                    AND NOT Shift(i))
                                                OR (Din(Din'HIGH - (j-2**i))
                                                    AND Shift(i));
                        end if;
                    elsif (i = Shift'HIGH) then
                        -- Final row, already handled if the shift bit is on.
                        -- Reverse back to normal if shifting right.
                        if (ShRight = '0') then
                            Dout <= tree_array(i-1)(j);
                        elsif (ShRight = '1') then
                            Dout <= tree_array(i-1)(Din'HIGH - j);
                        end if;
                    else
                        if (j <= 2**i) then
                            -- Sign-extend
                            tree_array(i)(j) <=    (tree_array(i-1)(j)
                                                    AND NOT Shift(i))
                                                OR (SignEx AND Shift(i));
                        else
                            -- If shift bit not on, take this column;
                            -- if shift on, take the column 2**i to the right
                            tree_array(i)(j) <=    (tree_array(i-1)(j)
                                                    AND NOT Shift(i))
                                                OR (tree_array(i-1)(j-2**i)
                                                    AND Shift(i));
                        end if;
                    end if;
                end loop;
            end loop;
        end if;
    end process barrel;
end a_barrel_shifter_ncl;
