library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_interface_tb is

end uart_interface_tb;

architecture Behavioral of uart_interface_tb is
    signal clk, reset, cs : std_logic;
    signal tx_line, rx_line, rts, cts, dsr : std_logic;
    
    signal data_read_bus, data_write_bus : std_logic_vector(7 downto 0);
    signal addr_bus : std_logic_vector(2 downto 0);
    
    constant T : time := 20ns;
    constant T_R : time := 8.68us;
begin
    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    reset <= '1', '0' after T * 2;
    
    uut : entity work.uart_interface(rtl)
          port map(addr_read_bus => addr_bus,
                   addr_write_bus => addr_bus,
                   data_read_bus => data_read_bus,
                   data_write_bus => data_write_bus,
                   tx => tx_line,
                   rx => rx_line,
                   rts => rts,
                   cts => cts,
                   dsr => dsr,
                   cs => cs,
                   reset => reset,
                   clk => clk);
                   
    process
    begin
        wait for T * 2;
    
        cts <= '0';
        
        -- Setup x16 baud rate generator
        cs <= '1';
        addr_bus <= "110";
        data_write_bus <= "00011011";
        wait for T;
        cs <= '1';
        data_write_bus <= X"1B";    -- 27
        addr_bus <= "110";
        wait for T;
        cs <= '1';
        data_write_bus <= X"00";    -- 0
        addr_bus <= "111";
        wait for T;
        cs <= '1';
        data_write_bus <= X"01";    -- 1
        addr_bus <= "100";
        wait for T;
        cs <= '0';
        data_write_bus <= X"00";
        addr_bus <= "000";
        
        wait for 5us;
    
        dsr <= '0';
        cts <= '0';
        rx_line <= '1';
        wait for T * 10;
        cs <= '1';
        addr_bus <= "001";
        data_write_bus <= X"BA";
        wait for T;
        cs <= '1';                  -- BEGIN TRANSMISSION
        data_write_bus <= X"02";
        addr_bus <= "100";
        wait for T;
        cs <= '1';                  -- RESET REQUEST TO SEND
        data_write_bus <= X"00";
        addr_bus <= "100";
        
        wait for 100us;
        
       
        
        wait for 5us;
        
        -- 0xAA
        rx_line <= '0';     -- START BIT
        wait for T_R;
        rx_line <= '1';     -- 1st BIT
        wait for T_R;
        rx_line <= '0';     -- 2nd BIT
        wait for T_R;
        rx_line <= '1';     -- 3rd BIT
        wait for T_R;
        rx_line <= '0';     -- 4th BIT
        wait for T_R;
        rx_line <= '1';     -- 5th BIT
        wait for T_R;
        rx_line <= '0';     -- 6th BIT
        wait for T_R;
        rx_line <= '1';     -- 7th BIT
        wait for T_R;
        rx_line <= '0';     -- 8th BIT
        wait for T_R;
        rx_line <= '1';     -- END BIT
        wait for T_R;
        
        wait for 50us;
        
        cs <= '1';
        data_write_bus <= X"01";    -- 1
        addr_bus <= "100";
        wait for T;
        cs <= '0';
        data_write_bus <= X"00";
        addr_bus <= "000";
        wait for T;
        
        -- 0xD7
        rx_line <= '0';     -- START BIT
        wait for T_R;
        rx_line <= '1';     -- 1st BIT
        wait for T_R;
        rx_line <= '1';     -- 2nd BIT
        wait for T_R;
        rx_line <= '0';     -- 3rd BIT
        wait for T_R;
        rx_line <= '1';     -- 4th BIT
        wait for T_R;
        rx_line <= '0';     -- 5th BIT
        wait for T_R;
        rx_line <= '1';     -- 6th BIT
        wait for T_R;
        rx_line <= '1';     -- 7th BIT
        wait for T_R;
        rx_line <= '1';     -- 8th BIT
        wait for T_R;
        rx_line <= '1';     -- END BIT
        wait for T_R;
        
        wait for 50us;
        
        
    end process;

end Behavioral;
