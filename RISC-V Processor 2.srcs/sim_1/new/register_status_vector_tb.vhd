library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity register_status_vector_tb is
--  Port ( );
end register_status_vector_tb;

architecture Behavioral of register_status_vector_tb is
    constant PHYS_REGFILE_ENTRIES : integer := 16;
    constant ARCH_REGFILE_ENTRIES : integer := 4;

    signal free_reg_alias : std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
    signal alloc_reg_alias : std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
    
    signal put_en, get_en, empty, clk, reset : std_logic;
    
    constant T : time := 20ns;
begin
    uut : entity work.register_alias_allocator_2(rtl)
          generic map(PHYS_REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES,
                      ARCH_REGFILE_ENTRIES => ARCH_REGFILE_ENTRIES)
          port map(free_reg_alias => free_reg_alias,
                   alloc_reg_alias => alloc_reg_alias,
                   put_en => put_en,
                   get_en => get_en,
                   empty => empty,
                   clk => clk,
                   reset => reset
                   );
               
    reset <= '1', '0' after T;
                   
    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    process
    begin
        get_en <= '0';
        put_en <= '0';
        free_reg_alias <= (others => '0');
    
        wait for T;
    
        get_en <= '1';
        
        wait for T * 100;
        get_en <= '0';
        
        free_reg_alias <= "0000";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "0001";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "0010";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "0011";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "0100";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "1111";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "1110";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "1101";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "1100";
        put_en <= '1';
        
        wait for T;
        
        free_reg_alias <= "1000";
        put_en <= '1';
        
        wait for T;
        
        
    end process;

end Behavioral;
