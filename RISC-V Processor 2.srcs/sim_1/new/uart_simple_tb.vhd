library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_simple_tb is

end uart_simple_tb;

architecture Behavioral of uart_simple_tb is
    signal clk : std_logic;
    signal reset : std_logic;

    signal bus_data_write : std_logic_vector(7 downto 0);
    signal bus_data_read : std_logic_vector(7 downto 0);
    signal bus_addr_write : std_logic_vector(2 downto 0);
    signal bus_addr_read : std_logic_vector(2 downto 0);
    
    signal en, tx, rx, ack : std_logic;

    constant T : time := 20ns;
begin
    reset <= '1', '0' after T * 2;

    uut : entity work.uart_simple(rtl)
          port map(bus_data_write => bus_data_write,
                   bus_data_read => bus_data_read,
                   bus_addr_write => bus_addr_write,
                   bus_addr_read => bus_addr_read,
                   bus_ack => ack,
                   
                   tx => tx,
                   rx => rx,
                   
                   en => en,
                   reset => reset,
                   clk => clk);

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    process
    begin
        bus_data_write <= (others => '0');
        bus_data_read <= (others => '0');
        bus_addr_write <= (others => '0');
        bus_addr_read <= (others => '0');
        
        en <= '0';
        rx <= '0';
    
        wait for T * 50;
        
        bus_addr_write <= "000";
        bus_data_write <= X"40";
        en <= '1';
        
        wait for T * 2;
        
        bus_addr_write <= "001";
        bus_data_write <= X"00";
        en <= '1';
        
        wait for T * 2;
        
        bus_addr_write <= "010";
        bus_data_write <= X"AA";
        en <= '1';
        
        wait for T;
        
        en <= '0';
        
        wait for T * 1000;
        
        bus_addr_write <= "010";
        bus_data_write <= X"66";
        en <= '1';
        
        wait for T;
        
        en <= '0';
        
        wait for T * 1000;
    end process;

end Behavioral;
