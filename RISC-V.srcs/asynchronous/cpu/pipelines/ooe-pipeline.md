Simple Out-of-Order Execution Pipeline
======================================

This pipeline extends the Simple Pipeline to include out-of-order execution.

# Pipeline staging
```
[Fetch]
       [LRW]
            [Load]
                  [ULR]
                       [Decode]
                               [Execute]
                                        [Store]
                                               [Retire]
```
In this pipeline, each instruction takes both read and write locks.  As in
the simple pipeline, locks are taken before Load; however, both read and
write lock counts are tracked.

Speculative execution and branch prediction are unsupported by this pipeline.
As the `Fetch` stage must use and update `pc`, `Fetch` sends the current `pc`
with the fetched instruction.  The `Fetch` stage occurs in order.

The `LRW` stage takes Read and Write locks.  `LRW` stalls any instructions
reading or writing data under write lock; the stalled instruction is placed
into a buffer, and the next instruction goes into `LRW`.  The next instruction
stalls both by normal locks and by having a locking contention with the
buffered instruction.  If the next instruction stalls, `LRW` stalls entirely
until the buffer is free; otherwise the instruction continues as normal.

This process allows simple out-of-order instruction execution for most RV32I
and RV64I instructions.  RISC-V instructions generally don't have
side-effects, such as setting status flag registers, so their order is
generally unimportant.

