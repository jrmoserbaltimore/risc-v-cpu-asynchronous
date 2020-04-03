Arithmetic Logic Unit
=====================

The ALUs here implement RV32I and RV64I instructions.  Various configurations
may enable multiple copies of particular facilities (adders, multipliers,
incrementers), multi-port ALUs (for SMT or OOE), and other features.

ALUs execute instructions in the order and with the data they are given.
Out-of-order and speculative execution are carried out before sending
instructions to the ALU.
