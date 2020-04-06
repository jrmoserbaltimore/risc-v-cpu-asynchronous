-- vim: sw=4 ts=4 et
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
use work.ncl.all;

entity e_ncl_dff_array is
    generic ( n: positive );
    port (
        D       : in  ncl_logic_vector(n-1 downto 0);
        EN, CLR : in  std_logic;
        Q       : out ncl_logic_vector(n-1 downto 0)
    );
end e_ncl_dff_array;

architecture ncl_dff_array of e_ncl_dff_array is
begin
    -- A regular D Flip-Flop follows a clock.
    -- This one follows EN and D both: EN means
    -- waiting for state, and will freely and
    -- continuously change state.
    dff: process(all)
    begin
        -- Activating both is not valid! In practice, favors CLR
        if (CLR) then
            -- Clear Q to all NULL regardless of D
            Q <= (others => ('0', '0'));
        elsif (EN) then
            Q <= D;
        end if;
    end process dff;
end ncl_dff_array;

library IEEE;
use IEEE.std_logic_1164.all;
use work.ncl.all;
-- Registered logic for wide bus
--
-- When R<='1' and D is NCL-complete, EN is activated
-- on the DFF.
--
-- When D=Q and D is NCL-complete and W<='1', 
entity e_ncl_logic_register is
    generic ( n: positive );
    port (
        D          : in  ncl_logic_vector(n-1 downto 0);
        -- Receiver R and W, that is, Ready(out) Waiting(in)
        R, W, CLR  : in  std_logic;
        Q          : out ncl_logic_vector(n-1 downto 0);
        Stored     : out std_logic
    );
end e_ncl_logic_register;

use work.e_ncl_dff_array;
use work.ncl.all;
-- n-bit delay-insensitive asynchronous register
architecture ncl_logic_register of e_ncl_logic_register is
    -- On when time to enable the DFF array
    signal en_dff            : std_logic;
begin
    dff_array: entity e_ncl_dff_array(ncl_dff_array)
    generic map ( n      => n )
    port map    ( D      => D,
                  EN     => en_dff,
                  CLR    => CLR,
                  Q      => Q);
   
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
    --
    -- Adding AND NOT Stored would tend to cut off EN just
    -- slightly earlier: Stored <= '1' has to propagate for
    -- R <= '0', which has to propagate through the AND gate
    -- to set EN <= '0'.
    en_dff <= '1' when R AND (NOT CLR) else
              '0';

    -- D and Q must be distinct signals
    Stored <= '1' when (NOT ncl_is_null(D)) AND (D = Q) AND W = '1' else
              '0';
end ncl_logic_register;
