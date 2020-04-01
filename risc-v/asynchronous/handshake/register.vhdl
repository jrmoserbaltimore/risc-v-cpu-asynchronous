-- vim: sw=4 ts=4 expandtab
-- NCL Buffer Register
--
-- INTEGRATION, the VLSI Journal, 59 (2017), 31-41,
-- doi 10.1016/j.vlsi.2017.05.002
-- "Simple Method of Asynchronous Circuits Implementation
-- in Commercial FPGAs" by Zbigniew Hajduk
--
-- The article above describes an Asynchronous Pipeline
-- Register (APR) as a single-ended data bus fed into a
-- network of two comparators, two flip-flops, AND gates,
-- inverters, and three multiplexers.
--
-- That design is not suitable for NULL convention logic.
-- Instead, we use a simpler overall circuit with two D
-- Flip-Flops, two Comparators, an N-Completion circuit,
-- and three AND gates.  This circuit specifically
-- interfaces with our handshake protocol and allows
-- reliable register storage without clock.
library IEEE;
use IEEE.std_logic_1164.all;

entity ncl_dff is
    port (
    D       : (in)  ncl_logic;
    EN, CLR : (in)  std_logic;
    Q       : (out) ncl_logic;
    );
end ncl_dff;

architecture a_ncl_dff of ncl_dff is
begin
    -- A regular D Flip-Flop follows a clock.
    -- This one follows EN and D both: EN means
    -- waiting for state, and will freely and
    -- continuously change state.
    dff: process(all)
    begin
        -- Activating both is not valid!
        if (EN) then
            Q <= D;
        elsif (CLR) then
            -- Clear Q regardless of D
            Q <= '0';
        end if;
    end process dff;
end ncl_dff;

-- Registered logic for wide bus
--
-- When R<='1' and D is NCL-complete, EN is activated
-- on the DFF.
--
-- When D=Q and D is NCL-complete and W<='1', 
entity ncl_logic_registered is
    generic ( n: positive );
    port (
        D          : (in)  ncl_logic(n-1 downto 0);
        -- Receiver R and W, that is, Ready(out) Waiting(in)
        R, W, CLR  : (in)  std_logic;
        Q          : (out) ncl_logic(n-1 downto 0);
        Ready      : (out) std_logic;
    );
end ncl_logic_registered;

architecture a_ncl_logic_registered of ncl_logic_registered is
    -- Input and output are equal (i.e. the input is stored)
    signal dQ_eq             : std_logic_vector(n-1 downto 0);
    -- r AND ncl-complete input
    signal in_ready_complete : std_logic;
begin
    d_ff : entity work.ncl_dff(a_ncl_dff)
end a_ncl_logic_registered;

entity ncl_register is
    generic ( bitwidth: positive );
    port(
    D          : (in)  ncl_logic(n-1 downto 0);
    -- Handshake R (out) and W (in) for receiver
    R, W, CLR  : (in)  std_logic;
    Q          : (out) ncl_logic(n-1 downto 0);
    Stored     : (out) std_logic);
    );
end ncl_register;

architecture a_ncl_register of ncl_register is
    -- ncl_dff input (D) and output (Q) are equal
    -- (i.e. the input signal is stored)
    signal dQ_eq           : std_logic_vector(n-1 downto 0);
    -- r AND ncl-complete input
    signal en_dff          : std_logic;
    signal in_completion   : std_logic_vector(n-1 downto 0);
    -- ncl-complete input AND D and Q equal
    signal eq_and_complete : std_logic;
    -- w AND D and Q equal AND ncl-complete
    signal w_and_ready     : std_logic;
    -- Interception
    signal Qout            : ncl_logic(n-1 downto 0);
begin
    generate_register:
    for i in d'RANGE generate
        dffx: entity ncl_dff(a_ncl_dff)
        port map( D(i)   => D,
                  en_dff => EN,
                  -- CLR is just forwarded straight to the DFF
                  CLR    => CLR,
                  Q(i)   => Qout(i));
    end generate generate_register;

    ncl_completion: entity ncl_completion(ncl_completion_arc)
    generic map (   n => bitwidth );
    port map (      D => D,
               output => in_completion);    

    -- Unary AND operator checks for all bits AND all others
    eq_and_complete <= '1' when (AND dQ_eq = '1')
                           AND (AND in_completion = '1') else
                       '0';
    -- XXX: should EN only activate when in_completion check
    -- passes?  Removing it has the virtue of filling the dff
    -- while waiting for completion on the input, which is
    -- faster.
    --
    -- Handshake protocol allows data in at all times, but
    -- only stores it when R=1, and only sets R=0 when W=1 AND
    -- the data has been stored (i.e. once the data-in lines
    -- can change without impacting the circuit, R <= 0 ).
    --
    -- CLR should never be '1' while R is '1'; however, it is
    -- intended to keep R = '0' until Q reads full NULL, then
    -- set CLR <= '0' and R <= '1'.  This creates a glitch
    -- wherein R propagates more slowly than CLR, so we ignore
    -- R when CLR is set.
    en_dff          <= '1' WHEN R = '1'
                           AND CLR = '0' else
                       '0';
    -- Data is stored.
    --
    -- This only goes to '1' when the data lines are non-NULL
    -- AND the sender has set W='1'.  It tells the circuit we
    -- can set R <= '0' safely. 
    Stored          <= W AND eq_and_complete;
    -- Just connect this (fugly?)
    Q               <= Qout;

    process(all)
    begin
        -- When the flip-flop becomes enabled--in essence,
        -- when R = '1'--we start checking for 
        if (en_dff = '1')
            for i in d'RANGE loop
                dQ_eq(i) = '1' when D(i) = Qout(i) else
                           '0';
            end loop;
        end if;
    end process;

end a_ncl_register;
