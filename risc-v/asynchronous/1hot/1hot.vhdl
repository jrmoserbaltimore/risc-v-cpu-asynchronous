-- 2 hot 2 handle
--
-- Handles encoding and decoding into 1-hot interfaces.
--
-- A one-hot bit is specified as such:
--
--   d : std_logic_vector(1 downto 0);
--
--   d = "00" -- NULL
--   d = "10" -- 0, note d(1) = '1', d(0) <= '0'
--   d = "01" -- 1
library IEEE;
use IEEE.std_logic_1164.all;

-- One-hot encoder/decoder entitites
entity one_hot_encoder is
	port(
	input  : (in)  std_logic;
	d      : (out) std_logic_vector(1 downto 0)
	);
end one_hot_encoder;

entity one_hot_decoder is
	port(
	d      : (in)  std_logic_vector(1 downto 0);
	output : (out) std_logic
	);
end one_hot_decoder;

-- AND/OR/NOT etc.
-- A decode/encode requires separate completion testing:
-- A xor B will be null before propagation, and an encoder
-- will output [1 0], indicating completion.
--
-- That's a lot of overhead: two inverters to encode the
-- output, plus the next circuit must test the two inputs
-- with two XOR gate to determine valid signal.
--
-- Direct one-hot logic performs the test (same two XOR
-- gates) and uses two gates to perform the computation.
-- It's the same amount of overhead, but with simpler
-- code.  Also, you don't have to route the two inputs
-- around the circuit and into the next circuit for;
-- completion detection.
entity one_hot_logic is
	port(
	A      : (in)  std_logic_vector(1 downto 0);
	B      : (in)  std_logic_vector(1 downto 0);
	output : (out) std_logic_vector(1 downto 0)
	);
end one_hot_logic;

entity one_hot_inverter is
	port(
	d      : (in)  std_logic_vector(1 downto 0);
	output : (out) std_logic_vector(1 downto 0)
	);
end one_hot_inverter;

-- Architecture for encoder
architecture one_hot_encoder_arc of one_hot_encoder is
begin
	d(1) <= NOT input;
	d(0) <= input;
end one_hot_encoder_arc;

-- Architecture for decoder
-- Strictly speaking, [0 0] and [1 1] are NULL and invalid,
-- respectively.  This decoder emits 0 unless the output is
-- 1.
--
-- Completion detection is necessary in any case, so some
-- other component must also receive d0 and d1 and validate.
-- With proper testing, the output would be 0 on [0 0], but
-- the circuit would identify that the 0 output is false.
--
-- As such, the one-hot decode is technically:
--
--   (d0 XOR d1) AND d1
--
-- Possibly with an output 'Z' if (d0 XNOR d1).
--
-- Because the circuit can't differentiate between '0' and
-- an incomplete case, d1 is equivalent.
architecture one_hot_decoder_arc of one_hot_decoder is
begin
	output <= d(0);
end one_hot_decoder_arc;

-- Architecture for completion check
-- Note [1 1] is undefined.  Value is available if d0 XOR d1.
--
-- A full completion check for 2 bits looks as follows:
--
--  d0 d1 d0 d1
--    | | | |
--    XOR XOR    --OR gates work as well; d0=d1=1 is undefined
--      | |
--      AND
--       |
--    Complete?
--
-- Asynchronous circuit networks will use this more than the
-- decoder.
architecture one_hot_completion_arc of one_hot_decoder is
begin
	output <= d(0) XOR d(1);
end one_hot_completion_arc;

-- Logical comparisons
-- These implement AND, OR, XOR, and so forth

-- Direct AND in one-hot logic.  Truth table:
--   A     B      AND
-- [1 0] [1 0]   [1 0] = 0
-- [1 0] [0 1]   [1 0] = 0
-- [0 1] [1 0]   [1 0] = 0
-- [0 1] [0 1]   [0 1] = 1
--
-- Note the single-bit truth tables for each line:
--
-- d(1)            d(0)
-- A B  AND  NAND  A B  AND  NAND   One-Hot AND
-- 1 1   1     0   0 0   0    1      [1 0] = 0
-- 1 0   0     1   0 1   0    1      [1 0] = 0
-- 0 1   0     1   1 0   0    1      [1 0] = 0
-- 0 0   0     1   1 1   1    0      [0 1] = 1
--
-- The one-hot AND is thus exclusively:
--
-- [A(0) NAND B(0), A(0) AND B(0)]
architecture one_hot_and of one_hot_logic is
	signal AComplete, Bcomplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);
	BCheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (B      => d;
		    BValid => output);
	-- Clear outputs
	reset: process(all)
	begin
		if (NOT (AComplete AND BComplete)) then
			output <= "00";
		end if;
	end process reset;

	compare: process(all)
	begin
		if (AComplete AND BComplete) then
			-- See truth table above
			output(1) <= A(0) NAND B(0);
			output(0) <= A(0) AND B(0);
		end if;
	end process compare;
end architecture one_hot_and;

