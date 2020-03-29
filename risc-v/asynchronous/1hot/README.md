Delay-insensitive encoding
===========================

Asynchronous components use one-hot delay-insensitive encoding internally.  In
standard TTL, a 32-bit data bus has 32 wires; in dual-rail one-hot encoding,
the same data bus has 64 wires. Each pair carries one bit in one-hot encoding:
```
Dx0    Dx1    Value
  0      0    NULL
  1      0    0
  0      1    1
  1      1    Halt and catch fire
```
Each step internally must encode in this way to ensure detectable completion.
The final output reaches a completion-detection circuit which then signals
completion.

The single-bit encoder looks as such:
```
INPUT
  |----
 NOT   |
  |    |
 dx0  dx1
```
The dx1 bit is just the input, while the dx0 bit is the input inverted, as
shown in the encoding table above.  Note that `1`-bits propagate slightly
faster than `0` bits if the NOT introduces delay.

The single-bit decoder looks as such:
```
Theoretical    Optimized
INPUT          INPUT
 | |----       |   |
 XOR    |          | 
  |     |        OUTPUT
   ----AND
        |
      OUTPUT
```
The optimized decoder will `wait until d0 XOR d1 = '1'` before sending `d1` to
`OUTPUT`.

Consider a two-bit adder, as below:
```
INPUT:  A1  B1       A0  B0
        0   1        1   1
        |   |        |   |
      [Encoder]    [Encoder]
       1 0 0 1      0 1 0 1
       | | | |      | | | |
     [Full Adder]-0[Half Adder] (Cout=[0 1]=1)
     [          ]-1[          ]
       0 1 1 0       1 0        (Carry=[0 1], S1=[1 0], S0=[1 0])
*      | | | |       | |
      [Decoder]    [Decoder]
OUTPUT:  1 0         0
```
The input is two binary values, `A=01` and `B=11`.  The encoder encodes these
to `A=[10 01]` and `B=[01 01]`.  The adders themselves also encode in this
manner (note this is a ripple-carry adder).

The outputs go to a decoder, which asserts 00 on the output and 1 as the carry
bit.  Note that adding 1 to 0b11 overflows and produces 0 and a carry bit.

The six output lines (marked `*`) also drive a gate tree as follows:
```
*      | | | |       | |
       XOR XOR       XOR Ready[In]--(INPUT)
         | |           | |
         AND           AND
	  |             |
           -----AND-----
                 |
            Waiting[Out]
```
Note the convention here:  on NULL `[0 0]`, the XOR gates output nothing, and
the component does not assert Waiting.  Because `[1 1]` is an invalid state,
OR gates also work rather than XOR; an XOR gate causes halt on invalid
encoding, while OR causes invalid output.

Also note Waiting[Out] is delayed by the gate delay of an XOR gate and *two*
AND gates, while the assertion of a `1` bit through the decoder is delayed
by an XOR gate and *one* AND gate.  For single-bit output, the delay is the
same as a `1` bit decode:
```
 | |
 XOR Ready[In]--(INPUT)
   | |
   AND
    |
Waiting[Out]
```
In general, for `n` bits of output, the delay to assert Waiting[Out] when
Ready[In] is asserted and all data lines are available is one level of XOR
gates plus `log(n+1,2)` levels of AND gates.

When Ready[In] becomes `0`, Waiting[Out] automatically becomes `0`.

The component can be made to also not pass Ready[Out] until all outputs read
`[0 0]` and Waiting[In] reads `0`:
```
*      | | | |       | |
       NOR NOR       NOR Waiting[In]--(INPUT)
         | |           |       |
         AND           AND----NOT
	  |             |
           -----AND-----
                 |
             Ready[Out]
```
In this way, the component asserts Waiting[Out] when all outputs are ready,
and asserts Ready[Out] when all outputs are cleared and Waiting[in] is not
asserted.

These assertions should be latched and reset at appropriate times.  For
example: Ready[Out] must remain asserted until the component is no longer
affected by state changes on the data bus.

When two components are both asynchronous, there is no reason to encode and
decode the output between them.  For example, the binary adder above may be
connected to an instruction pipeline which itself encodes and decodes the
data, or which itself only interfaces with asynchronous components.  In such
a case, the decoding delay is zero and the validation delay is greater than
zero.  Such a configuration would need to convert when leaving its domain,
such as when sending data to memory or peripherals.
