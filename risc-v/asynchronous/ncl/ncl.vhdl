-- 2 hot 2 handle
--
-- An NCL bit is basically two rail one-hot specified as such:
--
--   d : std_logic_vector(1 downto 0);
--
--   d = "00" -- NULL
--   d = "10" -- 0, note d(1) = '1', d(0) = '0'
--   d = "01" -- 1
--
-- Our NCL implementation operates as follows:
--
--   entity foo is
--     port( d : (in) ncl_logic(7 downto 0) );
--   end foo;
--
-- d(0)(L) will give the low bit, d(0)(H) will give the high bit,
-- on data bit 0.
library IEEE;
use IEEE.std_logic_1164.all;

type ncl_logic is record
    L : std_logic;
    H : std_logic;
end record;
