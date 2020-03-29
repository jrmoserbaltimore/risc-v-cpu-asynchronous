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
entity binary_adder_onehot is
port(
	A0    : (in)  std_logic;
        A1    : (in)  std_logic;
	B0    : (in)  std_logic;
	B1    : (in)  std_logic;
	Cin0  : (in)  std_logic;
	Cin1  : (in)  std_logic;
	Cout0 : (out) std_logic;
	Cout1 : (out) std_logic;
        S0    : (out) std_logic;
        S1    : (out) std_logic;
    );
end binary_adder_onehot;

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
entity binary_adder_pg_mux_onehot is
port (
	P0    : (in)  std_logic;
	P1    : (in)  std_logic;
	G0    : (in)  std_logic;
	G1    : (in)  std_logic;
	Pin0  : (in)  std_logic;
	Pin1  : (in)  std_logic;
	Gin0  : (in)  std_logic;
	Gin1  : (in)  std_logic;
	Pout0 : (out) std_logic;
	Pout1 : (out) std_logic;
	Gout0 : (out) std_logic;
	Gout1 : (out) std_logic;
    );
end binary_adder_pg_mux;

architecture binary_adder_onehot_arch of binary_adder_onehot is
begin
end binary_adder_oneht_arch;
