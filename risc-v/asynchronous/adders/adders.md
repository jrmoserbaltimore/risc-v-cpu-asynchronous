Adders
======

Various adders are available, using various amount of space and operating
at various speeds.

# Speculative Adders

Speculative adders take up additional space, but operate at higher frequencies.
They can run at higher fmax in synchronous circuits, and in less time in
asynchronous circuits.

Asynchronous adders require additional space, but have enormous advantages in
asynchronous circuits.

In synchronous circuits, if the fmax of the adder is higher than the fmax of
the CPU in general, the adder can be clocked higher and latch its output to
provide the addition in one CPU clock cycle instead of two when speculation
produces error.  Speculative adders have an error probability on the order of
10^-5, so this rarely happens and is not worth the additional space.

In a CPU with an asynchronous pipeline, a clocked speculative adder can run at
high speed to the same benefit, with a clock rate independent of the CPU.  An
asynchronous speculative adder can return a result immediately upon completion,
with negligible additional delay when speculation fails.  Synchronous
speculative adders with lower delay but higher error probability can require
several clock cycles to recover; while asynchronous highly-speculative adders
can take advantage of early completion.

## Han-Carlson

The Han-Carlson Speculative Adder shortens the critical path by one stage.  It
detects and corrects for error in the rare case of an error.  This adder
consumes minimal area and has a high fmax.
