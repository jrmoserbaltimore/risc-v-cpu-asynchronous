-- 2 hot 2 handle
--
-- Handles encoding and decoding into 1-hot interfaces.
library IEEE;
use IEEE.std_logic_1164.all;

-- One-hot encoder/decoder entitites
entity one_hot_encoder is
	port(
	input  : in  std_logic;
	d0     : out std_logic;
	d1     : out std_logic
	);
end one_hot_encoder;

entity one_hot_decoder is
	port(
	d0     : in  std_logic;
	d1     : in  std_logic;
	output : out std_logic
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
	A0      : in  std_logic;
	A1      : in  std_logic;
	B0      : in  std_logic;
	B1      : in  std_logic;
	output0 : out std_logic;
	output1 : out std_logic
	);
end one_hot_logic;

entity one_hot_inverter is
	port(
	d0      : in  std_logic;
	d1      : in  std_logic;
	output0 : out std_logic;
	output1 : out std_logic
	);
end one_hot_inverter;
-- Architecture for encoder

architecture one_hot_encoder_arc of one_hot_encoder is
begin
	d0 <= NOT input;
	d1 <= input;
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
	output <= d1;
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
	output <= d0 XOR d1;
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
--  d0              d1
-- A B  AND  NAND  A B  AND  NAND   One-Hot AND
-- 1 1   1     0   0 0   0    1      [1 0] = 0
-- 1 0   0     1   0 1   0    1      [1 0] = 0
-- 0 1   0     1   1 0   0    1      [1 0] = 0
-- 0 0   0     1   1 1   1    0      [0 1] = 1
--
-- The one-hot AND is thus exclusively:
--
-- [A1 NAND B1, A1 AND B1]
architecture one_hot_and of one_hot_logic is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		-- FIXME: replace these with one_hot_completion
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- See truth table above
		output0 <= A1 NAND B1;
		output1 <= A1 AND B1;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
end architecture one_hot_and;

-- Direct NAND in one-hot logic.  Inverse of AND.
-- Inverse of AND is exclusively:
--
-- [A1 AND B1, A1 NAND B1]
architecture one_hot_nand of one_hot_logic is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- See truth table above
		output0 <= A1 AND B1;
		output1 <= A1 NAND B1;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
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
-- A B  AND  NAND  A B  AND  NAND   One-Hot OR
-- 1 1   1     0   0 0   0    1      [1 0] = 0
-- 1 0   0     1   0 1   0    1      [0 1] = 1
-- 0 1   0     1   1 0   0    1      [0 1] = 1
-- 0 0   0     1   1 1   1    0      [0 1] = 1
--
-- The one-hot OR is thus exclusively:
--
-- [A0 AND B0, A0 NAND B0]
architecture one_hot_or of one_hot_logic is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- See truth table above
		output0 <= A0 AND B0;
		output1 <= A0 NAND B0;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
end architecture one_hot_or;

-- Direct NOR in one-hot logic.  Inverse of AND.
-- Inverse of OR is exclusively:
--
-- [A0 NAND B0, A0 AND B0]
architecture one_hot_nor of one_hot_logic is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- See truth table above
		output0 <= A0 NAND B0;
		output1 <= A0 AND B0;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
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
-- A B  XOR  XNOR  A B  XOR  XNOR  One-Hot XOR
-- 1 1   0     1   0 0   0    1      [1 0] = 0
-- 1 0   1     0   0 1   1    0      [0 1] = 1
-- 0 1   1     0   1 0   1    0      [0 1] = 1
-- 0 0   0     1   1 1   0    1      [1 0] = 0
--
-- The one-hot XOR is any of the following:
--
-- [A1 XNOR B0, A0 XOR B0]
-- [A1 XNOR B1, A1 XOR B1]
architecture one_hot_xor of one_hot_logic is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- See truth table above
		output0 <= A0 XNOR B0;
		output1 <= A0 XOR B0;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
end architecture one_hot_xor;

-- Direct XNOR in one-hot logic.  Inverse of XOR.
-- Inverse of XOR is any of:
--
-- [A0 XOR B0, A0 XNOR B0]
-- [A1 XOR B1, A1 XNOR B1]
architecture one_hot_xnor of one_hot_logic is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- See truth table above
		output0 <= A0 XOR B0;
		output1 <= A0 XNOR B0;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
end architecture one_hot_xnor;

architecture one_hot_not of one_hot_inverter is
begin
	process
	begin
		-- Clear outputs
		output0 <= '0';
		output1 <= '0';
		-- Wait for [0 1] or [1 0]
		wait until A0 XOR A1 = '1' and B0 XOR B1 = '1';
		-- invert
		output0 <= NOT d0;
		output1 <= NOT d1;
		-- Wait until one of the inputs is gone before
		-- clearing outputs
		wait until (A0 XOR A1 = '0') OR (B0 XOR B1 = '0')
	end process;
end architecture one_hot_not;
