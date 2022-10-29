library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_div_tb is

end clock_div_tb;

architecture rtl of clock_div_tb is
    signal clk, clk_div : std_logic;
    
    signal divider : std_logic_vector(15 downto 0);
    signal reset : std_logic;
    
    constant T : time := 20ns;
begin
    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    reset <= '1', '0' after T * 2;
    
    uut : entity work.clock_divider(rtl)
          port map(clk_src => clk,
                   clk_div => clk_div,
                   divider => divider,
                   reset => reset);
    
    process
    begin
        divider <= X"0002";     -- DIVIDE BY 2
        wait for T * 100;
        divider <= X"0003";     -- DIVIDE BY 3
        wait for T * 100;
        divider <= X"0004";     -- DIVIDE BY 4
        wait for T * 100;
        divider <= X"0005";     -- DIVIDE BY 5
        wait for T * 100;
        divider <= X"0010";     -- DIVIDE BY 16
        wait for T * 100;
        divider <= X"0100";     -- DIVIDE BY 256
        wait for T * 1000;
    end process;

end rtl;
