Roadmap for CPU
===============

# Minimal CPU

The steps to create a working RISC-V RV32I implementation are simple:

1.  Asynchronous component infrastructure
 * Handshake
 * Asynchronous register
 * Sync-Async transceiver
2. Infrastructure
 * Register file
 * Instruction fetch
 * Instruction decoder
3. Asynchronous RAM bus interface
 * Interface with synchronous memory
4.  Asynchronous components
 * Adder
 * Incrementer (toggle bits until encountering the firts 0 bit)
 * 2's complement
5.  Basic asynchronous instruction implementations
 * Canonical NOP instruction
   * Detect `ADDI x0, x0, 0` and silently abort the insn
   * Other writes to `x0` are `HINT` insns
 * Execute-circuit implementations
   * Load (`LW`, `LUI`)
   * Sign-extending Load (`LB`, `LH`, `LBU`, `LHU`)
   * Store (`SW`, `SH`, `SB`)
   * Bitwise logic (`AND`, `OR`, `XOR`, `ANDI`, `ORI`, `XORI`)
   * Bit shifters (`SLLI`, `SRLI`, `SRAI`, `SLL`, `SRL`, `SRA`)
   * Arithmetic (`ADD`, `SUB`, `ADDI`)
   * Branch (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`)
   * Control flow (`AUIPC`, `JAL`, `JALR`)
   * Comparison instructions (`SLTI`, `SLTIU`, `SLT`, `SLTU`)
6.  Asynchronous ALU
7.  Asynchronous pipeline
 * Fetch
 * Decode
 * Locking
 * Load
 * Execute
 * Retire

The above implements all the RV32I instructions except `FENCE`.  This
does not, however, implement machine mode:  the CPU is not a proper
RISC-V CPU.  With the above implemented, test RISC-V code can run on
the core.

# Machine-Mode

To implement a machine-mode RISC-V CPU, we need more infrastructure:

1.  Machine-mode CSRs
 * `misa`
 * `mvendorid`
 * `marchid`
 * `mimpid`
 * `mhartid`
 * `mstatus`
 * `mstatush`
 * `mdeleg`
 * `mideleg`
 * `mip`
 * `mie`
 * `mtime`
 * `mtimecmp`
 * `mcycle`
 * `minstret`
 * `mcounteren`
 * `mcountinhibit`
 * `mscratch`
 * `mepc`
 * `mcause`
 * `mtval`
2.  Machine-level ISA
 * Environment call (`ECALL`, `EBREAK`)
 * Trap-return (`MRET`, `SRET`)
 * Wait for interrupt (`WFI`)
3.  Machine-level infrastructure
 * Reset state
 * NMI
 * Physical memory considerations
 * Memory protection
 * Paging
3.  `FENCE` instruction to complete RV32I

Machine mode is not overly complex, but does carry a lot of infrastructure.

# Supervisor mode

Supervisor mode extends a CPU with machine mode, providing all the facilities
to run a modern Linux operating system.

# RV32M extension

Multiply and Divide add additional instructions and multipliers.

1.  Infrastructure
 * Multipliers
 * Dividers (Paravartya using multipliers)
2.  Instructions
 * Multiplication (`MUL`, `MULH`, `MULHSU`, `MULHU`)
 * Division (`DIV`, `DIVU`, `REM`, `REMU`)

# RV64IM

RV64I extends the addressing space and register size in 64-bit mode, and adds
a few 64-bit instructions.

1.  Infrastructure
 * 64-bit flag and proper behavior
 * Decoder
2.  Instructions
 * 64-bit load/store (`LD`, `SD`)
 * 32-bit W instructions
 * Adjustments to base instructions for 64-bit operation

Implementation of RV64M on top of all the above provides a full 64-bit
asynchronous RISC-V processor, albeit without floating point.

# Hypervisor Mode

The hypervisor extension is in draft as of RISC-V privileged architectures
V1.12 draft.

Hypervisor extensions add a significant amount of infrastructure and
instructions to the CPU and are far more challenging to implement than
Supervisor-mode extensions.
