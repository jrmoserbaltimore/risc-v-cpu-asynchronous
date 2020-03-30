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
	generic( n: positive );
	port(
	clk   : (in)  std_logic;
	din   : (in)  std_logic_vector(n-1 downto 0);
	dout  : (out) ncl_logic(n-1 downto 0);
	);
end transceiver_from_sync_entity;

-- From NCL to clocked
entity transceiver_to_sync_entity is
	generic ( n: positive );
	port(
	clk   : in  std_logic;
	din   : in  ncl_logic(n-1 downto 0);
	dout  : out std_logic_vector(n-1 downto 0);
	-- Write signal
	wr    : out std_logic;
	);
end transceiver_to_sync_entity;

architecture transceiver_from_sync_arch of transceiver_from_sync_entity is
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			for i in din'range loop
				-- 0 => [1 0]
				-- 1 => [0 1]
				dout(i) <= ( H=> NOT din(i), L => din(i) );
			end loop;
		elsif (falling_edge(clk)) then
			dout <= "00";
		end if;
	end process;
end transceiver_from_sync_arch;

architecture transceiver_to_sync_arch of transceiver_to_sync_entity is
	signal dComplete : ncl_logic(n-1 downto 0);
begin
	dCheck: entity work.ncl_completion(ncl_completion_arc)
		generic map (n      => n);
		port map (din       => d;
			      dComplete => output);	 

	process(clk)
	begin
		variable fullyComplete : std_logic;
		if (rising_edge(clk)) then
			fullyComplete := '1';
			for i in range'dComplete loop
				if (dComplete(i)) then
					dout(i) <= din(i)(L);
				else -- Incomplete, so don't send
					fullyComplete := '0';
					exit;
				end if;
			end loop;
			wr <= fullyComplete;
		elsif (falling_edge(clk)) then
			wr <= '0';
		end if;
	end process;
end transceiver_to_sync_arch;
