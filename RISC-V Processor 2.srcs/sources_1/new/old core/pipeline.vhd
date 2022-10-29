library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_pipeline.all;
use work.pkg_cpu.all;

entity pipeline is
    port(
        instruction_debug : in std_logic_vector(31 downto 0);
        instruction_addr_debug : out std_logic_vector(31 downto 0);
    
        -- AXI Controller Signals
        from_master : out work.axi_interface_signal_groups.FromMaster;
        to_master : in work.axi_interface_signal_groups.ToMaster;
    
        clk : in std_logic;
        clk_dbg : in std_logic;
        
        reset : in std_logic
    );
end pipeline;

architecture structural of pipeline is
-- Pipeline Control Signals
signal mem_busy : std_logic;
signal pc : std_logic_vector(31 downto 0);

signal pipeline_fwd_cntrl : pipeline_fwd_cntrl_type;

signal pipeline_regs_en : pipeline_regs_en_type;
signal pipeline_regs_rst : pipeline_regs_rst_type;

-- Pipeline Registers
signal fet_de_register_next : fet_de_register_type;
signal fet_de_register : fet_de_register_type;

signal de_ex_register_next : de_ex_register_type;
signal de_ex_register : de_ex_register_type;

signal ex_mem_register_next : ex_mem_register_type;
signal ex_mem_register : ex_mem_register_type;

signal mem_wb_register_next : mem_wb_register_type;
signal mem_wb_register : mem_wb_register_type;

-- Forwarding Signals
signal ex_mem_forward_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
signal mem_wb_forward_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);

-- Other Control Signals
signal branch_taken : std_logic;
signal branch_target_addr : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);

