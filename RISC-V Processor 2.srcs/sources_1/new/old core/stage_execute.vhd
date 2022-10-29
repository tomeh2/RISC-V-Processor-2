library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pkg_cpu.all;

entity stage_execute is
    port(
        -- ========== DATA SIGNALS ==========
        reg_1_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        alu_result : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data_forwarded : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        ex_mem_forward_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        mem_wb_forward_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        -- ========== CONTROL SIGNALS ==========
        pc : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        alu_op_sel : in std_logic_vector(3 downto 0);
        reg_1_used : in std_logic;
        reg_2_used : in std_logic;
        immediate_used : in std_logic;
        pc_used : in std_logic;
        
        reg_1_fwd_em : in std_logic;
        reg_1_fwd_mw : in std_logic;
        reg_2_fwd_em : in std_logic;
        reg_2_fwd_mw : in std_logic;
        
        prog_flow_cntrl : in std_logic_vector(1 downto 0);
        invert_condition : in std_logic;
        branch_target_addr : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_taken : out std_logic
    );
end stage_execute;

architecture structural of stage_execute is
    signal alu_op_sel_i : std_logic_vector(3 downto 0);
    
    -- ALU
    signal alu_oper_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal alu_oper_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal alu_result_i : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
    -- MUX Select Signals
    signal mux_alu_oper_1_sel : std_logic_vector(1 downto 0);
    signal mux_alu_oper_2_sel : std_logic_vector(1 downto 0);
    
    signal mux_reg_2_fwd_sel : std_logic_vector(1 downto 0);
    
    -- Forwarded Register Data Signals
    signal reg_2_fwd : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
begin
    branching_unit : entity work.branching_unit(rtl)
                     port map(pc => pc,
                              immediate => immediate_data,
                              alu_comp_res => alu_result_i(0),
                              invert_branch_cond => invert_condition,
                              reg_1_data => reg_1_data,
                              prog_flow_cntrl => prog_flow_cntrl,
                              branch_target_addr => branch_target_addr,
                              branch_taken => branch_taken);

    mux_reg_2_fwd : entity work.mux_4_1(rtl)
                    generic map(WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                    port map(in_0 => reg_2_data,
                             in_1 => ex_mem_forward_data,
                             in_2 => mem_wb_forward_data,
                             in_3 => mem_wb_forward_data,
                             output => reg_2_fwd,
                             sel => mux_reg_2_fwd_sel);

    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => CPU_DATA_WIDTH_BITS)
          port map(operand_1 => alu_oper_1,
                   operand_2 => alu_oper_2,
                   result => alu_result_i,
                   alu_op_sel => alu_op_sel);
                   
    mux_alu_op_1 : entity work.mux_4_1(rtl)
                   generic map(WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                   port map(in_0 => reg_1_data,
                            in_1 => pc,
                            in_2 => mem_wb_forward_data,
                            in_3 => ex_mem_forward_data,
                            output => alu_oper_1,
                            sel => mux_alu_oper_1_sel);
                   
    mux_alu_op_2 : entity work.mux_4_1(rtl)
                   generic map(WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                   port map(in_0 => reg_2_fwd,
                            in_1 => immediate_data,
                            in_2 => NUM_4,
                            in_3 => (others => '0'),
                            output => alu_oper_2,
                            sel => mux_alu_oper_2_sel);
                          
    mux_reg_2_fwd_sel(0) <= reg_2_fwd_em;
    mux_reg_2_fwd_sel(1) <= reg_2_fwd_mw;
                            
    mux_alu_oper_1_sel(0) <= prog_flow_cntrl(1) or reg_1_fwd_em or pc_used;
    mux_alu_oper_1_sel(1) <= reg_1_fwd_mw or reg_1_fwd_em;
                            
    mux_alu_oper_2_sel(0) <= immediate_used;
    mux_alu_oper_2_sel(1) <= prog_flow_cntrl(1);  
    
    alu_result <= alu_result_i;  
    reg_2_data_forwarded <= reg_2_fwd;
end structural;











