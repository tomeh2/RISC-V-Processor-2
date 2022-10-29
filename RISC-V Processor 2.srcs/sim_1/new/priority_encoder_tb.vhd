library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity priority_encoder_tb is

end priority_encoder_tb;

architecture Behavioral of priority_encoder_tb is
    signal clk : std_logic;
    
    signal d : std_logic_vector(31 downto 0);
    signal q : std_logic_vector(4 downto 0);
    
    constant T : time := 20ns;
begin
    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;

    uut : entity work.priority_encoder(rtl)
          generic map(NUM_INPUTS => 32)
          port map(d, q);

    process
    begin
        for i in 0 to 30 loop
            d <= std_logic_vector(to_unsigned(2 ** i + 453, 32));
            wait for T;
        end loop;
    end process;
end Behavioral;
