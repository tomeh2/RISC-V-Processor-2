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

-- NOTE: This implementation of the front-end is VERY EXPERIMENTAL used to develop blocks for the FE. Future implementation will have a number of optimizations (for ex. pipelining)
-- and will be be implemented from scratch using the created blocks.

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
    
        uop_decoded_tmp : out front_end_pipeline_reg_0;
    
        rom_ack : out std_logic;
    
        stall : in std_logic;
        
        branch_mask : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        branch_predicted_pc : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_prediction : out std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end front_end;

architecture Structural of front_end is
    signal fetched_instruction : std_logic_vector(31 downto 0);

    signal program_counter_reg : std_logic_vector(31 downto 0);
    
    signal rom_en : std_logic;
    signal resetn : std_logic;
    
    signal pc_overwrite_val : std_logic_vector(31 downto 0);
    signal pc_overwrite_en : std_logic;
    
    signal branch_taken_pc : std_logic_vector(31 downto 0);
    signal branch_not_taken_pc : std_logic_vector(31 downto 0);
    signal branch_alternate_pc : std_logic_vector(31 downto 0);
    signal pc_force_overwrite : std_logic;
    
    signal is_speculative_branch : std_logic;
    signal is_uncond_branch : std_logic;
    
    signal bc_speculated_branches_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal bc_branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal bc_empty : std_logic;
    
    signal btb_predicted_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    
    signal instruction_ready : std_logic;
    
    signal uop_instr_dec : uop_instr_dec_type;

    signal uop_decoded_pipeline_reg_next : front_end_pipeline_reg_0;
    
    signal stall_fe : std_logic;
    
    signal bp_in : bp_input_type;
    signal bp_out : bp_output_type;
    
    type state_type is (INACTIVE, ACTIVE);
    signal state : state_type;
    signal state_next : state_type;
    signal pc_overwritten : std_logic;
    
    signal instruction_fetched : std_logic;
begin
    resetn <= not reset;

    bp_in.fetch_addr <= program_counter_reg(CDB_PC_BITS + 1 downto 2);
    bp_in.put_addr <= cdb.pc_low_bits;
    bp_in.put_outcome <= cdb.branch_taken;
    bp_in.put_en <= '1' when cdb.branch_mask /= BRANCH_MASK_ZERO and cdb.is_jalr = '0' and cdb.valid = '1' else '0';

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

    branch_target_buffer : entity work.branch_target_buffer(rtl)
                           port map(read_addr => program_counter_reg(CDB_PC_BITS + 1 downto 2),
                                    predicted_pc => btb_predicted_pc,
                                    
                                    write_addr => cdb.pc_low_bits,
                                    write_en => cdb.is_jalr and cdb.valid,
                                    target_pc => cdb.target_addr,
                                    
                                    clk => clk);

    branch_controller : entity work.branch_controller(rtl)
                        port map(cdb => cdb,
                        
                                 speculated_branches_mask => bc_speculated_branches_mask,
                                 alloc_branch_mask => bc_branch_mask,
                                 
                                 branch_alloc_en => is_speculative_branch and not stall_fe and instruction_ready,

                                 empty => bc_empty,
                                 
                                 clk => clk,
                                 reset => reset);  

    instruction_decoder : entity work.instruction_decoder(rtl)
                          port map(cdb => cdb,
                          
                                   instruction => fetched_instruction,
                                   uop => uop_instr_dec,
                                   pc => program_counter_reg,
                                   rom_ack => instruction_fetched,

                                   branch_taken_pc => branch_taken_pc,
                                   branch_not_taken_pc => branch_not_taken_pc,

                                   is_speculative_branch => is_speculative_branch,
                                   is_uncond_branch => is_uncond_branch,
                                   pc_force_overwrite => pc_force_overwrite,
                                   
                                   instruction_ready => instruction_ready);

