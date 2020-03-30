-- ncl_completion
--
-- Determines if an NCL signal is NULL or not.
library IEEE;
use IEEE.std_logic_1164.all;

entity ncl_completion is
    generic ( n: positive );
    port(
    d      : (in)  ncl_logic(n-1 downto 0);
    output : (out) std_logic_vector(n-1 downto 0)
    );
end ncl_completion;

-- Architecture for completion check
-- Note [1 1] is undefined.  Value is available if d0 XOR d1.
--
-- A full completion check for 2 bits looks as follows:
--
--  dH dL dH dL
--    | | | |
--    XOR XOR    --OR gates work as well; d0=d1=1 is undefined
--      | |
--      AND
--       |
--    Complete?
--
-- Asynchronous circuit networks will use this more than the
-- decoder.
architecture ncl_completion_arc of ncl_completion is
begin
    process(all)
    begin
        for i in input'range loop
            output(i) <= d(i)(L) XOR d(i)(H);
        end loop;
    end process;
end ncl_completion_arc;
