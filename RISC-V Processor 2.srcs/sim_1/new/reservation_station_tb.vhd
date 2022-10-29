library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reservation_station_tb is

end reservation_station_tb;

architecture Behavioral of reservation_station_tb is
    signal clk, reset, write_en, read_en : std_logic;
    
    signal cdb_opcode_bits : std_logic_vector(7 downto 0);
    signal cdb_res_stat_1 : std_logic_vector(2 downto 0);
    signal cdb_res_stat_2 : std_logic_vector(2 downto 0);
    signal cdb_operand_1 : std_logic_vector(31 downto 0);
    signal cdb_operand_2 : std_logic_vector(31 downto 0);
    
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
    
    uut : entity work.reservation_station(rtl)
          generic map(NUM_ENTRIES => 8,
                      OPCODE_BITS => 8,
                      OPERAND_BITS => 32)
          port map(i1_opcode_bits => cdb_opcode_bits,
                   i1_res_stat_1 => cdb_res_stat_1,
                   i1_res_stat_2 => cdb_res_stat_2,
                   i1_operand_1 => cdb_operand_1,
                   i1_operand_2 => cdb_operand_2,
                   clk => clk,
                   write_en => write_en,
                   read_en => read_en,
                   reset => reset);
          
    process
    begin
        cdb_opcode_bits <= (others => '0');
        cdb_res_stat_1 <= (others => '0');
        cdb_res_stat_2 <= (others => '0');
        cdb_operand_1 <= (others => '0');
        cdb_operand_2 <= (others => '0');
        write_en <= '0';
        read_en <= '0';
        
        wait for T * 10;
        
        cdb_opcode_bits <= (others => '1');
        cdb_res_stat_1 <= (others => '0');
        cdb_res_stat_2 <= (others => '0');
        cdb_operand_1 <= (others => '1');
        cdb_operand_2 <= (others => '1');
        write_en <= '1';
        
        wait for T * 2;
        
        cdb_opcode_bits <= (others => '1');
        cdb_res_stat_1 <= (others => '1');
        cdb_res_stat_2 <= (others => '0');
        cdb_operand_1 <= (others => '1');
        cdb_operand_2 <= (others => '1');
        write_en <= '1';
        
        wait for T;
        
        cdb_opcode_bits <= (others => '1');
        cdb_res_stat_1 <= (others => '0');
        cdb_res_stat_2 <= (others => '0');
        cdb_operand_1 <= (others => '1');
        cdb_operand_2 <= (others => '1');
        write_en <= '1';
        read_en <= '1';
        
        wait for T;
        
        write_en <= '0';
        read_en <= '0';
        
        wait for T * 10;
        
        read_en <= '1';
        
        wait for T * 3;
        
        read_en <= '0';
        
        wait for T;
        
        cdb_opcode_bits <= (others => '1');
        cdb_res_stat_1 <= (others => '0');
        cdb_res_stat_2 <= (others => '0');
        cdb_operand_1 <= (others => '0');
        cdb_operand_2 <= (others => '0');
        write_en <= '1';
        
        wait for T;
        
        write_en <= '0';
        
        wait for T * 1000;
        
    end process;

end Behavioral;
