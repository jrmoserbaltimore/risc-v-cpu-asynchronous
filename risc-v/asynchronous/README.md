Asynchronous CPU Components
===========================

These CPU components are asynchronous.  They include adders, dividers,
pipelines, and other features.

# Architecture

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

A completion-detection handshake allows for delay-insensitive components.

Consider a component shaped as below:
```
  ______________________________
-| Ready  (out)   Ready    (in) |-
-| Waiting (in)   Waiting (out) |-
=| d[0..x] (in)   d[0..x] (out) |=
 |______________________________|
```
The above has a data input and a data output.  Another component with the same
interface would send and received data over the same interface.

This allows only the transitions below:
```
W[in]   R[out]   Transition
1       1        R[out] <= 0
0       0        R[out] <= 1

R[in]   W[out]   Transition
1       0        W[out] <= 1
0       1        W[out] <= 0
```

The initialization  state is `W[out]=0, R[out]=X`, with `R[out]` transitioning
to `1` when ready.  To be more clear:
```
     Sender           Receiver
 _______________   _______________
| Ready    (in) |-| Ready   (out) |
| Waiting (out) |-| Waiting  (in) |
| d[0..x] (out) |=| d[0..x]  (in) |
|_______________| |_______________|
```
Above, the Sender waits for Ready to read `1`.  When this occurs, the Sender
sets Waiting to `1` only after it has data ready on `d[0..x]`.  Waiting and
`d[0..x]` remain asserted until Ready reads `0`, at which point Waiting is
de-asserted to `0`.

The Receiver, when ready to receive data, waits for Waiting to read `0`.  When
this occur, the Receiver asserts Ready as `1` only after it is ready to receive
new data.  When Waiting reads `1`, the Receiver de-asserts Ready to `0` only
after it no longer requires the data on `d[0..x]`.

In this way the Sender sends data to the Receiver immediately when the Receiver
is ready for it.  Two-way or pipeline communication requires two such buses:
each must send and receive to either one another or some other component.
