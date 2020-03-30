-- ncl_inverter
--
-- Handles NCL NOT operator.
library IEEE;
use IEEE.std_logic_1164.all;

entity ncl_logic_inverter is
    generic( n: positive );
    port(
    d      : (in)  ncl_logic(n-1 downto 0);
    output : (out) ncl_logic(n-1 downto 0)
    );
end ncl_logic_inverter;

-- NOT operator
architecture ncl_not of ncl_logic_inverter is
    signal AComplete : ncl_logic(n-1 downto 0);
begin
    ACheck: entity work.ncl_completion(ncl_completion_arc)
      generic map (n      => n);
      port map (A         => d;
                AComplete => output);

    invert: process(all)
    begin
        for i in A'range loop
            if (AComplete(i)) then
                output(i) <= (H=>NOT A(i)(H),
                              L=>NOT A(i)(L));
            else -- [0 0]
                output(i) <= (H=>'0', L=>'0');
            end if;
        end loop;
    end process invert;
end architecture ncl_not;
