library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_cpu.all;

entity instruction_decoder is
    generic(
        DATA_WIDTH_BITS : integer;
        REGFILE_ADDRESS_WIDTH_BITS : integer
    );
    port(
        -- ========== INSTRUCTION INPUT ==========
        instruction_bus : in std_logic_vector(31 downto 0);
        
        -- ========== GENERATED CONTROL SIGNALS ==========
        -- ALU
        alu_op_sel : out std_logic_vector(3 downto 0);
        
        -- Immediates
        immediate_data : out std_logic_vector(DATA_WIDTH_BITS - 1 downto 0);
        
        immediate_used : out std_logic;
        pc_used : out std_logic;
        
        -- Branch control
        prog_flow_cntrl : out std_logic_vector(1 downto 0);
        invert_condition : out std_logic;
        
        -- Register control
        reg_rd_1_addr : out std_logic_vector(REGFILE_ADDRESS_WIDTH_BITS - 1 downto 0);
        reg_rd_2_addr : out std_logic_vector(REGFILE_ADDRESS_WIDTH_BITS - 1 downto 0);
        reg_wr_addr : out std_logic_vector(REGFILE_ADDRESS_WIDTH_BITS - 1 downto 0);
        
        reg_rd_1_used : out std_logic;
        reg_rd_2_used : out std_logic;
        reg_wr_en : out std_logic;
        
        -- Memory control
        transfer_data_type : out std_logic_vector(2 downto 0);
        
        execute_read : out std_logic;
        execute_write : out std_logic
    );
end instruction_decoder;

architecture rtl of instruction_decoder is

begin

    decoder : process(all)
    begin
    -- Default values for signals in case the instruction does not set them
    alu_op_sel <= "0000";
    immediate_data <= (others => '0');
    
    reg_rd_1_used <= '0';
    reg_rd_2_used <= '0';
    reg_wr_en <= '0';
    immediate_used <= '0';
    pc_used <= '0';
    
    prog_flow_cntrl <= PROG_FLOW_NORM;
    invert_condition <= '0';
    
    transfer_data_type <= "000";
    
    execute_read <= '0';
    execute_write <= '0';
    
    -- Always decode register addresses
    reg_rd_1_addr <= instruction_bus(15 + REGFILE_ADDRESS_WIDTH_BITS - 1 downto 15);
    reg_rd_2_addr <= instruction_bus(20 + REGFILE_ADDRESS_WIDTH_BITS - 1 downto 20);
    reg_wr_addr <= instruction_bus(7 + REGFILE_ADDRESS_WIDTH_BITS - 1 downto 7);
    
    if (instruction_bus(6 downto 0) = REG_ALU_OP) then                       -- Reg-Reg ALU Operations
        alu_op_sel <= instruction_bus(30) & instruction_bus(14 downto 12);
        
        reg_rd_1_used <= '1';
        reg_rd_2_used <= '1';
        reg_wr_en <= '1';
    elsif (instruction_bus(6 downto 0) = IMM_ALU_OP) then                    -- Reg-Imm ALU Operations
        alu_op_sel <= '0' & instruction_bus(14 downto 12);
        
        reg_rd_1_used <= '1';
        reg_wr_en <= '1';
        immediate_used <= '1';
        
        -- Immediate decoding
        immediate_data(11 downto 0) <= instruction_bus(31 downto 20);
        immediate_data(DATA_WIDTH_BITS - 1 downto 12) <= (others => instruction_bus(31));
    elsif (instruction_bus(6 downto 0) = LUI) then                    -- LUI
        alu_op_sel <= "0000";
        
        reg_wr_en <= '1';
        immediate_used <= '1';
        
        reg_rd_1_addr <= (others => '0');   -- Select zero as first operand
        -- Immediate decoding
        
        immediate_data(DATA_WIDTH_BITS - 1 downto 31) <= (others => instruction_bus(31));
        immediate_data(30 downto 12) <= instruction_bus(30 downto 12);
        immediate_data(11 downto 0) <= (others => '0');
    elsif (instruction_bus(6 downto 0) = AUIPC) then
        alu_op_sel <= "0000";
        
        reg_wr_en <= '1';
        
        pc_used <= '1';
        immediate_used <= '1';
        
        immediate_data(DATA_WIDTH_BITS - 1 downto 31) <= (others => instruction_bus(31));
        immediate_data(30 downto 12) <= instruction_bus(30 downto 12);
        immediate_data(11 downto 0) <= (others => '0');
    elsif (instruction_bus(6 downto 0) = LOAD) then                    -- LOAD
        alu_op_sel <= "0000";
        
        reg_rd_1_used <= '1';
        immediate_used <= '1';
        reg_wr_en <= '1';
        
        transfer_data_type <= instruction_bus(14 downto 12);
        
        execute_read <= '1';
        
        immediate_data(11 downto 0) <= instruction_bus(31 downto 20);
        immediate_data(DATA_WIDTH_BITS - 1 downto 12) <= (others => instruction_bus(31));
    elsif (instruction_bus(6 downto 0) = STORE) then                    -- STORE
        alu_op_sel <= "0000";
        
        reg_rd_1_used <= '1';
        reg_rd_2_used <= '1';       -- For forwarding purposes
        immediate_used <= '1';
        
        transfer_data_type <= instruction_bus(14 downto 12);
        
        execute_write <= '1';
        
        immediate_data(11 downto 5) <= instruction_bus(31 downto 25);
        immediate_data(4 downto 0) <= instruction_bus(11 downto 7);
        immediate_data(DATA_WIDTH_BITS - 1 downto 12) <= (others => instruction_bus(31));
    elsif (instruction_bus(6 downto 0) = JAL) then
        alu_op_sel <= "0000";
        
        reg_wr_en <= '1';
        
        prog_flow_cntrl <= PROG_FLOW_JAL;
        
        immediate_data(10 downto 1) <= instruction_bus(30 downto 21);
        immediate_data(11) <= instruction_bus(20);
        immediate_data(19 downto 12) <= instruction_bus(19 downto 12);
        immediate_data(DATA_WIDTH_BITS - 1 downto 20) <= (others => instruction_bus(31));
    elsif (instruction_bus(6 downto 0) = JALR) then
        alu_op_sel <= "0000";
        
        reg_wr_en <= '1';
        
        prog_flow_cntrl <= PROG_FLOW_JALR;
        
        immediate_data(11 downto 0) <= instruction_bus(31 downto 20);
        immediate_data(DATA_WIDTH_BITS - 1 downto 12) <= (others => instruction_bus(31));
    elsif (instruction_bus(6 downto 0) = BR_COND) then
        if (instruction_bus(14 downto 13) = "00") then
            alu_op_sel <= "1100";
        elsif (instruction_bus(14 downto 13) = "10") then
            alu_op_sel <= "0010";
        elsif (instruction_bus(14 downto 13) = "11") then
            alu_op_sel <= "1110";
        end if;
        
        prog_flow_cntrl <= PROG_FLOW_COND;
        invert_condition <= instruction_bus(12);
        
        reg_rd_1_used <= '1';
        reg_rd_2_used <= '1';
        
        immediate_data(0) <= '0';
        immediate_data(4 downto 1) <= instruction_bus(11 downto 8);
        immediate_data(10 downto 5) <= instruction_bus(30 downto 25);
        immediate_data(11) <= instruction_bus(7);
        immediate_data(DATA_WIDTH_BITS - 1 downto 12) <= (others => instruction_bus(31));
    end if;
    end process;
    
end rtl;
















