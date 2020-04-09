-- vim: sw=4 ts=4 et
-- AND a sign-extended 12-bit immediate register
library IEEE;
use IEEE.std_logic_1164.all;
library async_ncl;
use async_ncl.ncl.all;
use work.e_ncl_logic_register;
use work.e_ncl_handshake_receiver;

entity e_riscv_insn_async_2reg_infra is
    generic ( XLEN : positive );
    port (
        -- Receiver port and handshake
        rs1  : in  ncl_logic_vector(XLEN-1 downto 0);
        rs2  : in  ncl_logic_vector(XLEN-1 downto 0);
        insn : in  ncl_logic_vector(31 downto 0);
        Rr   : out std_logic;
        Wr   : in  std_logic;
        -- Sender handshake
        Rs   : in  std_logic;
        Ws   : out std_logic;
        -- Logic circuit:  buffered rs1, rs2, insn
        rs1b : out ncl_logic_vector(XLEN-1 downto 0);
        rs2b : out ncl_logic_vector(XLEN-1 downto 0);
        insnb: out ncl_logic_vector(31 downto 0);
        -- result from the logic circuit
        rdl  : in  ncl_logic_vector(XLEN-1 downto 0)
    );
end e_riscv_insn_async_2reg_infra;

architecture riscv_insn_async_2reg_infra of e_riscv_insn_async_2reg_infra is
    signal Din   : ncl_logic_vector( (rs1'LENGTH
                                    + rs2'LENGTH
                                    + insn'LENGTH)-1 downto 0);
    -- Buffered into a delay-insensitive register
    signal in_buffer : ncl_logic_vector( (  rs1'LENGTH
                                          + rs2'LENGTH
                                          + insn'LENGTH)-1 downto 0);

    alias r_rs1  : ncl_logic_vector((rs1'LENGTH)-1 downto 0) is
                          in_buffer((rs1'LENGTH)-1 downto 0);
                         
    alias r_rs2  : ncl_logic_vector( (rs2'LENGTH)-1 downto 0) is
                          in_buffer( (rs1'LENGTH
                                    + rs2'LENGTH)-1 downto (rs1'LENGTH));

    alias r_insn : ncl_logic_vector( (insn'LENGTH)-1 downto 0) is
                         in_buffer( (rs1'LENGTH
                                   + rs2'LENGTH
                                   + insn'LENGTH)-1 downto (rs1'LENGTH
                                                          + rs2'LENGTH));
    signal r_Enable : std_logic;
    signal r_Clear  : std_logic;
    signal r_Stored : std_logic;
    -- Receiver handshake
    signal r_hs_Enable : std_logic;
    
begin

    -- DI registered buffer 
    r_buffer: entity e_ncl_logic_register(ncl_logic_register)
        generic map (n => rs1'LENGTH + rs2'LENGTH + insn'LENGTH)
        port map
        (D      => Din,
         Q      => in_buffer,
         En     => r_Enable,
         CLR    => r_Clear,
         W      => Wr,
         Stored => r_Stored
        );

    -- Handshake to receive input data
    hs_receiver: entity e_ncl_handshake_receiver(ncl_handshake_receiver)
        port map (
        Ready    => Rr,
        -- Enable when nothing stored
        En       => NOT r_Stored, -- FIXME:  Needs to come from the ICT component (yellow)
        Waiting  => Wr,
        EnOut    => r_Enable
    );

    -- TODO:  Input completion test component
    -- TODO:  Sender handshake component
    -- TODO:  Flush signal

    -- TODO: Setup receiver handshake enable

    -- Set up r_buffer input signal
    Din((rs1'LENGTH)-1 downto 0) <= rs1;
    Din( (rs1'LENGTH
        + rs2'LENGTH)-1 downto (rs1'LENGTH)) <= rs2;
    Din( (rs1'LENGTH
        + rs2'LENGTH
        + insn'LENGTH)-1 downto (rs1'LENGTH
                               + rs2'LENGTH)) <= insn;

end riscv_insn_async_2reg_infra;