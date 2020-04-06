-- vim: sw=4 ts=4 et
-- Shift instructions, including:
--
-- RV32I
--   SLLI   Shift Left Logical Immediate (32)
--   SRLI   Shift Right Logical Immediate (32)
--   SRAI   Shift Right Arithmetic Immediate (32)
--   SLL    Shift Left Logical (32)
--   SRL    Shift Right Logical (32)
--   SRA    Shift Right Arithmetic (32)
--
-- RV64I
--   SLLI   Shift Left Logical Immediate (64)
--   SRLI   Shift Right Logical Immediate (64)
--   SRAI   Shift Right Arithmetic Immediate (64)
--   SLL    Shift Left Logical (64)
--   SRL    Shift Right Logical (64)
--   SRA    Shift Right Arithmetic (64)
--   SLLIW  SLLI (32)
--   SRLIW  SRLI (32)
--   SRAIW  SRAI (32)
--   SLLW   SLL (32)
--   SRLW   SRL (32)
--   SRAW   SRA (32)
--
-- RV128I
--   TBA

library IEEE;
use IEEE.std_logic_1164.all;
use work.ncl.all;

architecture riscv_insn_shift of riscv_insn is
begin
    -- XLEN will be 32, 64, or 128, and will instantiate a shifter
    -- that many bits wide.
    --
    -- The barrel shifter can place bail-out circuits at each halving
    -- of the bit width, e.g. with XLEN=128 and BitWidths=3, the
    -- shifter can direct to output at 128, 64, or 32 bits.
    barrel_shifter: entity e_barrel_shifter_ncl(a_barrel_shifter_ncl)
    generic map (n             => XLEN,
                 BitWidths => BitWidthCount );

    -- TODO:  send current bit width mode to barrel_shifter

    -- TODO:  

end architecture;
