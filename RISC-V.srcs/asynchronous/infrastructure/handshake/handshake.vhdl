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
	port(
	    Ready     : in  std_logic;
	    -- Enable "Waiting" output
	    En        : in  std_logic;
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
        Waiting  : in  std_logic
    );
end e_ncl_handshake_receiver;

-- Kind of useless
architecture ncl_handshake_sender of e_ncl_handshake_sender is
begin
    -- Only raise Waiting when the cicruit has indicated doing
    -- so will not cause erroneous state AND when the Ready
    -- signal is sent by the recipient.
    --
    -- Waiting will be suppressed until the recipient sends
    -- Ready.
    
    -- ONLY when Waiting is '0', it will transition to '1'
    -- when both the receiver is ready to receive AND the
    -- circuit (sender) has indicated readiness to send.
    handshake_sender: process(all) is
    begin
        if (Waiting = '0') then
            -- ONLY when Waiting is off:
            -- Other circuit is ready AND this circuit is
            -- is ready to send.
            --
            -- State change:  R=1, W=0, En=1 => W=1
            Waiting <= Ready AND En;
        elsif (Waiting = '1') then
            -- ONLY when Waiting is being sent:
            -- Other circuit is no longer ready AND this
            -- circuit has stopped enabling Send.
            --
            -- This requires En to drop before Waiting
            -- will drop, otherwise Ready can immediately
            -- come back before En drops and cause error.
            --
            -- State change: R=0, W=1, En=0 => W=0
            Waiting <= NOT (Ready OR En);
        end if;
    end process handshake_sender;
end ncl_handshake_sender;

architecture ncl_handshake_receiver of e_ncl_handshake_receiver is
begin
    Ready   <= NOT Waiting;
    
    handshake_receiver: process(all) is
    begin
        if (Ready = '0') then
            -- ONLY when Ready is off:
            -- Other circuit does not have data waiting on the bus
            -- AND this circuit (receiver) is ready to receive data.
            --
            -- State change: R=0, W=0, En=1 => R=1
            Ready <= (NOT Waiting) AND En;
        elsif (Ready = '1') then
            -- ONLY when Ready is being sent:
            -- Other circuit is no longer ready AND this
            -- circuit has stopped enabling Send.
            --
            -- This requires En to drop before Ready will
            -- drop AND Waiting to be high.
            --
            -- State change: R=1, W=1, En=0 => R=0
            Ready <= (NOT Waiting) OR En;
        end if;
    end process handshake_receiver;
end ncl_handshake_receiver;