begin
    -- ========== PIPELINE CONTROL ==========
    pipeline_controller : entity work.pipeline_controller(rtl)
                          port map(mem_busy => mem_busy,
                                   halt => '0',
                                   branch_taken => branch_taken,
                                   reset => reset,
                                   
                                   pipeline_regs_en => pipeline_regs_en,
                                   pipeline_regs_rst => pipeline_regs_rst);
                                   
    forwarding_unit : entity work.forwarding_unit(rtl)
                      port map(reg_1_addr => de_ex_register.reg_1_addr,
                               reg_2_addr => de_ex_register.reg_2_addr,
                               reg_1_used => de_ex_register.reg_1_used,
                               reg_2_used => de_ex_register.reg_2_used,
                               
                               reg_wr_addr_em => ex_mem_register.reg_wr_addr,
                               reg_wr_addr_mw => mem_wb_register.reg_wr_addr,
                               
                               reg_wr_used_em => ex_mem_register.reg_wr_en,
                               reg_wr_used_mw => mem_wb_register.reg_wr_en,
                               
                               reg_1_fwd_em => pipeline_fwd_cntrl.reg_1_fwd_em,
                               reg_1_fwd_mw => pipeline_fwd_cntrl.reg_1_fwd_mw,
                               reg_2_fwd_em => pipeline_fwd_cntrl.reg_2_fwd_em,
                               reg_2_fwd_mw => pipeline_fwd_cntrl.reg_2_fwd_mw);

    -- ========== STAGES ==========
    stage_fetch : entity work.stage_fetch(rtl)
                  port map(program_counter => pc,
                           branch_taken => branch_taken,
                           branch_target_addr => branch_target_addr,
                           halt => mem_busy,
                           clk => clk,
                           reset => reset);
    
    stage_decode : entity work.stage_decode(structural)
                   port map(-- DATA SIGNALS
                            instruction_bus => fet_de_register.instruction,
                            reg_1_data => de_ex_register_next.reg_1_data,
                            reg_2_data => de_ex_register_next.reg_2_data,
                            immediate_data => de_ex_register_next.immediate_data,
                            
                            reg_wr_data => mem_wb_register.mem_data,
                            
                            -- CONTROL SIGNALS
                            reg_1_addr => de_ex_register_next.reg_1_addr,
                            reg_2_addr => de_ex_register_next.reg_2_addr,
                            reg_1_used => de_ex_register_next.reg_1_used,
                            reg_2_used => de_ex_register_next.reg_2_used,
                            alu_op_sel => de_ex_register_next.alu_op_sel,
                            immediate_used => de_ex_register_next.immediate_used,
                            pc_used => de_ex_register_next.pc_used,
                            
                            prog_flow_cntrl => de_ex_register_next.prog_flow_cntrl,
                            invert_condition => de_ex_register_next.invert_condition,
                            
                            reg_wr_addr => de_ex_register_next.reg_wr_addr,
                            reg_wr_en => de_ex_register_next.reg_wr_en,
                            
                            reg_wr_addr_in => mem_wb_register.reg_wr_addr,
                            reg_wr_en_in => mem_wb_register.reg_wr_en,
                            
                            transfer_data_type => de_ex_register_next.transfer_data_type,
                            
                            execute_read => de_ex_register_next.execute_read,
                            execute_write => de_ex_register_next.execute_write,
                            
                            reset => reset,
                            clk => clk,
                            clk_dbg => clk_dbg
                            );
                            
    stage_execute : entity work.stage_execute(structural)
                    port map(-- DATA SIGNALS
                             reg_1_data => de_ex_register.reg_1_data,
                             reg_2_data => de_ex_register.reg_2_data,
                             immediate_data => de_ex_register.immediate_data,
                             alu_result => ex_mem_register_next.alu_result,
                             reg_2_data_forwarded => ex_mem_register_next.reg_2_data,
                                
                             ex_mem_forward_data => ex_mem_forward_data,
                             mem_wb_forward_data => mem_wb_forward_data,
                             
                             -- CONTROL SIGNALS
                             pc => de_ex_register.pc,
                             
                             prog_flow_cntrl => de_ex_register.prog_flow_cntrl,
                             invert_condition => de_ex_register.invert_condition,
                             
                             branch_taken => branch_taken,
                             branch_target_addr => branch_target_addr,
                             
                             alu_op_sel => de_ex_register.alu_op_sel,
                             reg_1_used => de_ex_register.reg_1_used,
                             reg_2_used => de_ex_register.reg_2_used,
                             immediate_used => de_ex_register.immediate_used,
                             pc_used => de_ex_register.pc_used,
                             
                             reg_1_fwd_em => pipeline_fwd_cntrl.reg_1_fwd_em,
                             reg_1_fwd_mw => pipeline_fwd_cntrl.reg_1_fwd_mw,
                             reg_2_fwd_em => pipeline_fwd_cntrl.reg_2_fwd_em,
                             reg_2_fwd_mw => pipeline_fwd_cntrl.reg_2_fwd_mw);
                             
    stage_memory : entity work.stage_memory(structural)
                   port map(data_in => ex_mem_register.reg_2_data,
                            data_out => mem_wb_register_next.mem_data,
                            addr_in => ex_mem_register.alu_result,
                            
                            from_master => from_master,
                            to_master => to_master,
                            
                            transfer_data_type => ex_mem_register.transfer_data_type,
                            
                            execute_read => ex_mem_register.execute_read,
                            execute_write => ex_mem_register.execute_write,
                            busy => mem_busy
                            );

    -- ========== PIPELINE REGISTERS ==========
    -- ===================== FETCH / DECODE REGISTER ===================== 
    fet_de_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (pipeline_regs_rst.fet_de_reg_rst = '1') then
                fet_de_register <= FET_DE_REGISTER_CLEAR;
            elsif (pipeline_regs_en.fet_de_reg_en = '1') then
                fet_de_register <= fet_de_register_next;
            end if;
        end if;
    end process;

    -- ===================== DECODE / EXECUTE REGISTER ===================== 
    de_ex_register_next.pc <= fet_de_register.pc;
    
    de_ex_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (pipeline_regs_rst.de_ex_reg_rst = '1') then 
                de_ex_register <= DE_EX_REGISTER_CLEAR;
            elsif (pipeline_regs_en.de_ex_reg_en = '1') then
                de_ex_register <= de_ex_register_next;
            end if;
        end if;
    end process;

    -- ===================== EXECUTE / MEMORY REGISTER ===================== 
    ex_mem_register_next.reg_wr_addr <= de_ex_register.reg_wr_addr;
    ex_mem_register_next.reg_wr_en <= de_ex_register.reg_wr_en;
    
    ex_mem_register_next.transfer_data_type <= de_ex_register.transfer_data_type;
    
    ex_mem_register_next.execute_read <= de_ex_register.execute_read;
    ex_mem_register_next.execute_write <= de_ex_register.execute_write;
              
    ex_mem_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (pipeline_regs_rst.ex_mem_reg_rst = '1') then
                ex_mem_register <= EX_MEM_REGISTER_CLEAR;
            elsif (pipeline_regs_en.ex_mem_reg_en = '1') then
                ex_mem_register <= ex_mem_register_next;
            end if;
        end if;
    end process;
    
-- ===================== MEMORY / WRITEBACK REGISTER ===================== 
    mem_wb_register_next.reg_wr_addr <= ex_mem_register.reg_wr_addr;
    mem_wb_register_next.reg_wr_en <= ex_mem_register.reg_wr_en;
           
    mem_wb_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (pipeline_regs_rst.mem_wb_reg_rst = '1') then
                mem_wb_register <= MEM_WB_REGISTER_CLEAR;
            elsif (pipeline_regs_en.mem_wb_reg_en = '1') then
                mem_wb_register <= mem_wb_register_next;
            end if;
        end if;
    end process;             

    ex_mem_forward_data <= ex_mem_register.alu_result;
    mem_wb_forward_data <= mem_wb_register.mem_data;

    fet_de_register_next.instruction <= instruction_debug;
    
    fet_de_register_next.pc <= pc;
    instruction_addr_debug <= pc;
end structural;















