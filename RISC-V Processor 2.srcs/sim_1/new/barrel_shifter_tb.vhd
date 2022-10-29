library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_shifter_tb is

end barrel_shifter_tb;

architecture Behavioral of barrel_shifter_tb is
    signal clk, reset : std_logic;
    
    signal data_in, data_out : std_logic_vector(47 downto 0);
    signal shift_amount : std_logic_vector(5 downto 0);
    signal shift_dir, shift_arith : std_logic;
    
    constant T : time := 20ns;
begin
    uut : entity work.barrel_shifter_2(rtl)
          generic map(DATA_WIDTH => 48)
          port map(data_in => data_in,
                   data_out => data_out,
                   shift_amount => shift_amount,
                   shift_direction => shift_dir,
                   shift_arith => shift_arith);

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
        data_in <= X"8000_0000_0000";
        shift_amount <= "000001";
        shift_dir <= '0';
        shift_arith <= '0';
        wait for T;
        assert data_out = X"4000_0000_0000";
        wait for T * 5;
        
        data_in <= X"8000_0000_0000";
        shift_amount <= "100000";
        shift_dir <= '0';
        shift_arith <= '0';
        wait for T;
        assert data_out = X"0000_0000_8000";
        wait for T * 5;
        
        data_in <= X"8000_0000_0000";
        shift_amount <= "000001";
        shift_dir <= '0';
        shift_arith <= '1';
        wait for T;
        assert data_out = X"C000_0000_0000";
        wait for T * 5;
        
        data_in <= X"8000_0000_0000";
        shift_amount <= "100000";
        shift_dir <= '0';
        shift_arith <= '1';
        wait for T;
        assert data_out = X"FFFF_FFFF_8000";
        wait for T * 5;
        
        data_in <= X"0000_0000_0001";
        shift_amount <= "000001";
        shift_dir <= '1';
        shift_arith <= '0';
        wait for T;
        assert data_out = X"0000_0000_0002";
        wait for T * 5;
        
        data_in <= X"0000_0000_0001";
        shift_amount <= "100000";
        shift_dir <= '1';
        shift_arith <= '0';
        wait for T;
        assert data_out = X"0001_0000_0000";
        wait for T * 5;
        
        report "Test Done."  severity failure ;
    end process;
end Behavioral;
