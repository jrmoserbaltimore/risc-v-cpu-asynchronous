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
-- Ready and Waiting are TTL, not NCL
library IEEE;
use IEEE.std_logic_1164.all;
use work.ncl.all;

entity ncl_handshake_sender is
	port(
	    Ready   : in  std_logic;
	    Waiting : out std_logic
    );
end ncl_handshake_sender;

entity ncl_handshake_receiver is
    port(
        Ready   : out std_logic;
        Waiting : in  std_logic
    );
end ncl_handshake_receiver;

-- Kind of useless
architecture a_ncl_handshake_sender of ncl_handshake_sender is
begin
    Waiting <= Ready;
end a_ncl_handshake_sender;

architecture a_ncl_handshake_receiver of ncl_handshake_receiver is
begin
    Ready   <= NOT Waiting;
end a_ncl_handshake_receiver;
