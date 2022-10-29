library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_cpu.all;

entity forwarding_unit is
    port(
        reg_1_addr : in std_logic_vector(ENABLE_BIG_REGFILE + 3 downto 0);
        reg_2_addr : in std_logic_vector(ENABLE_BIG_REGFILE + 3 downto 0);
        reg_wr_addr_em : in std_logic_vector(ENABLE_BIG_REGFILE + 3 downto 0);
        reg_wr_addr_mw : in std_logic_vector(ENABLE_BIG_REGFILE + 3 downto 0);
        
        reg_1_used : in std_logic;
        reg_2_used : in std_logic;
        reg_wr_used_em : in std_logic;
        reg_wr_used_mw : in std_logic;
    
        reg_1_fwd_em : out std_logic;
        reg_1_fwd_mw : out std_logic;
        reg_2_fwd_em : out std_logic;
        reg_2_fwd_mw : out std_logic
    );
end forwarding_unit;

architecture rtl of forwarding_unit is

begin
    process(all)
    begin
        -- Register 1 forwarding
        if (reg_1_addr = reg_wr_addr_em and reg_1_used = '1' and reg_wr_used_em = '1') then
            reg_1_fwd_em <= '1';
            reg_1_fwd_mw <= '0';
        elsif (reg_1_addr = reg_wr_addr_mw and reg_1_used = '1' and reg_wr_used_mw = '1') then
            reg_1_fwd_em <= '0';
            reg_1_fwd_mw <= '1';
        else
            reg_1_fwd_em <= '0';
            reg_1_fwd_mw <= '0';
        end if; 
        
        -- Register 2 forwarding
        if (reg_2_addr = reg_wr_addr_em and reg_2_used = '1' and reg_wr_used_em = '1') then
            reg_2_fwd_em <= '1';
            reg_2_fwd_mw <= '0';
        elsif (reg_2_addr = reg_wr_addr_mw and reg_2_used = '1' and reg_wr_used_mw = '1') then
            reg_2_fwd_em <= '0';
            reg_2_fwd_mw <= '1';
        else
            reg_2_fwd_em <= '0';
            reg_2_fwd_mw <= '0';
        end if; 
    end process;

end rtl;
