-- ncl_encoder
--
-- Handles encoding from TTL into NCL.
library IEEE;
use IEEE.std_logic_1164.all;

-- NCL encoder entity
entity ncl_encoder is
    generic ( n: positive );
    port(
    input  : (in)  std_logic_vector(n-1 downto 0);
    d      : (out) ncl_logic(n-1 downto 0)
    );
end ncl_encoder;

-- Architecture for encoder
architecture ncl_encoder_arc of ncl_encoder is
begin
    process(all)
    begin
        for i in input'range loop
            d(i)(H) <= NOT input(i);
            d(i)(L) <= input(i);
        end loop;
    end process;
end ncl_encoder_arc;

