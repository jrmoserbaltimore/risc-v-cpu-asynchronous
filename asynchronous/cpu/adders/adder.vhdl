-- adder components
--
-- These are parts of adders
library IEEE;
use IEEE.std_logic_1164.all;

-- Binary adder
--
--  Ripple-Carry:
--
--        A   B
--        |   |
--       -------
-- Cout-| Adder |-Cin
--       -------
--          |
--          S
--
-- Parallel prefix:
--
--            A   B
--            |   |
--           -------
-- Cout (G)-| Adder |-Cin (G[n-1])
--           -------
--              |
--              S (P)
--
-- Parallel prefix adder sends P to an XOR gate along with Cin
-- (final output from last stage, so it has the same interface.
-- In architecture, G would be sent to Cout, P sent to MUX.
entity binary_adder_ncl_entity is
port(
    A     : in  work.ncl_logic;
    B     : in  ncl_logic;
    Cin   : in  ncl_logic;
    Cout  : out ncl_logic;
    S     : out ncl_logic
    );
end binary_adder_ncl_entity;

-- There are two forms of this.  All but the last for a given
-- bit are as follows:
--
--  G Gin P Pin
--  | |   | |
--  | AND-| |
--  | |   AND
--  XOR    |
--   |     |
--  Gout  Pout
--
-- The last stage is as follows:
--
--  G Gin P
--  | |   |
--  | AND-
--  | |
--  XOR
--   |
--  Gout
entity binary_adder_pg_mux_ncl_entity is
port (
    P     : in  ncl_logic;
    G     : in  ncl_logic;
    Pin   : in  ncl_logic;
    Gin   : in  ncl_logic;
    Pout  : out ncl_logic;
    Gout  : out ncl_logic
    );
end binary_adder_pg_mux_ncl_entity;

-- A simple full adder.
--
-- A-------A
-- |       N-----
-- | B-----D     |
-- | |           |
-- XOR           |
--   |-------A   |
--   |       N--OR
--   | CIN---D   |
--   | |         |
--   XOR         |
--    |          |
--    S        Cout
--
-- All computations require NCL-complete input signals and pass
-- NULL if any signal is incomplete.  This prevents invalid output.
architecture binary_adder_ncl_fulladder_arch of binary_adder_ncl_entity is
begin
    -- S bit is A XOR B XOR Cin; output NULL if A or B is null
    S    <= A XOR B XOR Cin;
    -- Cout is (A AND B) OR ((A XOR B) AND Cin); output NULL if null
    Cout <= (A AND B) OR ((A XOR B) AND Cin);
end binary_adder_ncl_fulladder_arch;
