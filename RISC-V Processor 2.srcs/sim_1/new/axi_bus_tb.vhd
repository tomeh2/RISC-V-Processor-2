library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pkg_axi.all;

entity axi_bus_tb is
    
end axi_bus_tb;

architecture Behavioral of axi_bus_tb is
    signal read_channels : work.pkg_axi.FromMasterInterface;
    signal write_channels : work.pkg_axi.ToMasterInterface;
    signal handshake_master_src : work.pkg_axi.HandshakeMasterSrc;
    signal handshake_slave_src : work.pkg_axi.HandshakeSlaveSrc;
    
    signal addr_write, addr_read, data_write : std_logic_vector(31 downto 0);
    signal data_in_slave : std_logic_vector(31 downto 0);
    
    signal master_interface_out : work.pkg_axi.FromMasterInterface;
    signal slave_interface_out : work.pkg_axi.FromSlaveInterface;
    
    signal burst_len : std_logic_vector(7 downto 0);
    signal burst_size : std_logic_vector(2 downto 0);
    signal burst_type : std_logic_vector(1 downto 0);
    signal clk, reset, execute_w, execute_r : std_logic;
    
    type slave_data_type is array (0 to 63) of std_logic_vector(31 downto 0);
    constant slave_data : slave_data_type := (
        0 => X"0000_0001",
        4 => X"0000_0002",
        8 => X"0000_0003",
        12 => X"0000_0004",
        16 => X"0000_0005",
        20 => X"0000_0006",
        
        others => X"0000_0000"
    );
    
    constant T : time := 20ns;
begin
    clock : process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    reset <= '1', '0' after 20ns;

    axi_interconnect : entity work.axi_interconnect(rtl)
                       port map(master_to_interface_1.data_write => data_write,
                                master_to_interface_1.addr_write => addr_write,
                                master_to_interface_1.addr_read => addr_read,
                                master_to_interface_1.execute_read => execute_r,
                                master_to_interface_1.execute_write => execute_w,
                                master_to_interface_1.burst_len => burst_len,
                                master_to_interface_1.burst_size => burst_size,
                                master_to_interface_1.burst_type => burst_type,
                                
                                master_from_interface_1 => master_interface_out,
                                
                                slave_to_interface_1.data_read => data_in_slave,
                                
                                slave_from_interface_1 => slave_interface_out,
                                
                                clk => clk,
                                reset => reset);
                           
    tb : process
    begin
        burst_len <= "00000000";
        burst_size <= "000";
        burst_type <= "00";
        
        addr_read <= X"0000_0000"; 
        
        execute_w <= '0';
        execute_r <= '0';
        wait for 100ns;
        data_write <= X"F0F0_F0F0";
        addr_write <= X"0F0F_0F0F";
        execute_w <= '1';
        
        wait for 20ns;
        execute_w <= '0';
        wait for T * 10;
        data_write <= X"AAAA_AAAA";
        addr_write <= X"BBBB_BBBB";
        execute_w <= '1';
        
        wait for 20ns;
        execute_w <= '0';
        wait for T * 20;
        addr_read <= X"CCCC_CCCC";
        data_in_slave <= X"ABCD_ABCD";
        execute_r <= '1';
        
        wait for 20ns;
        execute_r <= '0';
        wait for T * 10;
        
        wait for 20ns;
        execute_w <= '0';
        wait for T * 20;
        addr_read <= X"1111_1111";
        data_in_slave <= X"FEDC_364A";
        execute_r <= '1';
        
        wait for 20ns;
        execute_r <= '0';
        wait for T * 25;
        
        -- BURST TRANSFER TESTS
        
        burst_len <= "00001111";
        burst_size <= "010";
        burst_type <= BURST_INCR;
        
        addr_read <= X"0001_0000";
        
        execute_r <= '1';
        wait for 20ns;
        execute_r <= '0';
        wait for 100ns;
        
        data_in_slave <= X"0000_0001";
        
        wait for 20ns;
        
        data_in_slave <= X"0000_0002";
        
        wait for 20ns;
        
        data_in_slave <= X"0000_0003";
        
        wait for T * 25;
        
        burst_len <= "00001111";
        burst_size <= "010";
        burst_type <= BURST_INCR;
        
        addr_write <= X"0002_0000";
        execute_w <= '1';
        wait for 20ns;
        execute_w <= '0';
        wait for T * 50;
        
        burst_len <= "00001111";
        burst_size <= "010";
        burst_type <= BURST_WRAP;
        
        addr_write <= X"1000_0010";
        
        execute_w <= '1';
        wait for 20ns;
        execute_w <= '0';
        
        wait for T * 50;
        
        burst_len <= "00001111";
        burst_size <= "010";
        burst_type <= BURST_WRAP;
        
        addr_read <= X"1000_0010";
        
        execute_r <= '1';
        wait for 20ns;
        execute_r <= '0';
        wait for T * 50;
        
        report "Test Done."  severity failure ;
    end process;

end Behavioral;






