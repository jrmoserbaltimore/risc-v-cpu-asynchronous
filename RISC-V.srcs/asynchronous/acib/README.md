Asynchronous Component Interface Bus
====================================

This describes an Asynchronous Component Interface Bus (ACIB), a bus to
connect components with an asynchronous communications protocol.

This is an extreme rough draft.

# Asynchronous Differential Null Convention Coding

ACIB uses Asynchronous Differential Null Convention Coding (ADNCC) to transmit
data.

ADNCC uses a serial differential pair to transmit a NULL Convention Logic (NCL)
signal from a sender to a receiver.  Unlike NCL communications internal to a
given IC, ACBI is serial and self-timing.  Like all component buses, it uses
signal negotiation and data error detection and correction to preserve data
integrity.  This can create more latency, but high throughput, which is more
appropriate for communications between components.

## Differential Pairs

ADNCC communicates via differential pairs.  Each pair has a fixed positive `p`
and a differential negative `n` rail carrying an NCL bit of `[p n]`.  The
rails are considered equivalent with a NULL value of `[0 0]` when within a
defined voltage of one another; otherwise, the more-negative rail is the
`1` bit.

Given a base voltage of 0 on both rails and a 50mV standard signal
differential, the signal would read as follows:

| `p` | `n`   | NCL     | Value
| ---:| -----:| -------:| ----:
|   0 | +50mV | `[1 0]` | `0`
|   0 |   0mV | `[0 0]` | `NULL`
|   0 | -50mV | `[0 1]` | `1`

To transmit multiple `0` or `1` bits in series, the sender must transition to
`NULL` between each bit; whereas a transition directly between `0` and `1`
is always accepted for several reasons:

* The `p` rail is constant, so there's no chance of a glitch from propagation
delay on `p`;
* A transition between `0` and `1` on the `n` line must necessarily pass
through `NULL`, which would only signal that the next non-`NULL` value is a
an intended data bit, and so is implicit; and
* If the `n` line can spuriously transition between `0` and `1`, the circuit
can spuriously transition between `NULL` and non-`NULL`, and no data integrity
is possible.

This together means there is no value in requiring a `NULL` between valid and
distinct `0` and `1` signals; rather a transition between *any* of the three
states is valid, and the `NULL` state is just not data and not recorded.

## Voltage Characteristics

ADNCC uses a variable transmission voltage.  Any voltage differential between
50mV and 300mV is acceptable, negotiated between the two endpoints.  `NULL` is
always *sent* as `+0mV`, and the threshold for transition to `NULL` is 1/3 the
voltage differential, while transition to not-`null` is 2/3 the voltage.

(FIXME:  is that reasonable thresholding?)

Implementations are not required to support all voltages.  Implementations
*must* support each of `p`+/-50mV, `p`+/-150mV, and `p`+/-300mV.

## Signal Negotiation

Bus protocols over ADNCC must uses packet error detection and correction, as
is the case with most modern bus protocols.  Bus protocols using ADNCC may
responds to error rate by:

* Implementing error-correcting coding;
* Negotiating a diffrent voltage differential; or
* Clocking the sender.

If a voltage differential of 300mV does not result in a low-error connection,
the sender may physically delay each transition to align with a clock signal,
varying this clock and the voltage differential to achieve optimal transmission
rate.  The receiver doesn't concern itself with the error rate.

## Signal Transmission Rate

ADNCC provides asynchronous transmission of digital signals.  Bus protocols
using ADNCC must negotiate packet size and manage error over this coding.

ADNCC will operate at higher or lower baud rate based on cable length,
temperature, encoding and decoding hardware, and other characteristics.  It
is delay-insensitive, but requires readable signal.

Data transmission may, in some cases, overwhelm the capabalities of the
receiver in buffering and processing the data.  This causes errors unrelated
to the transmission protocol, but rather to the sheer volume of data received.
Bus protocols using ADNCC must handle these errors either by negotiating
packet size and transmission rate or by slowing down the data transmission as
in any other error condition.

# Asynchronous Component Interface Bus

Asynchronous Component Interface Bus (ACIB) uses ADNCC to provide an
asynchronous data bus.

## Electrical Characteristics

ACIB uses two types of connectors:  a 20-pin interface and ...

### 20-pin connector

The 20-pin connector is pin-compatible with Type-C, including a maximum 100W
power delivery and four differential pairs.  The differential pairs must
operate as ADNCC in ACIB mode.

### X-pin connector

TBD:  Number of pairs, power characteristics.

## Bus protocol

XXX:  Bus protocol

Packets have specific connection ID attached to them.

DMA is negotiated to specific memory areas via a memory controller.

### Error Correction

ACIB uses a fast, variable Reed-Solomon coding to correct for errors, as well
as variation of the ADNCC physical layer.

TBD:  Specific RS Coding, fast hardware implementation.

## Implementation considerations

ACIB transceivers may support multiple devices and simultaneous communication
with the host.  Such devices may use multiplexers in a one-to-many or
many-to-many configuration to allow simultaneous communication.

ACIB controls the communication between two ACIB devices.  ADNCC does not
negotiate asynchronous data flow, but only uses delay-insensitive data
transmission.  ACIB can delay data flow by delaying an acknowledgement of
readiness for a packet.

An ACIB transceiver may interface asynchronously with the host device via a
handshake protocol, notably when the ACIB transceiver is integrated into a
SoC.  This automatically manages behavior related to data transfer and
processing capability:  if the ACIB transciever can buffer all data packets
it requests or accepts, then it can wait to acknowledge pending requests or
make new requests simply by waiting until its internal buffers are flushed.
If this happens over an asynchronous handshake protocol, then the transceiver
waits precisely until the host receives and acknowledges its receipt of the
buffered data.
