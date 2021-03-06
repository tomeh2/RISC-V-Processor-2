library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity testbench_template is

end testbench_template;

architecture Behavioral of testbench_template is
    signal clk : std_logic;
    signal reset : std_logic;

    constant T : time := 20ns;
    
    signal branch_target_addr : std_logic_vector(31 downto 0);
    signal alloc_branch_tag : std_logic_vector(3 downto 0);
    signal alloc_en : std_logic;
begin
    reset <= '1', '0' after T * 2;

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    uut : entity work.entity_name(str)
          port map(branch_target_addr => branch_target_addr,
        
                   alloc_branch_tag => alloc_branch_tag,
                   alloc_en => alloc_en,
        
                   reset => reset,
                   clk => clk,
                   
    proce     

end Behavioral;
