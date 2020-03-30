-- ncl_decoder
--
-- Handles encoding from NCL into TTL.
library IEEE;
use IEEE.std_logic_1164.all;

-- NCL decoder entity

entity ncl_decoder is
    generic ( n: positive );
    port(
    d      : (in)  ncl_logic(n-1 downto 0);
    output : (out) std_logic_vector(n-1 downto 0)
    );
end ncl_decoder;

-- Architecture for decoder
-- [0 0] and [1 1] are NULL and invalid, respectively.
--
-- The NCL decode is technically:
--
--   (d(L) XOR d(H)) AND d(L)
--
-- This is implemented as a completion check and output of
-- d(L) as a completed value.  When the value is null or
-- invalid, the output is 'U'; however, the receiving circuit
-- cannot identify 'U' on its input.  The decoder should thus
-- only be used after completion detection on all inputs.
architecture ncl_decoder_arc of ncl_decoder is
    signal dCompletion : std_logic_vector(n-1 downto 0);
begin
    Completion: entity work.ncl_completion(ncl_completion_arc)
      generic map (n           => n)
      port map    (d           => d,
               dCompletion => output);

    process(all)
    begin
        for i in input'range loop
            if (dCompletion(i)) then
                output(i) <= d(i)(L);
            else
                output(i) <= 'U';
            end if;
        end loop;
    end process;
end ncl_decoder_arc;
