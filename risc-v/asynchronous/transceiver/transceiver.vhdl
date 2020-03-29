-- Synchronous-Asynchronous Transceiver 
--
-- Connects to/from a synchronous interface.
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

entity transceiver_from_sync_entity is
	port(
	clk   : in  std_logic;
	din   : in  std_logic;
	dout  : out std_logic_vector(1 downto 0);
	);
end transceiver_from_sync_entity;

entity transceiver_to_sync_entity is
	port(
	clk   : in  std_logic;
	din   : in  std_logic_vector(1 downto 0);
	dout  : out std_logic;
	S     : out std_logic;
	);
end transceiver_to_sync_entity;

architecture transceiver_from_sync_arch of transceiver_from_sync_entity is
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			dout(1) <= NOT din;
			dout(0) <= din;
		end if;
		if (falling_edge(clk)) then
			dout <= "00";
		end if;
	end process;
end transceiver_from_sync_arch;

architecture transceiver_to_sync_arch of transceiver_to_sync_entity is
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (din(0) XOR din(1) = '1') then
			dout <= din(0);
			S    <= '1';
		end if;
		if (falling_edge(clk)) then
			S <= '0';
		end if;
	end process;
end transceiver_to_sync_arch;
