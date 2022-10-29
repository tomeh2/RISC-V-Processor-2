library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;

entity branch_control_tb is

end branch_control_tb;

architecture Behavioral of branch_control_tb is
    signal clk : std_logic;
    signal reset : std_logic;

    constant T : time := 20ns;
    
    signal speculated_branches_mask : std_logic_vector(3 downto 0);
    signal alloc_branch_mask : std_logic_vector(3 downto 0);
    signal alloc_en, empty : std_logic;
    
    signal cdb : cdb_type;
begin
    reset <= '1', '0' after T * 2;

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    uut : entity work.branch_controller(rtl)
          port map(cdb => cdb,
          
                   speculated_branches_mask => speculated_branches_mask,
                   alloc_branch_mask => alloc_branch_mask,
                   branch_alloc_en => alloc_en,
        
                   empty => empty,
        
                   reset => reset,
                   clk => clk);
                   
    process
    begin   
        alloc_en <= '0';
        
        cdb.branch_mask <= (others => '0');
        cdb.branch_mispredicted <= '0';
        cdb.valid <= '0';
        
        wait for T * 10;
        
        alloc_en <= '1';
        
        wait for T * 10;
        
        alloc_en <= '0';
        
        wait for T * 10;
        
        cdb.branch_mask <= "0001";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.branch_mask <= "0010";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.branch_mask <= "0100";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.branch_mask <= "1000";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.valid <= '0';
        
        wait for T * 10;
        
        alloc_en <= '1';
        
        wait for T * 2;
        
        alloc_en <= '0';
        
        wait for T * 10;
        
        cdb.branch_mask <= "0001";
        cdb.valid <= '1';
        alloc_en <= '1';
        
        wait for T;
        
        wait for T * 10;
        
        cdb.branch_mask <= "0001";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.branch_mask <= "0010";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.branch_mask <= "0100";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.branch_mask <= "1000";
        cdb.valid <= '1';
        
        wait for T * 10;
        
        cdb.valid <= '0';
        alloc_en <= '1';
        
        wait for T * 10;
        
        alloc_en <= '0';
        cdb.branch_mask <= "0010";
        cdb.branch_mispredicted <= '1';
        cdb.valid <= '1';
        
        wait for T;
        
        cdb.valid <= '0';
        
        wait for T * 1000;
        
    end process;     

end Behavioral;
