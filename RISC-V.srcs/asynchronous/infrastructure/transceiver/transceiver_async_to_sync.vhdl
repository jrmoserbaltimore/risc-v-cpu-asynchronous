-- vim: sw=4 ts=4 et
-- Synchronous-Asynchronous Transceiver 
--
-- Connects to/from a synchronous interface.
--
-- Sync to Async
--
-- Theory of operation:
--
-- An asynchronous interface recognizes when data is ready and negotiates
-- completion state continuously.  Synchronous circuits rely on a clock
-- timed to at least the delay of the circuits.
--
-- An asynchronous interface is delay-insensitive and can wait forever for
-- input or for a neighboring circuit to be ready to receive input.  As
-- such, any asynchronous circuit can synchronize to a clock and interface
-- with other asynchronous circuits via the asynchronous protocol, only
-- experiencing additional delay.
--
-- Interfacing between asynchronous and synchronous circuits only requires
-- an asynchronous circuit clocked to the synchronous circuit.  The client
-- circuits only connect to their respective interfaces, thus translating
-- between the two.
library IEEE;
use IEEE.std_logic_1164.all;
use work.ncl.all;

entity e_transceiver_async_to_sync is
    generic( n: positive );
    port(
    clk   : in  std_logic;
    din   : in  ncl_logic_vector(n-1 downto 0);
    dout  : out std_logic_vector(n-1 downto 0);
    -- Write signal
    wr    : out std_logic
    );
end e_transceiver_async_to_sync;

-- FIXME:  these need a complete transceiver architecture with
-- an appropriate handshake.

architecture transceiver_async_to_sync of e_transceiver_async_to_sync is
begin
    process(clk)
    begin
        if (rising_edge(clk) and not ncl_is_null(din)) then
            dout <= ncl_decode(din);
            wr   <= '1';
        elsif (falling_edge(clk)) then
            wr   <= '0';
        end if;
    end process;
end transceiver_async_to_sync;
