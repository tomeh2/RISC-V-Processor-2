library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_cpu.all;
use work.axi_interface_signal_groups.all;

entity stage_memory is
    port(
        -- Data Signals
        data_in : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        data_out : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        -- Control Signals
        addr_in : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        transfer_data_type : in std_logic_vector(2 downto 0);
        
        execute_read : in std_logic;
        execute_write : in std_logic;
        
        busy : out std_logic;
        
        -- AXI Controller Signals
        from_master : out work.axi_interface_signal_groups.FromMaster;
        to_master : in work.axi_interface_signal_groups.ToMaster
    );
end stage_memory;

architecture structural of stage_memory is

begin
    --data_out <= data_in;
    
    data_out_mux : entity work.mux_2_1(rtl)
                   generic map(WIDTH_BITS => 32)
                   port map(in_0 => addr_in,
                            in_1 => to_master.data_read,
                            output => data_out,
                            sel => execute_read);
    
    from_master.data_write <= data_in;
    from_master.addr_write <= addr_in;
    from_master.addr_read <= addr_in;
    
    from_master.burst_len <= (others => '0');
    from_master.burst_size <= '0' & transfer_data_type(1 downto 0);
    from_master.burst_type <= BURST_FIXED;
    
    from_master.execute_read <= execute_read;
    from_master.execute_write <= execute_write;
    
    busy <= (execute_read or execute_write) and (not to_master.done_read and not to_master.done_write);
end structural;











