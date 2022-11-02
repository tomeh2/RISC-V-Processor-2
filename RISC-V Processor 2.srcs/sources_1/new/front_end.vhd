--===============================================================================
--MIT License

--Copyright (c) 2022 Tomislav Harmina

--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:

--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.

--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.
--===============================================================================

-- TODO: Update PC logic in case branch mispredict resolved in D1 stage
-- TODO: Re-make BTB and connect it with prediction logic in the FE
-- TODO: Handle stalls due to a full FIFO

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity front_end is
    port(
        bus_data_read : in std_logic_vector(31 downto 0);
        bus_addr_read : out std_logic_vector(31 downto 0);
        bus_stbr : out std_logic;
        bus_ackr : in std_logic;
            
        cdb : in cdb_type;

        branch_mask : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        branch_predicted_pc : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_prediction : out std_logic;
        
        decoded_uop : out uop_decoded_type;
        decoded_uop_valid : out std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end front_end;

architecture Structural of front_end is
    -- PIPELINE
    signal f1_f2_pipeline_reg : f1_f2_pipeline_reg_type;
    signal f1_f2_pipeline_reg_next : f1_f2_pipeline_reg_type;
    
    signal f2_d1_pipeline_reg : f2_d1_pipeline_reg_type;
    signal f2_d1_pipeline_reg_next : f2_d1_pipeline_reg_type;
    
    signal stall : std_logic;
    signal branch_mispredicted : std_logic;
    signal clear_pipeline : std_logic;
    
    -- ICACHE
    signal ic_wait : std_logic;
    
    -- F1 STAGE
    signal bp_in : bp_in_type;
    signal bp_out : bp_out_type;
        
    signal f1_pc_reg : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    
    signal f1_pred_target_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal f1_pred_is_branch : std_logic;
    signal f1_pred_outcome : std_logic;
    -- F2 STAGE
    signal f2_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    
    -- D1 STAGE
    signal d1_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal d1_instr : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal d1_instr_valid : std_logic;
    
    signal d1_branch_taken_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal d1_branch_not_taken_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    
    signal d1_speculated_branches_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal d1_alloc_branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal d1_bc_empty : std_logic;
    
    signal d1_is_speculative_br : std_logic;
    signal d1_is_uncond_br : std_logic;
    
    signal d1_instr_dec_uop : uop_instr_dec_type;
begin
    -- ========================== PIPELINE CONTROL ==========================
    pipeline_reg_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                f1_f2_pipeline_reg.valid <= '0';
                f2_d1_pipeline_reg.valid <= '0';
            else
                if (stall = '0') then
                    f1_f2_pipeline_reg <= f1_f2_pipeline_reg_next;
                end if;
                f2_d1_pipeline_reg <= f2_d1_pipeline_reg_next;
            end if;
        end if;
    end process;
    
    f1_f2_pipeline_reg_next.pc <= f1_pc_reg;
    
    f2_d1_pipeline_reg_next.pc <= f1_f2_pipeline_reg.pc;
    
    f1_f2_pipeline_reg_next.valid <= '0' when clear_pipeline else '1';
    f2_d1_pipeline_reg_next.valid <= '0' when clear_pipeline else '1';
    
    stall <= ic_wait;
    branch_mispredicted <= cdb.valid and cdb.branch_mispredicted;
    clear_pipeline <= branch_mispredicted;
    -- ======================================================================

    -- ========================== F1 STAGE ========================== 
    branch_predictor_gen : if (BP_TYPE = "STATIC") generate
            bp_static : entity work.bp_static(rtl)
                        port map(bp_in => bp_in,
                                bp_out => bp_out,
                                          
                                clk => clk,
                                reset => reset);
        elsif (BP_TYPE = "2BSP") generate
            bp_2bsp : entity work.bp_saturating_counter(rtl)
                      port map(bp_in => bp_in,
                              bp_out => bp_out,
                                          
                              clk => clk,
                              reset => reset);
    end generate;
    
    pc_update_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                f1_pc_reg <= PC_VAL_INIT;
            else
                if (stall = '0') then
                    if (branch_mispredicted = '1') then
                        f1_pc_reg <= cdb.target_addr;
                    elsif (f1_pred_is_branch = '1' and f1_pred_outcome = '1') then
                        f1_pc_reg <= f1_pred_target_pc;
                    else
                        f1_pc_reg <= std_logic_vector(unsigned(f1_pc_reg) + 4);
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    bp_in.fetch_addr <= f1_pc_reg(CDB_PC_BITS + 1 downto 2);
    bp_in.put_addr <= cdb.pc_low_bits;
    bp_in.put_outcome <= cdb.branch_taken;
    bp_in.put_en <= '1' when cdb.branch_mask /= BRANCH_MASK_ZERO and cdb.is_jalr = '0' and cdb.valid = '1' else '0';
    
    f1_pred_target_pc <= (others => '0');
    f1_pred_is_branch <= '0';
    f1_pred_outcome <= bp_out.predicted_outcome and f1_pred_is_branch;
    -- ==============================================================
    
    -- ========================== F2 STAGE ==========================
    icache_inst : entity work.icache(rtl)
                  port map(read_addr => f1_pc_reg,
                           read_en => '1',
                           read_cancel => clear_pipeline,
                           
                           resolving_miss => ic_wait,
                           data_out => f2_d1_pipeline_reg_next.instruction,
                           data_valid => f2_d1_pipeline_reg_next.valid,
                           
                           bus_addr_read => bus_addr_read,
                           bus_data_read => bus_data_read,
                           bus_stbr => bus_stbr,
                           bus_ackr => bus_ackr,
                           
                           clk => clk,
                           reset => reset); 
    
    f2_d1_pipeline_reg_next.pc <= f1_f2_pipeline_reg.pc;
    -- ==============================================================
    
    -- ========================== D1 STAGE ==========================
    instruction_decoder_inst : entity work.instruction_decoder(rtl)
                               port map(instruction => f2_d1_pipeline_reg.instruction,
                                        pc => f2_d1_pipeline_reg.pc,
                                        
                                        branch_taken_pc => d1_branch_taken_pc,
                                        branch_not_taken_pc => d1_branch_taken_pc,
                                        
                                        is_speculative_branch => d1_is_speculative_br,
                                        is_uncond_branch => d1_is_uncond_br,
                                        
                                        uop => d1_instr_dec_uop);
                                        
    branch_controller_inst : entity work.branch_controller(rtl)
                             port map(cdb => cdb,
                             
                                      speculated_branches_mask => d1_speculated_branches_mask,
                                      alloc_branch_mask => d1_alloc_branch_mask,
                                      
                                      branch_alloc_en => d1_is_speculative_br and f2_d1_pipeline_reg.valid,
                                      
                                      empty => d1_bc_empty,
                                      
                                      reset => reset,
                                      clk => clk);
                                      
    decoded_uop.pc <= f2_d1_pipeline_reg.pc;
    decoded_uop.operation_type <= d1_instr_dec_uop.operation_type;
    decoded_uop.operation_select <= d1_instr_dec_uop.operation_select;
    decoded_uop.immediate <= d1_instr_dec_uop.immediate;
    decoded_uop.arch_src_reg_1_addr <= d1_instr_dec_uop.arch_src_reg_1_addr;
    decoded_uop.arch_src_reg_2_addr <= d1_instr_dec_uop.arch_src_reg_2_addr;
    decoded_uop.arch_dest_reg_addr <= d1_instr_dec_uop.arch_dest_reg_addr;
    decoded_uop.branch_mask <= d1_alloc_branch_mask;
    decoded_uop.branch_predicted_outcome <= ;
    decoded_uop.speculated_branches_mask <= d1_speculated_branches_mask;
    decoded_uop_valid <= f2_d1_pipeline_reg.valid;
    -- ==============================================================
end Structural;










