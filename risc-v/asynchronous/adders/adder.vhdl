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
    A     : (in)  ncl_logic;
    B     : (in)  ncl_logic;
    Cin   : (in)  ncl_logic;
    Cout  : (out) ncl_logic;
    S     : (out) ncl_logic
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
    P     : (in)  ncl_logic;
    G     : (in)  ncl_logic;
    Pin   : (in)  ncl_logic;
    Gin   : (in)  ncl_logic;
    Pout  : (out) ncl_logic;
    Gout  : (out) ncl_logic
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
    signal AComplete, BComplete, CinComplete : std_logic;
    signal ABLx, ABHx, AllComplete : std_logic;
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (1      => n);
      port map (A         => d;
                AComplete => output);

    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (1      => n);
      port map (B         => d;
                BComplete => output);
      
    CinCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (1        => n);
      port map (Cin         => d;
                CinComplete => output);

    AllComplete <= (AComplete AND BComplete AND CinComplete);
    -- S bit is A XOR B XOR Cin; output NULL if A or B is null
    ABLx <= (A.L XOR B.L);
    ABHx <= (A.H XOR B.H);
    S    <= (L <= (ABLx XOR Cin.L) AND AllComplete,
	     H <= (ABHx XOR Cin.H) AND AllComplete);
    -- Cout is (A AND B) OR ((A XOR B) AND Cin); output NULL if null
    Cout <= (L <= ((ABLx AND Cin.L) OR (A.L AND B.L)) AND AllComplete,
	     H <= ((ABHx AND Cin.H) OR (A.H AND B.H)) AND AllComplete);
end binary_adder_ncl_fulladder_arch;
