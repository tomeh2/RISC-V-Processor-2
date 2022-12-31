library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package config is
    constant STACK_ADDR : std_logic_vector(31 downto 0) := X"0000_0000";
    constant RESET_PC : std_logic_vector(31 downto 0) := X"0000_0000";
    
    subtype wb_data_type is std_logic_vector(31 downto 0);
    subtype wb_addr_type is std_logic_vector(31 downto 0);

    type MEMMAP_type is array (natural range <>) of std_logic_vector(7 downto 0); 
end config;