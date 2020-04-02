-- ncl_logic_operator
--
-- Handles logic operations in NCL.
library IEEE;
use IEEE.std_logic_1164.all;

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
-- around the circuit and into the next circuit for
-- completion detection.
entity ncl_logic_operator is
    generic ( n: positive );
    port(
    A      : (in)  ncl_logic(n-1 downto 0);
    B      : (in)  ncl_logic(n-1 downto 0);
    output : (out) ncl_logic(n-1 downto 0)
    );
end ncl_logic_operator;

-- Logical comparisons
-- These implement AND, OR, XOR, and so forth directly in NCL.
-- Note when '0' or '1', the low bit is the decoded value.
--  Therefor, all logic is:
--
--    H <= A.L N<operator> B.L,
--    L <= A.L <operator>  B.L
architecture ncl_and of ncl_logic_operator is
    signal AComplete, Bcomplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);
    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (B         => d;
                BComplete => output);

    compare: process(all)
    begin
	-- Basically (A.L NAND B.L)
	--       AND (A.L XOR A.H)
	--       AND (B.L XOR B.H)
	-- gives the high bit.
        for i in A'range loop
            if (AComplete(i) AND BComplete(i)) then
                output(i) <= (H=>A.L NAND B.L,
                              L=>A.L AND  B.L);
            else
                -- Output [0 0] on any incomplete inputs.
                -- Downstream circuit should wait for completion
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process compare;
end architecture ncl_and;

-- Direct NAND in NCL.
architecture ncl_nand of ncl_logic_operator is
    signal AComplete, Bcomplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);
    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (B         => d;
                BComplete => output);

    compare: process(all)
    begin
        for i in A'range loop
            if (AComplete(i) AND BComplete(i)) then
                output(i) <= (H=>A.L AND  B.L,
                              L=>A.L NAND B.L);
            else -- [0 0]
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process compare;
end architecture ncl_nand;

-- Direct OR in NCL.
architecture ncl_or of ncl_logic_operator is
    signal AComplete, Bcomplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);
    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (B         => d;
                BComplete => output);

    compare: process(all)
    begin
        for i in A'range loop
            if (AComplete(i) AND BComplete(i)) then
                output(i) <= (H=>A.L NOR B.L,
                              L=>A.L OR  B.L);
            else -- [0 0]
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process compare;
end architecture ncl_or;

-- Direct NOR in NCL
architecture ncl_nor of ncl_logic_operator is
    signal AComplete, Bcomplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);
    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (B         => d;
                BComplete => output);

    compare: process(all)
    begin
        for i in A'range loop
            if (AComplete(i) AND BComplete(i)) then
                output(i) <= (H=>A.L OR  B.L,
                              L=>A.L NOR B.L);
            else -- [0 0]
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process compare;
end architecture ncl_nor;

-- Direct XOR in NCL.
architecture ncl_xor of ncl_logic_operator is
    signal AComplete, Bcomplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);
    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (B         => d;
                BComplete => output);

    compare: process(all)
    begin
        for i in A'range loop
            if (AComplete(i) AND BComplete(i)) then
                output(i) <= (H=>A.L XNOR B.L,
                              L=>A.L XOR  B.L);
            else -- [0 0]
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process compare;
end architecture ncl_xor;

-- Direct XNOR in NCL.
architecture ncl_xnor of ncl_logic_operator is
    signal AComplete, Bcomplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);
    BCheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (B         => d;
                BComplete => output);

    compare: process(all)
    begin
        for i in A'range loop
            if (AComplete(i) AND BComplete(i)) then
                output(i) <= (H=>A.L XOR  B.L,
                              L=>A.L XNOR B.L);
            else -- [0 0]
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process compare;
end architecture ncl_xnor;
