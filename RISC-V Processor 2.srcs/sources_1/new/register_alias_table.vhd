library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Potentially change it to a synchronous read

entity register_alias_table is
    generic(
        PHYS_REGFILE_ENTRIES : integer range 1 to 1024;
        ARCH_REGFILE_ENTRIES : integer range 1 to 1024;
        
        VALID_BIT_INIT_VAL : std_logic;
        ENABLE_VALID_BITS : boolean
    );
    port(
        -- ========== READING PORTS ==========
        -- Inputs take the architectural register address for which we want the physical entry address
        arch_reg_addr_read_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        arch_reg_addr_read_2 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        
        -- Outputs give the physical entry address
        phys_reg_addr_read_1 : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        phys_reg_addr_read_1_v : out std_logic;
        phys_reg_addr_read_2 : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        phys_reg_addr_read_2_v : out std_logic;
        -- ===================================
        
        -- ========== WRITING PORTS ==========
        cdb_phys_dest_reg : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        cdb_valid : in std_logic;
        
        arch_reg_addr_write_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0); 
        phys_reg_addr_write_1 : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        -- ===================================
                
        -- Control signals
        rat_out : out rat_type;
        rat_in : in rat_type;
        rat_overwrite : in std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end register_alias_table;

architecture rtl of register_alias_table is
    constant PHYS_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))); 
    constant ARCH_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))); 

    constant ARCH_REGFILE_ADDR_ZERO : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');
    constant PHYS_REGFILE_ADDR_ZERO : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');

    signal rat : rat_type;
begin
    rat_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to ARCH_REGFILE_ENTRIES - 1 loop
                    rat(i) <= std_logic_vector(to_unsigned(i, PHYS_REGFILE_ADDR_BITS)) & VALID_BIT_INIT_VAL;
                end loop;
            elsif (rat_overwrite = '1') then
                rat <= rat_in;
            else
                if (arch_reg_addr_write_1 /= ARCH_REGFILE_ADDR_ZERO) then
                    rat(to_integer(unsigned(arch_reg_addr_write_1))) <= phys_reg_addr_write_1 & '0';
                end if;
                
                -- Questionable implementation of conditional generation
                if (ENABLE_VALID_BITS = true) then
                    for i in 0 to ARCH_REGFILE_ENTRIES - 1 loop
                        if (rat(i)(PHYS_REGFILE_ADDR_BITS downto 1) = cdb_phys_dest_reg and cdb_valid = '1') then
                            rat(i)(0) <= '1';
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;
    
    phys_reg_addr_read_1 <= rat(to_integer(unsigned(arch_reg_addr_read_1)))(PHYS_REGFILE_ADDR_BITS downto 1);
    phys_reg_addr_read_2 <= rat(to_integer(unsigned(arch_reg_addr_read_2)))(PHYS_REGFILE_ADDR_BITS downto 1);
    
    phys_reg_addr_read_1_v <= rat(to_integer(unsigned(arch_reg_addr_read_1)))(0);
    phys_reg_addr_read_2_v <= rat(to_integer(unsigned(arch_reg_addr_read_2)))(0);
    
    rat_out <= rat;
end rtl;
