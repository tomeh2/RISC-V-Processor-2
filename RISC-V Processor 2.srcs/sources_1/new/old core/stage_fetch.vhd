library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_cpu.all;

entity stage_fetch is
    port(
        program_counter : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        branch_taken : in std_logic;
        branch_target_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        halt : in std_logic;
        clk : in std_logic;
        reset : in std_logic
    );
end stage_fetch;

architecture rtl of stage_fetch is
    signal program_counter_reg : unsigned(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal program_counter_next : unsigned(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    
    signal pc_reg_en : std_logic;
begin
    pc_update_process : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                program_counter_reg <= (others => '0');
            else
                if (pc_reg_en = '1') then
                    program_counter_reg <= program_counter_next;
                end if;
            end if;
        end if;
    end process;
    
    pc_next_mux_proc : process(program_counter_reg, halt, branch_taken, branch_target_addr)
    begin
        if (branch_taken = '1') then
            program_counter_next <= unsigned(branch_target_addr);
        else
            program_counter_next <= program_counter_reg + 4;
        end if; 
    end process;

    pc_reg_en <= not halt or branch_taken;
    program_counter <= std_logic_vector(program_counter_reg);

end rtl;
