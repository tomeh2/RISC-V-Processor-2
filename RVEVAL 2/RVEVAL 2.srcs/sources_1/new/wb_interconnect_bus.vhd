library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.CONFIG.ALL;

entity wb_interconnect_bus is
    generic(
        DECODER_ADDR_WIDTH : integer := 8;
        NUM_SLAVES : integer;
        BASE_ADDRS : MEMMAP_type := (X"F0", X"F1")
    );
    port(
        wb_master_rdata : out std_logic_vector(31 downto 0);
        wb_master_wdata : in std_logic_vector(31 downto 0);
        wb_master_addr : in std_logic_vector(31 downto 0);
        wb_master_wstrb : in std_logic_vector(3 downto 0);
        wb_master_cyc : in std_logic;
        wb_master_ack : out std_logic;
        
        wb_slave_rdata : in wb_data_type(NUM_SLAVES - 1 downto 0);
        wb_slave_wdata : out std_logic_vector(31 downto 0);
        wb_slave_addr : out std_logic_vector(31 downto 0);
        wb_slave_wstrb : out std_logic_vector(3 downto 0);
        wb_slave_cyc : out std_logic_vector(NUM_SLAVES - 1 downto 0);
        wb_slave_ack : in std_logic_vector(NUM_SLAVES - 1 downto 0);
        
        clk : in std_logic;
        reset : in std_logic
    );
end wb_interconnect_bus;

architecture rtl of wb_interconnect_bus is

begin


end rtl;
