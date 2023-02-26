library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu_tb is

end cpu_tb;

architecture Behavioral of cpu_tb is
    signal clk, reset, uart_rx : std_logic;
    
    constant T : time := 100ns;
    constant T_BAUD : time := 104us;    -- 9600 baud rate
begin
    cpu : entity work.cpu(structural)
          port map(clk_cpu => clk,
                   
                   gpio_i => (others => '0'),
                   
                   uart_rx => uart_rx,
                   uart_rts => '0',
                   
                   reset_cpu => reset);

    reset <= '1', '0' after T * 2;

    clock : process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;

    tb : process
    begin
        uart_rx <= '0';
        wait for 500us;
        uart_rx <= '1';
        wait for 500us;
    end process;

end Behavioral;