--    program_memory_temp : entity work.rom_memory(rtl)
--                          port map(addr => program_counter_reg(9 downto 0),
--                                   data => fetched_instruction,
--                                   en => rom_en,
--                                   --ack => open,
--                                   --reset => reset,
--                                   clk => clk);

    fetched_instruction <= bus_data_read;

    uop_decoded_pipeline_reg_next.uop_decoded.pc <= uop_instr_dec.pc;
    uop_decoded_pipeline_reg_next.uop_decoded.operation_type <= uop_instr_dec.operation_type;
    uop_decoded_pipeline_reg_next.uop_decoded.operation_select <= uop_instr_dec.operation_select;
    uop_decoded_pipeline_reg_next.uop_decoded.immediate <= uop_instr_dec.immediate;
    uop_decoded_pipeline_reg_next.uop_decoded.arch_src_reg_1_addr <= uop_instr_dec.arch_src_reg_1_addr;
    uop_decoded_pipeline_reg_next.uop_decoded.arch_src_reg_2_addr <= uop_instr_dec.arch_src_reg_2_addr;
    uop_decoded_pipeline_reg_next.uop_decoded.arch_dest_reg_addr <= uop_instr_dec.arch_dest_reg_addr;
    uop_decoded_pipeline_reg_next.uop_decoded.branch_mask <= bc_branch_mask;
    uop_decoded_pipeline_reg_next.uop_decoded.branch_predicted_outcome <= bp_out.predicted_outcome;
    uop_decoded_pipeline_reg_next.uop_decoded.speculated_branches_mask <= bc_speculated_branches_mask and not cdb.branch_mask when cdb.branch_mispredicted = '0' and cdb.valid = '1' else bc_speculated_branches_mask;
    uop_decoded_pipeline_reg_next.valid <= '1' when instruction_ready = '1' and stall_fe = '0' and not ((bc_speculated_branches_mask and cdb.branch_mask) /= BRANCH_MASK_ZERO and cdb.branch_mispredicted = '1' and cdb.valid = '1') else '0';
    uop_decoded_tmp <= uop_decoded_pipeline_reg_next;

    --rom_en <= '1' when program_counter_reg(31 downto 10) = X"00000" & "00" else '0';
    --rom_ack <= '1';        
    
    pc_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                program_counter_reg <= (others => '0');
            elsif (cdb.is_jalr = '1' and cdb.branch_mispredicted = '1' and cdb.valid = '1') then
                program_counter_reg <= cdb.target_addr;
            elsif (cdb.branch_mispredicted = '1' and cdb.valid = '1') then
                program_counter_reg <= cdb.target_addr;
            elsif ((bp_out.predicted_outcome = '0' and is_uncond_branch = '0') and is_speculative_branch = '1' and stall_fe = '0' and instruction_ready = '1') then
                program_counter_reg <= branch_not_taken_pc;
            elsif ((((bp_out.predicted_outcome = '1' or is_uncond_branch = '1') and is_speculative_branch = '1' and stall_fe = '0') or pc_force_overwrite = '1') and instruction_ready = '1') then
                program_counter_reg <= btb_predicted_pc when uop_instr_dec.operation_select(3 downto 0) = "0001" else branch_taken_pc;
            elsif (stall_fe = '0' and state = ACTIVE and bus_ackr = '1') then       -- We dont actually need to stall as soon as BC becomes empty, rather when BC is empty and next instruction is a branch
                program_counter_reg <= std_logic_vector(unsigned(program_counter_reg) + 4);
            end if;
        end if;
    end process;

    branch_mask <= bc_branch_mask;
    branch_predicted_pc <= btb_predicted_pc;
    -- Predict taken for JALR
    branch_prediction <= '1' when is_uncond_branch = '1' else bp_out.predicted_outcome;

    stall_fe <= stall or bc_empty;
    
    bus_addr_read <= program_counter_reg;
    
    pc_overwritten <= '1' when (cdb.is_jalr = '1' and cdb.branch_mispredicted = '1' and cdb.valid = '1') or
                               (cdb.branch_mispredicted = '1' and cdb.valid = '1') or
                               ((bp_out.predicted_outcome = '0' and is_uncond_branch = '0') and is_speculative_branch = '1' and stall_fe = '0'  and instruction_ready = '1') or
                               ((((bp_out.predicted_outcome = '1' or is_uncond_branch = '1') and is_speculative_branch = '1' and stall_fe = '0') or pc_force_overwrite = '1') and instruction_ready = '1') or
                               reset = '1' else '0';
    
    process(all)
    begin
        case state is
            when INACTIVE =>
                if (pc_overwritten = '1') then
                    state_next <= INACTIVE;
                else
                    state_next <= ACTIVE;
                end if;
            when ACTIVE =>
                if (pc_overwritten = '1') then
                    state_next <= INACTIVE;
                else
                    state_next <= ACTIVE;
                end if;
        end case;
    end process;
    
    process(clk)
    begin
        if (rising_edge(clk)) then
            state <= state_next;
        end if;
    end process;
    
    process(all)
    begin
        case state is
            when INACTIVE =>
                bus_stbr <= '0';
            when ACTIVE =>
                bus_stbr <= not stall_fe;
        end case;
    end process;
    
    instruction_fetched <= '1' when bus_stbr = '1' and bus_ackr = '1' else '0';
    
end Structural;
