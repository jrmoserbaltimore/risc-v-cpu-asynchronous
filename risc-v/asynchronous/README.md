Asynchronous CPU Components
===========================

These CPU components are asynchronous.  They include adders, dividers,
pipelines, and other features.

# Major Architecture

Ultimately, this RISC-V implementation will use an entirely asynchronous
architecture.  This consumes significant area, largely due to routing;
however, routing is between directly-attached components generally, and
should not be a problem in and of itself.

In general, an Asynchronous CPU operates in a synchronous system as below:
```
       __________________________________________________________
      |   _______________             ________________________   |
  CLK-|--|  Transceiver  |=Handshake=| Asynchronous circuitry |  |
D0..n=|==|               |=D[0]0..n==|                        |  |
      |  |               |=D[1]0..n==|                        |  |
      |  |_______________|           |________________________|  |
      |__________________________________________________________|
```
Above, a transceiver operates as a clocked (synchronous) component and an
unclocked (asynchronous) component.  The asynchronous side experiences delay
controlled by the clock, but uses the asynchronous protocol.

# Handshake

A completion-detection handshake allows for delay-insensitive components.  Such components are attached as such:
```
     Sender           Receiver
 _______________   _______________
| Ready    (in) |-| Ready   (out) |
| Waiting (out) |-| Waiting  (in) |
| d[0..x] (out) |=| d[0..x]  (in) |
|_______________| |_______________|
```
A strict handshake protocol ensures transitions on each side follow a state
machine in which data must be acknowledged seen, then not seen; sent, then
not sent; and so forth.  This protocol ensures each sender holds the data
lines stable until the recipient acknowldeges it has a stable copy of the data,
and only sends data when a recipient *is* ready to receive data.

# NULL Convention Logic

Asynchronous components use a form of one-hot logic called NULL Convention
Logic.  Each bit has one of the following states:

```
High  Low  Value
   0    0   NULL
   1    0      0
   0    1      1
```

The `[1 1]` signal is invalid.  Completion detection circuits wait for all
bits to see `High XOR Low = 1` before signaling the completion of some action.

An adder may indicate its readiness to add data, latch all the data lines when
acknowledged that data is waiting *and* all data lines are completed
(i.e. transmitted, `L XOR H = 1`), and *then* remove its `Ready` signal. Then,
upon completion of all output data lines, it latches those outputs, waits for
a `Ready` signal from the recipient of the result, and clears its inputs.
Finally, when it sees all its outputs read `NULL`, it signals `Ready` to the
component sending it data.

In this way, the adder blocks incoming data on the data bus when not `Ready`
to do new computations, and accepts new data immediately when it finishes a
computation.  A computation is finished when it is stored somehow for sending
to the recipient of the result, and when all outputs from the adder are once
again `NULL`.

This NULL Convention Logic allows each stage of the adder to output `NULL`
until it receives a non-`NULL` input (with no handshaking:  the component
does all the input-output tests and signals other components, and manages
what is sent to the adder circuit itself).  That in turn allows the adder
to not propagate computations *until* a signal has validly propagated,
allowing the component as a whole to detect its own completion state.
