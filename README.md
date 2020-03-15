RISC-V Soft CPU
===============

The RISC-V Soft CPU provides various CPU packages.

# RV32/64IM

This is a small-footprint, embedded processor conformant to the following
RISC-V standards:

* RV32/64I 2.1
* M 2.0
  * Uses FPGA multipliers
  * Paravartya integer division implementation

The FPGA implementation of RISC-V is likely unaffected by registers, as LUT
registers are almost never a resource constraint and BRAM is often plentiful.

64-bit extension instructions add 15 RV64I and 5 RV64M instructions.

This implements only the M machine mode privileged system, and has the
following MISA flags available:

* E
* I
* M

This core is suitable for embedded environments, notably for the Retro-1 BIOS
implementation.  UEFI always runs in M mode on the BIOS embedded CPU.  This
core implements no pipelines, simple adders, and synchronous operations to
minimize size.

# RV32/64IM-Counters-Zicsr-Zifencei

This extends the RV32/64IM with the following:

* Counters 2.0 Draft
  * Draft for counters
  * Cycle counter uses adder loop when non-retired instructions in pipeline:  adder increments counter CSR
* Zfencei

This core also implements the M, S, and U privilege levels, and so implements
MISA flags:

* E
* I
* M
* S
* U

This core is suitable for running Linux or Minix operating systems.

This core implements simple pipelines, Han-Carlson adders, and NULL Convention
Logic for asynchronous execution.  It eschews floating point due to large area
usage.

# RV32/64IMAFDQC-Counters-Zicsr-Zifencei-Hypervisor

This extends the RV32/64IM core with floating point and hypervisor support.
This is a *large* core implementing as much logic as possible as NCL.

This core does not exclude simultaneous multithreading (SMT), out-of-order
execution (OOE), speculative execution, runahead, and so forth.  It includes
custom counters to determine which facilities stall the most (e.g. contention
for adders, multipliers, registers in register renaming) to guide customized
implementation.


