----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/30/2022 03:08:05 PM
-- Design Name: 
-- Module Name: soc - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.CONFIG.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity soc is
--  Port ( );
end soc;

architecture rtl of soc is
    component picorv32
		generic(
			STACKADDR : std_logic_vector(31 downto 0) := STACK_ADDR;
			PROGADDR_RESET : std_logic_vector(31 downto 0) := RESET_PC;
			ENABLE_COUNTERS : boolean := true;
			ENABLE_COUNTERS64 : boolean := true;
			ENABLE_REGS_16_31 : boolean := true;
			ENABLE_REGS_DUALPORT : boolean := true;
			LATCHED_MEM_RDATA : boolean := false;
			TWO_STAGE_SHIFT : boolean := true;
			BARREL_SHIFTER : boolean := true;
			TWO_CYCLE_COMPARE : boolean := false;
			TWO_CYCLE_ALU : boolean := false;
			COMPRESSED_ISA : boolean := false;
			CATCH_ILLINSN : boolean := true;
			ENABLE_PCPI : boolean := false;
			ENABLE_MUL : boolean := false;
			ENABLE_DIV : boolean := false;
			ENABLE_FAST_MUL : boolean := false;
			ENABLE_IRQ : boolean := false;
			ENABLE_IRQ_QREGS : boolean := true;
			ENABLE_IRQ_TIMER : boolean := true;
			ENABLE_TRACE : boolean := false;
			REGS_INIT_ZERO : boolean := true;
			MASKED_IRQ : std_logic_vector(31 downto 0) := (others => '0');
			LATCHED_IRQ : std_logic_vector(31 downto 0) := (others => '0');
			PROGADDR_IRQ : std_logic_vector(31 downto 0) := (others => '0')
		);
		port(
			mem_valid : out std_logic;
			mem_instr : out std_logic;
			mem_ready : in std_logic;
			mem_addr : out std_logic_vector(31 downto 0);
			mem_wdata : out std_logic_vector(31 downto 0);
			mem_wstrb : out std_logic_vector(3 downto 0);
			mem_rdata : in std_logic_vector(31 downto 0);
			
			pcpi_wr : in std_logic;
			pcpi_rd : in std_logic_vector(31 downto 0);
			pcpi_ready : in std_logic;
			pcpi_wait : in std_logic;
			
			mem_la_read : out std_logic;
			mem_la_write : out std_logic;
			mem_la_addr : out std_logic_vector(31 downto 0);
			mem_la_wdata : out std_logic_vector(31 downto 0);
			mem_la_wstrb : out std_logic_vector(3 downto 0);
			
			pcpi_valid : out std_logic;
			pcpi_insn : out std_logic_vector(31 downto 0);
			pcpi_rs1 : out std_logic_vector(31 downto 0);
			pcpi_rs2 : out std_logic_vector(31 downto 0);
			
			irq : in std_logic_vector(31 downto 0);
			eoi : out std_logic_vector(31 downto 0);
			
			trace_valid : out std_logic;
			trace_data : out std_logic_vector(35 downto 0);
			
			trap : out std_logic;
			clk : in std_logic;
			resetn : in std_logic
		);
	end component;
    
    component simpleuart
		port(
			clk : in std_logic;
			resetn : in std_logic;
			
			ser_tx : out std_logic;
			ser_rx : in std_logic;
			
			reg_div_we : in std_logic_vector(3 downto 0);
			reg_div_di : in std_logic_vector(31 downto 0);
			reg_div_do : out std_logic_vector(31 downto 0);
			
			reg_dat_we : in std_logic;
			reg_dat_re : in std_logic;
			
			reg_dat_di : in std_logic_vector(31 downto 0);
			reg_dat_do : out std_logic_vector(31 downto 0);
			reg_dat_wait : out std_logic
		);
	end component;

    signal wb_cpu_rdata : std_logic_vector(31 downto 0);
    signal wb_cpu_wdata : std_logic_vector(31 downto 0);
    signal wb_cpu_addr : std_logic_vector(31 downto 0);
    signal wb_cpu_wstrb : std_logic_vector(3 downto 0);
    signal wb_cpu_ready : std_logic;
    signal wb_cpu_valid : std_logic;
    
    signal wb_uart_rdata : std_logic_vector(31 downto 0);
    signal wb_uart_wdata : std_logic_vector(31 downto 0);
    signal wb_uart_addr : std_logic_vector(31 downto 0);
    signal wb_uart_wstrb : std_logic_vector(3 downto 0);
    signal wb_uart_ready : std_logic;
    signal wb_uart_valid : std_logic;
begin


end rtl;
