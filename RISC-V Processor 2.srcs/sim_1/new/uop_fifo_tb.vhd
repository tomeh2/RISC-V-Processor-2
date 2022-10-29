library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;

entity uop_fifo_tb is

end uop_fifo_tb;

architecture Behavioral of uop_fifo_tb is
    signal clk : std_logic;
    signal reset : std_logic;

    constant T : time := 20ns;
    
    signal rd_en, rd_ready, wr_en, full, empty : std_logic;
    signal uop_in, uop_out : uop_decoded_type;
begin
    reset <= '1', '0' after T * 2;

    uut : entity work.decoded_uop_fifo(rtl)
          generic map(DEPTH => 4)
          port map(cdb => CDB_OPEN_CONST,
                   uop_in => uop_in,
                   uop_out => uop_out,
                   
                   rd_en => rd_en,
                   rd_ready => rd_ready,
                   wr_en => wr_en,
                   
                   full => full,
                   empty => empty,
                   clk => clk,
                   reset => reset);

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;

    process
    begin
        uop_in <= UOP_ZERO;
        rd_en <= '0';
        wr_en <= '0';
        wait for T * 10;
        
        wr_en <= '1';
        
        wait for T;
        
        wr_en <= '0';
        
        wait for T * 10;
        
        rd_en <= '1';
        
        wait for T;
        
        rd_en <= '0';
        
        wait for T * 10;
        
        uop_in.operation_select <= X"01";
        wr_en <= '1';
        
        wait for T;
        
        uop_in.operation_select <= X"02";
        
        wait for T;
        
        uop_in.operation_select <= X"03";
        
        wait for T;
        
        uop_in.operation_select <= X"04";
        
        wait for T;
        
        uop_in.operation_select <= X"05";
        
        wait for T;
        
        uop_in.operation_select <= X"06";
        
        wait for T;
        
        wr_en <= '0';
        
        wait for T;
        
        wr_en <= '1';
        rd_en <= '1';
        
        wait for T * 10;
        
        wr_en <= '0';
        
        wait for T * 1000;
    end process;

end Behavioral;