-- Direct NAND in one-hot logic.  Inverse of AND.
-- Inverse of AND is exclusively:
--
-- [A(0) AND B(0), A(0) NAND B(0)]
architecture one_hot_nand of one_hot_logic is
	signal AComplete, Bcomplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);
	BCheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (B      => d;
		    BValid => output);

	reset: process(all)
	begin
		if (NOT (AComplete AND BComplete)) then
			output <= "00";
		end if;
	end process reset;

	compare: process(all)
	begin
		if (AComplete AND BComplete) then
			-- See truth table above
			output(1) <= A(0) AND B(0);
			output(0) <= A(0) NAND B(0);
		end if;
	end process compare;
end architecture one_hot_nand;

-- Direct OR in one-hot logic.  Truth table:
--   A     B      OR
-- [1 0] [1 0]   [1 0] = 0
-- [1 0] [0 1]   [0 1] = 1
-- [0 1] [1 0]   [0 1] = 1
-- [0 1] [0 1]   [0 1] = 1
--
-- Note the single-bit truth tables for each line:
--
-- d(1)            d(0)
-- A B  AND  NAND  A B  AND  NAND   One-Hot OR
-- 1 1   1     0   0 0   0    1      [1 0] = 0
-- 1 0   0     1   0 1   0    1      [0 1] = 1
-- 0 1   0     1   1 0   0    1      [0 1] = 1
-- 0 0   0     1   1 1   1    0      [0 1] = 1
--
-- The one-hot OR is thus exclusively:
--
-- [A(1) AND B(1), A(1) NAND B(1)]
architecture one_hot_or of one_hot_logic is
	signal AComplete, BComplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);
	BCheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (B      => d;
		    BValid => output);

	reset: process(all)
	begin
		if (NOT (AComplete AND BComplete)) then
			output <= "00";
		end if;
	end process reset;

	compare: process(all)
	begin
		if (AComplete AND BComplete) then
			-- See truth table above
			output(1) <= A(1) AND B(1);
			output(0) <= A(1) NAND B(1);
		end if;
	end process compare;
end architecture one_hot_or;

-- Direct NOR in one-hot logic.  Inverse of AND.
-- Inverse of OR is exclusively:
--
-- [A(1) NAND B(1), A(1) AND B(1)]
architecture one_hot_nor of one_hot_logic is
	signal AComplete, Bcomplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);
	BCheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (B      => d;
		    BValid => output);

	reset: process(all)
	begin
		if (NOT (AComplete AND BComplete)) then
			output <= "00";
		end if;
	end process reset;

	compare: process(all)
	begin
		if (AComplete AND BComplete) then
			-- See truth table above
			output(1) <= A(1) NAND B(1);
			output(0) <= A(1) AND B(1);
		end if;
	end process compare;
end architecture one_hot_nor;

-- Direct XOR in one-hot logic.  Truth table:
--   A     B      XOR
-- [1 0] [1 0]   [1 0] = 0
-- [1 0] [0 1]   [0 1] = 1
-- [0 1] [1 0]   [0 1] = 1
-- [0 1] [0 1]   [1 0] = 0
--
-- Note the single-bit truth tables for each line:
--
-- d(1)            d(0)
-- A B  XOR  XNOR  A B  XOR  XNOR  One-Hot XOR
-- 1 1   0     1   0 0   0    1      [1 0] = 0
-- 1 0   1     0   0 1   1    0      [0 1] = 1
-- 0 1   1     0   1 0   1    0      [0 1] = 1
-- 0 0   0     1   1 1   0    1      [1 0] = 0
--
-- The one-hot XOR is any of the following:
--
-- [A(n) XNOR B(n), A(m) XOR B(m)]
--
-- m can equal n.
architecture one_hot_xor of one_hot_logic is
	signal AComplete, Bcomplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);
	BCheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (B      => d;
		    BValid => output);

	reset: process(all)
	begin
		if (NOT (AComplete AND BComplete)) then
			output <= "00";
		end if;
	end process reset;

	compare: process(all)
	begin
		if (AComplete AND BComplete) then
			-- See truth table above
			output(1) <= A(0) XNOR B(0);
			output(0) <= A(0) XOR B(0);
		end if;
	end process compare;
end architecture one_hot_xor;

-- Direct XNOR in one-hot logic.  Inverse of XOR.
-- Inverse of XOR is any of:
--
-- [A(n) XOR B(n), A(m) XNOR B(m)]
architecture one_hot_xnor of one_hot_logic is
	signal AComplete, Bcomplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);
	BCheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (B      => d;
		    BValid => output);

	reset: process(all)
	begin
		if (NOT (AComplete AND BComplete)) then
			output <= "00";
		end if;
	end process reset;

	compare: process(all)
	begin
		if (AComplete AND BComplete) then
			-- See truth table above
			output(1) <= A(0) XOR B(0);
			output(0) <= A(0) XNOR B(0);
		end if;
	end process compare;
end architecture one_hot_xnor;

-- NOT operator
architecture one_hot_not of one_hot_inverter is
	signal AComplete : std_logic;
begin
	ACheck: entity work.one_hot_decoder(one_hot_completion_arc)
	  port map (A      => d;
		    AValid => output);

	reset: process(all)
	begin
		if (NOT AComplete) then
			output <= "00";
		end if;
	end process reset;

	invert: process(all)
	begin
		if (AComplete) then
			output <= NOT A;
		end if;
	end process invert;
end architecture one_hot_not;
