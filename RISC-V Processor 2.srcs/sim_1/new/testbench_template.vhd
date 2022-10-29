library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity testbench_template is

end testbench_template;

architecture Behavioral of testbench_template is
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

end Behavioral;
