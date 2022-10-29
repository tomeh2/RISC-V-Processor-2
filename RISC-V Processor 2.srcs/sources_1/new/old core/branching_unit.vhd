library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pkg_cpu.all;

entity branching_unit is
    port(
        -- Target address generation data
        pc : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        immediate : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_1_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        -- Control signals
        alu_comp_res : in std_logic;
        
        invert_branch_cond : in std_logic;
        prog_flow_cntrl : in std_logic_vector(1 downto 0);
        
        branch_target_addr : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_taken : out std_logic
    );
end branching_unit;

architecture rtl of branching_unit is
    signal base_addr_i : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal branch_target_addr_i : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);

    signal base_addr_sel_i : std_logic;
    signal cond_branch_taken_i : std_logic;
begin
    base_addr_mux : entity work.mux_2_1(rtl)
                    generic map(WIDTH_BITS => 32)
                    port map(in_0 => pc,
                             in_1 => reg_1_data,
                             output => base_addr_i,
                             sel => base_addr_sel_i);
                             
    base_addr_sel_i <= prog_flow_cntrl(1) and prog_flow_cntrl(0);
    
    branch_taken <= (prog_flow_cntrl(1) and prog_flow_cntrl(0)) or 
                    (prog_flow_cntrl(1) and not prog_flow_cntrl(0)) or
                    (not prog_flow_cntrl(1) and prog_flow_cntrl(0) and cond_branch_taken_i);
                    
    cond_branch_taken_i <= alu_comp_res xor invert_branch_cond;
    
    -- ========== BRANCH TARGET ==========
    branch_target_addr_i <= std_logic_vector(signed(base_addr_i) + signed(immediate));
    branch_target_addr(CPU_ADDR_WIDTH_BITS - 1 downto 1) <= branch_target_addr_i(CPU_ADDR_WIDTH_BITS - 1 downto 1);
    branch_target_addr(0) <= '0';
end rtl;
