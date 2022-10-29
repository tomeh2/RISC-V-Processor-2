library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_cpu.all;

entity stage_decode is
    port(
        -- ========== INPUT DATA SIGNALS ==========
        reg_wr_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
        -- ========== OUTPUT DATA SIGNALS ==========
        reg_1_data : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate_data : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
        -- ========== INPUT CONTROL SIGNALS ==========
        instruction_bus : in std_logic_vector(31 downto 0);
        
        reg_wr_addr_in : in std_logic_vector(3 + ENABLE_BIG_REGFILE downto 0);
        reg_wr_en_in : in std_logic;
        
        clk : in std_logic;
        clk_dbg : in std_logic;
        
        reset : in std_logic;
        
        -- ========== OUTPUT CONTROL SIGNALS ==========
        reg_1_addr : out std_logic_vector(3 + ENABLE_BIG_REGFILE downto 0);
        reg_2_addr : out std_logic_vector(3 + ENABLE_BIG_REGFILE downto 0);
        reg_wr_addr : out std_logic_vector(3 + ENABLE_BIG_REGFILE downto 0);
        reg_1_used : out std_logic;
        reg_2_used : out std_logic;
        reg_wr_en : out std_logic;
        immediate_used : out std_logic;
        pc_used : out std_logic;
        
        prog_flow_cntrl : out std_logic_vector(1 downto 0);
        invert_condition : out std_logic;
        
        transfer_data_type : out std_logic_vector(2 downto 0);
        
        execute_read : out std_logic;
        execute_write : out std_logic;
        
        alu_op_sel : out std_logic_vector(3 downto 0)
    );
end stage_decode;

architecture structural of stage_decode is
    signal reg_1_addr_i : std_logic_vector(3 + ENABLE_BIG_REGFILE downto 0);
    signal reg_2_addr_i : std_logic_vector(3 + ENABLE_BIG_REGFILE downto 0);
    
    signal reg_1_used_i : std_logic;
    signal reg_2_used_i : std_logic;
    
begin
    instruction_decoder : entity work.instruction_decoder(rtl)
                          generic map (DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                       REGFILE_ADDRESS_WIDTH_BITS => 4 + ENABLE_BIG_REGFILE)
                          port map(
                                   -- ===== CONTROL SIGNALS =====
                                   instruction_bus => instruction_bus,
                                   reg_rd_1_addr => reg_1_addr_i,
                                   reg_rd_2_addr => reg_2_addr_i,
                                   reg_wr_addr => reg_wr_addr,
                                   reg_rd_1_used => reg_1_used,
                                   reg_rd_2_used => reg_2_used,
                                   reg_wr_en => reg_wr_en,
                                   immediate_used => immediate_used,
                                   pc_used => pc_used,
                                   
                                   prog_flow_cntrl => prog_flow_cntrl,
                                   invert_condition => invert_condition,
                                   
                                   transfer_data_type => transfer_data_type,
                                   
                                   execute_read => execute_read,
                                   execute_write => execute_write,
                                   
                                   alu_op_sel => alu_op_sel,
                                   
                                   -- ===== DATA SIGNALS =====
                                   immediate_data => immediate_data);
    
    register_file : entity work.register_file(rtl)
                    generic map(REG_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                REGFILE_SIZE => 4 + ENABLE_BIG_REGFILE)
                    port map(-- ADDRESSES
                             rd_1_addr => reg_1_addr_i,
                             rd_2_addr => reg_2_addr_i,
                             wr_addr => reg_wr_addr_in,
                             
                             -- DATA
                             wr_data => reg_wr_data,
                             rd_1_data => reg_1_data,
                             rd_2_data => reg_2_data,
                             
                             -- CONTROL
                             wr_en => reg_wr_en_in,
                             reset => reset,
                             clk => clk,
                             clk_dbg => clk_dbg);
    
    reg_1_addr <= reg_1_addr_i;
    reg_2_addr <= reg_2_addr_i;
    
end structural;












