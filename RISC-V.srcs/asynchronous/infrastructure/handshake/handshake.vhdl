-- vim: sw=4 ts=4 et
-- Handshake
--
--      Sender           Receiver
--  _______________   _______________
-- | Ready    (in) |-| Ready   (out) |
-- | Waiting (out) |-| Waiting  (in) |
-- | d[0..x] (out) |=| d[0..x]  (in) |
-- |_______________| |_______________|
--
-- Transitions:
-- W[in]   R[out]   Transition
-- 1       1        R[out] <= 0
-- 0       0        R[out] <= 1
--
-- R[in]   W[out]   Transition
-- 1       0        W[out] <= 1
-- 0       1        W[out] <= 0
--
-- Ready and Waiting are TTL, not NCL:  there is only
-- one valid transition each way on the En input to the
-- handshakes (0 to 1 or 1 to 0).  State cannot go from
-- enabled to null to enabled, because the circuit
-- using the handshake MUST be able to identify with
-- 100% certainty that it's transitioned TO a ready
-- or waiting state and with 100% certainty that it's
-- transitioned TO a not-ready or not-waiting state.
-- This is why the asynchronous circuits using this
-- handshake MUST verify complete data input BEFORE
-- indicating they're no longer Ready (have received
-- the data) AND confirm they've fully flushed the
-- input buffer AND the output NULL BEFORE indicating
-- they ARE ready:  spurious mis-estimates of completion
-- are fatal. 
library IEEE;
use IEEE.std_logic_1164.all;
library async_ncl;
use async_ncl.ncl.all;

entity e_ncl_handshake_sender is
    generic ( n : positive );
	port(
	    Ready     : in  std_logic;
	    -- Output data
	    Dout      : in  ncl_logic_vector(n-1 downto 0);
	    -- Waiting signal
	    Waiting   : out std_logic
    );
end e_ncl_handshake_sender;

library IEEE;
use IEEE.std_logic_1164.all;
library async_ncl;
use async_ncl.ncl.all;

entity e_ncl_handshake_receiver is
    port(
        Ready    : out std_logic;
        -- Enable "Ready" output
        En       : in  std_logic;
        Waiting  : in  std_logic;
        EnOut    : Out std_logic
    );
end e_ncl_handshake_receiver;

architecture ncl_handshake_sender of e_ncl_handshake_sender is
    signal data_complete : std_logic;
    signal data_flushed  : std_logic;
    signal data_complete_a : std_logic_vector(Dout'RANGE);
begin
    -- Track when outgoing data is all not null
    data_complete <= NOT (OR ncl_is_null(Dout));
    
    -- Track when absolutely every outgoing data LINE is '0'
    G1: for i in Dout'RANGE generate
        data_complete_a(i) <= Dout(i).H OR Dout(i).L;
    end generate G1;
    data_flushed  <= NOT (OR data_complete_a);

    -- Signal data is waiting when receiver is Ready AND
    -- our data lines are complete;
    --
    -- Keep signaling data is waiting until our data
    -- lines are flushed.
    --
    -- Circuit must NOT alter incoming data UNTIL the
    -- incoming READY signal is dropped!
    Waiting <=    (Ready   AND data_complete)
               OR (Waiting AND data_flushed);
end ncl_handshake_sender;

architecture ncl_handshake_receiver of e_ncl_handshake_receiver is
begin
    -- Waiting MUST only transition from 0 to 1 when sending Ready!
    -- En should be 1 when ready for new data.
    EnOut   <= Ready AND Waiting AND En; 
    Ready   <= (Waiting NOR (NOT En)) OR (Waiting AND En);
end ncl_handshake_receiver;
