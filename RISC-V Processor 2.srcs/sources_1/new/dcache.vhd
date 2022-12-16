--===============================================================================
--MIT License

--Copyright (c) 2022 Tomislav Harmina

--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:

--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.

--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.
--===============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;

entity dcache is
    port(
        read_addr_1 : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        read_valid_1 : in std_logic;
        read_ready_1 : in std_logic;
        
        write_addr_1 : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        write_data_1 : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        write_valid_1 : in std_logic;
        write_ready_1 : in std_logic;
        
    
        clk : in std_logic;
        reset : in std_logic
    );
end dcache;

architecture rtl of dcache is
    type c1_c2_pipeline_reg_type is record
        valid : std_logic;
    end record;
    
    type c2_c3_pipeline_reg_type is record
        valid : std_logic;
    end record;
    
    signal c1_c2_pipeline_reg : c1_c2_pipeline_reg_type;
    signal c2_c3_pipeline_reg : c2_c3_pipeline_reg_type;
begin
    pipeline_cntrl_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                c1_c2_pipeline_reg.valid <= '0';
                c2_c3_pipeline_reg.valid <= '0';
            else
                c1_c2_pipeline_reg.valid <= (read_valid_1 and read_ready_1) or (write_valid_1 and write_ready_1);
                c2_c3_pipeline_reg.valid <= c1_c2_pipeline_reg.valid;
            end if;
        end if;
    end process;

    cache_bram_inst : entity work.cache(rtl)
                      generic map(ADDR_SIZE_BITS => CPU_ADDR_WIDTH_BITS,
                                  ENTRY_SIZE_BYTES => 4,
                                  ENTRIES_PER_CACHELINE => DCACHE_ENTRIES_PER_CACHELINE,
                                  ASSOCIATIVITY => DCACHE_ASSOCIATIVITY,
                                  NUM_SETS => DCACHE_NUM_SETS,
                                  CACHELINE_AS_OUTPUT => true)
                      port map(cacheline_data_write => ,
                               data_read => ,
                               
                               read_addr => ,
                               write_addr => ,
                               
                               read_en => ,
                               write_en => ,
                               
                               clear_pipeline => ,
                               stall => ,
                               
                               hit => ,
                               miss => ,
                               miss_cacheline_addr => ,
                               cacheline_valid => ,
                               
                               clk => clk,
                               reset => reset);

end rtl;
