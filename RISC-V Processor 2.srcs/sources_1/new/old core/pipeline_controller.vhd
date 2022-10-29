library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_pipeline.all;

entity pipeline_controller is
    port(
        -- Input Control Signals
        mem_busy : in std_logic;
        halt : in std_logic;
        branch_taken : in std_logic;
        
        reset : in std_logic;
        -- Output Control Signals
        pipeline_regs_en : out pipeline_regs_en_type;
        pipeline_regs_rst : out pipeline_regs_rst_type
    );
end pipeline_controller;

architecture rtl of pipeline_controller is

begin
    -- Logic for enable signals
    pipeline_regs_en.fet_de_reg_en <= not mem_busy or halt;
    pipeline_regs_en.de_ex_reg_en <= not mem_busy or halt;
    pipeline_regs_en.ex_mem_reg_en <= not mem_busy or halt;
    pipeline_regs_en.mem_wb_reg_en <= not mem_busy or halt;

    -- Logic for reset signals
    pipeline_regs_rst.fet_de_reg_rst <= reset or branch_taken;
    pipeline_regs_rst.de_ex_reg_rst <= reset or branch_taken;
    pipeline_regs_rst.ex_mem_reg_rst <= reset;
    pipeline_regs_rst.mem_wb_reg_rst <= reset;
end rtl;
