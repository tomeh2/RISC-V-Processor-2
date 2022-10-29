library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity core is
    port(
        -- AXI Controller Signals
        from_master : out work.axi_interface_signal_groups.FromMaster;
        to_master : in work.axi_interface_signal_groups.ToMaster;
    
        clk_cpu : in std_logic;
        clk_dbg : in std_logic;
        
        reset_cpu : in std_logic
    );
end core;

architecture structural of core is
    signal instruction_debug : std_logic_vector(31 downto 0);
    signal instruction_addr_debug : std_logic_vector(31 downto 0);

begin
    core_pipeline : entity work.pipeline(structural)
                    port map(instruction_debug => instruction_debug,
                             instruction_addr_debug => instruction_addr_debug,
                             from_master => from_master,
                             to_master => to_master,
                             clk => clk_cpu,
                             clk_dbg => clk_dbg,
                             reset => reset_cpu);
                             
    rom : entity work.rom_memory(rtl)
          port map(data => instruction_debug,
                   addr => instruction_addr_debug(7 downto 0),
                   clk => clk_cpu);
end structural;
