-- vim: sw=4 ts=4 et
-- AND a sign-extended 12-bit immediate register
library IEEE;
use IEEE.std_logic_1164.all;
library async_ncl;
use async_ncl.ncl.all;
use work.e_ncl_logic_register;
use work.e_riscv_insn_async_2reg_infra;

entity e_riscv_insn_async_2reg is
    generic ( XLEN : positive );
    port (
        -- Receiver port and handshake
        rs1  : in  ncl_logic_vector(XLEN-1 downto 0);
        rs2  : in  ncl_logic_vector(XLEN-1 downto 0);
        insn : in  ncl_logic_vector(31 downto 0);
        Rr   : out std_logic;
        Wr   : in  std_logic;
        -- Sender port and handshake
        Dout : out ncl_logic_vector(XLEN-1 downto 0);
        Rs   : in  std_logic;
        Ws   : out std_logic
    );
end e_riscv_insn_async_2reg;

architecture riscv_i_async_bitmask of e_riscv_insn_async_2reg is
    signal Din   : ncl_logic_vector( (rs1'LENGTH
                                    + rs2'LENGTH
                                    + insn'LENGTH)-1 downto 0);
    -- Buffered into a delay-insensitive register
    signal in_buffer : ncl_logic_vector( (  rs1'LENGTH
                                          + rs2'LENGTH
                                          + insn'LENGTH)-1 downto 0);

    signal r_rs1  : ncl_logic_vector(rs1'RANGE);
    signal r_rs2  : ncl_logic_vector(rs2'RANGE);
    signal r_insn : ncl_logic_vector(insn'RANGE);

    -- Data extracted from the buffered instruction
    alias opcode : ncl_logic_vector(6 downto 0)  is r_insn(6 downto 0);
    -- I-type immediate value
    alias imm    : ncl_logic_vector(11 downto 0) is r_insn(31 downto 20);
    -- R-type
    alias funct7 : ncl_logic_vector(6 downto 0)  is r_insn(31 downto 25);
    alias funct3 : ncl_logic_vector(2 downto 0)  is r_insn(14 downto 12);
    -- opcode is 0010011 if I-type, 0110011 if R-type
    alias rtype  : ncl_logic is r_insn(5);
begin

    -- DI registered buffer 
    r_infra: entity e_riscv_insn_async_2reg_infra(riscv_insn_async_2reg_infra)
        generic map (XLEN => XLEN)
        port map
        (rs1   => rs1,
         rs2   => rs2,
         insn  => insn,
         Rr    => Rr,
         Wr    => Wr,
         Rs    => Rs,
         Ws    => Ws,
         -- Buffered registers
         rs1b  => r_rs1,
         rs2b  => r_rs2,
         insnb => r_insn,
         -- send output to 2reg infrastructure
         rdl   => Dout 
        );

    -- TODO:
    -- instantiate an ncl_logic_register of length
    --   (rs1'LENGTH + rs2'LENGTH + insn'LENGTH)
    -- and handshake to store input into that register.
    --
    -- Rewrite slices above to use this register 

    bitmask : process(all) is
    begin
        -- FIXME:  Handshake.  We need the handshake or this WILL fail.
        if ( rtype = ncl_encode('1') ) then
            -- R-type opcode
            if ((funct3(2) AND funct3(1) AND funct3(0)) = ncl_encode('1')) then
                -- funct3 = 111 is AND              
                Dout <= r_rs1 AND r_rs2;
            elsif (    ((funct3(2) AND funct3(1)) = ncl_encode('1'))
                   AND (funct3(0) = ncl_encode('0'))) then
                -- funct3 = 110 = or
                Dout <= rs1 OR rs2;
            elsif (    (funct3(2) = ncl_encode('1'))
                   AND ((funct3(1) OR funct3(0)) = ncl_encode('0'))) then
                -- funct3 = 100 = xor
                Dout <= rs1 XOR rs2;
            else
                -- NULL output
                Dout <= (others => (others => '0')); 
            end if;
        elsif ( rtype = ncl_encode('0') ) then
            -- I-type opcode
            if ((funct3(2) AND funct3(1) AND funct3(0)) = ncl_encode('1')) then
                -- funct3 = 111 is AND              
                Dout <= (11 downto 0 => rs1(11 downto 0) AND imm);
                -- Sign extend
                for i in Dout'HIGH downto 12 loop
                    Dout(i) <= rs1(i) AND imm(11);
                end loop;
            elsif (    ((funct3(2) AND funct3(1)) = ncl_encode('1'))
                   AND (funct3(0) = ncl_encode('0'))) then
                -- funct3 = 110 = or
                Dout <= (11 downto 0 => rs1(11 downto 0) OR imm);
                -- Sign extend
                for i in Dout'HIGH downto 12 loop
                    Dout(i) <= rs1(i) OR imm(11);
                end loop;
            elsif (    (funct3(2) = ncl_encode('1'))
                   AND ((funct3(1) OR funct3(0)) = ncl_encode('0'))) then
                -- funct3 = 100 = xor
                Dout <= (11 downto 0 => rs1(11 downto 0) XOR imm);
                -- Sign extend
                for i in Dout'HIGH downto 12 loop
                    Dout(i) <= rs1(i) XOR imm(11);
                end loop;
            else
                -- NULL output
                Dout <= (others => (others => '0')); 
            end if;        
        else
            -- NULL output
            Dout <= (others => (others => '0'));
        end if;
    end process bitmask;
end riscv_i_async_bitmask;