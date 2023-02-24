library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_simple_tb is

end uart_simple_tb;

architecture Behavioral of uart_simple_tb is
    signal clk : std_logic;
    signal reset : std_logic;

    signal bus_data_write : std_logic_vector(31 downto 0);
    signal bus_data_read : std_logic_vector(31 downto 0);
    signal bus_addr_write : std_logic_vector(3 downto 0);
    signal bus_addr_read : std_logic_vector(3 downto 0);
    
    signal en, rd_en, tx, rx, ack : std_logic;

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

                   wr_en => en,
                   rd_en => rd_en,
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
        rd_en <= '0';
        
        en <= '0';
        rx <= '1';
    
        wait for T * 50;
        
        bus_addr_write <= X"4";
        bus_data_write <= X"0000_0000";
        en <= '1';
        
        wait for T * 2;
        
        bus_addr_write <= X"0";
        bus_data_write <= X"0000_0010";
        en <= '1';

        wait for T * 2;
        
        bus_addr_write <= X"8";
        bus_data_write <= X"0000_0040";
        en <= '1';
        
        wait for T * 2;
        
        en <= '0';
        
        wait for T * 500;
        
        rx <= '0';
        
        wait for T * 20;
        
        rx <= '1';
        
        wait for T * 1000;
        
        rx <= '0';
        
        wait for T * 100;
        
        rx <= '1';
        
        wait for T * 100;
        
        bus_addr_read <= X"4";
        rd_en <= '1';
        
        wait for T;
        
        rd_en <= '0';
        
        wait for T * 100000;
    end process;

end Behavioral;
