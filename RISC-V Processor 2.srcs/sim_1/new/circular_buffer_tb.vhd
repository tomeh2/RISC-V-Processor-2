library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity circular_buffer_tb is

end circular_buffer_tb;

architecture Behavioral of circular_buffer_tb is
    signal data_write, data_read : std_logic_vector(7 downto 0);
    signal read_en, write_en, full, empty : std_logic;

    signal clk : std_logic;
    signal reset : std_logic;

    constant T : time := 20ns;
begin
    reset <= '1', '0' after T * 2;

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    uut : entity work.circular_buffer(rtl)
          generic map(ENTRY_BITS => 8,
                      BUFFER_ENTRIES => 8)
          port map(data_write => data_write,
                   data_read => data_read,
                   
                   read_en => read_en,
                   write_en => write_en,
                   
                   full => full,
                   empty => empty,
                   
                   reset => reset,
                   clk => clk);
                   
    process
    begin
        wait for T * 2;
        write_en <= '1';
        data_write <= "01010101";
        wait for T * 10;
        write_en <= '0';
        read_en <= '1';
        wait for T * 10;
        read_en <= '0';
        write_en <= '1';
        data_write <= "10101010";
        wait for T * 10;
        write_en <= '0';
        read_en <= '1';
        wait for T * 200;
    end process;

end Behavioral;
