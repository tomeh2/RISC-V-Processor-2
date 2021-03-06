--------------------------------
-- NOTES:
-- 1) Does this infer LUT-RAM?
--------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.pkg_cpu.all;

entity register_file is
    generic(
        REG_DATA_WIDTH_BITS : integer;                                                        -- Number of bits in the registers (XLEN)
        REGFILE_ENTRIES : integer                                                                -- Number of registers in the register file (2 ** REGFILE_SIZE)
    );
    port(
        -- Address busses
        rd_1_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        rd_2_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        rd_3_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        rd_4_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        wr_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        
        -- Data busses
        rd_1_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_2_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_3_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_4_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        wr_data : in std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        
        -- Control busses
    
        en : in std_logic;
        reset : in std_logic;                                                           -- Sets all registers to 0 when high (synchronous)
        clk : in std_logic;                                                             -- Clock signal input
        clk_dbg : in std_logic                                                           
    );
end register_file;

architecture rtl of register_file is
    -- ========== CONSTANTS ==========
    constant REG_ADDR_ZERO : std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0) := (others => '0'); 
    -- ===============================

    -- ========== RF REGISTERS ==========
    type reg_file_type is array (REGFILE_ENTRIES - 1 downto 0) of std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
    signal reg_file : reg_file_type;
    -- ==================================
    
begin
    -- Read from registers
    rd_1_data <= reg_file(to_integer(unsigned(rd_1_addr)));
    rd_2_data <= reg_file(to_integer(unsigned(rd_2_addr)));
    rd_3_data <= reg_file(to_integer(unsigned(rd_3_addr)));
    rd_4_data <= reg_file(to_integer(unsigned(rd_4_addr)));

    rf_access_proc : process(clk)
    begin
        -- Writing to registers
        if (rising_edge(clk)) then
            if (reset = '1') then
                reg_file <= (others => (others => '0'));
            elsif (en = '1' and wr_addr /= REG_ADDR_ZERO) then
                reg_file(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;
end rtl;
