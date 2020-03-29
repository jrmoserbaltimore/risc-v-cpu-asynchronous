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
entity binary_adder_onehot_entity is
port(
	A     : (in)  std_logic_vector(1 downto 0);
	B     : (in)  std_logic_vector(1 downto 0);
	Cin   : (in)  std_logic_vector(1 downto 0);
	Cout  : (out) std_logic_vector(1 downto 0);
        S     : (out) std_logic_vector(1 downto 0);
    );
end binary_adder_onehot_entity;

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
entity binary_adder_pg_mux_onehot_entity is
port (
	P     : (in)  std_logic_vector(1 downto 0);
	G     : (in)  std_logic_vector(1 downto 0);
	Pin   : (in)  std_logic_vector(1 downto 0);
	Gin   : (in)  std_logic_vector(1 downto 0);
	Pout  : (out) std_logic_vector(1 downto 0);
	Gout  : (out) std_logic_vector(1 downto 0);
    );
end binary_adder_pg_mux_entity;

-- A simple full adder.
architecture binary_adder_onehot_fulladder_arch of binary_adder_onehot_entity is
	signal Aready, Bready, Cinready : std_logic;
	signal ABa, ABx, Sbit, Coutbit : std_logic;
begin
	-- Initialize when any inputs are null
	reset process(A,B,Cin)
	begin
		if (A = "00"
		 OR B = "00"
		 OR Cin = "00") then
			Cout  <= "00";
			S     <= "00";
		end if;
	end process reset;

	-- Add when none are null
	adder process(A,B,Cin)
	begin
		if ((A(0) XOR A(1) = '1')
		AND (B(0) XOR B(1) = '1')
		AND (Cin(0) XOR Cin(1) = '1')) then
		-- Full adder
		ABx      <= A(0) XOR B(0);
		ABa      <= A(0) AND B(0);
		Sbit     <= ABx XOR Cin(0);
		Coutbit  <= (ABx AND Cin(0)) OR ABa;
                -- FIXME: Use an encoder component
		S(0)     <= S;
		S(1)     <= NOT S;
		Cout(0)  <= Cout;
		Cout(1)  <= NOT Cout;
	end process;
end binary_adder_onehot_fulladder_arch;
