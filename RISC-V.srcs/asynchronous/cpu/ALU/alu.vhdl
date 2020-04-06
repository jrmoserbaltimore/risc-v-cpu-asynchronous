-- vim: sw=4 ts=4 et
--
-- Highly-conceptual rough-in, very broken
library IEEE;
use IEEE.std_logic_1164.all;
use work.ncl.all;

-- Circuit to 
entity insn_output is
    generic ( XLEN : positive );
    port map (
        -- The content to stick into rd
        rd   : ncl_logic_vector(XLEN-1 downto 0);
        -- The instruction itself, which contains
        -- rd at [11:7], along with all information
        -- about read and write targets
        insn : ncl_logic_vector(31 downto 0)
    );
end insn;

entity insn_riscv_execution is
    generic ( XLEN : positive );
    port map (
        rs1    : in ncl_logic_vector(XLEN-1 downto 0);
        rs2    : in ncl_logic_vector(XLEN-1 downto 0);
        insn   : in ncl_logic_vector(31 downto 0);
        -- FIXME:  Need all the machine registers passed in
        -- some readable manner so instructions can react to
        -- the machine's mode.
        --
        -- MISA lets us at least check 
        misa_r : in ncl_logic_vector(XLEN-1);
        Rt, Wr : in std_logic;
        -- rd is the actual output data
        rd     : out ncl_logic_vector(XLEN-1 downto 0);
        Rr, Wt : out std_logic
    );
end insn_riscv;

entity insn_riscv_decoder is
    generic ( XLEN : positive );
    port map (
        insn    : in ncl_logic_vector(31 downto 0);
        Rr, Wr  : in std_logic;
        pc      : in ncl_logic_vector(XLEN-1 downto 0);
        misa_r  : in ncl_logic_vector(XLEN-1);
        -- Change this to actual not-crap
        regfile : in ncl_logic_vector(15 downto 0);
        -- rd is the actual output data
        rd      : out ncl_logic_vector(XLEN-1 downto 0);
        Rt, Wt  : out std_logic
   );
end insn_riscv_decoder;

architecture a_insn_riscv_decoder of insn_riscv_decoder is
    signal data_rs1, data_rs2 = ncl_logic_vector(XLEN-1 downto 0);
    signal Rinsn :
begin

    andi_insn : entity insn_riscv_execution(insn_riscv_andi)
        generic map ( XLEN => XLEN)
        port map (
        rs1    => data_rs1;
        rs2    => data_rs2;
        insn   => insn;
        misa_r => misa_r;

        );


end a_insn_riscv_decoder;
