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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity cache is
    generic(
        ADDR_SIZE_BITS : integer;
        ENTRY_SIZE_BYTES : integer;
        ENTRIES_PER_CACHELINE : integer;
        ASSOCIATIVITY : integer;
        NUM_SETS : integer
    );

    port(
        cacheline_data_write : in std_logic_vector(ENTRY_SIZE_BYTES * 8 * ENTRIES_PER_CACHELINE - 1 downto 0);
        data_read : out std_logic_vector(ENTRY_SIZE_BYTES * 8 - 1 downto 0);
        cacheline_read : out std_logic_vector((ADDR_SIZE_BITS - integer(ceil(log2(real(ENTRIES_PER_CACHELINE)))) - integer(ceil(log2(real(NUM_SETS)))) - integer(ceil(log2(real(ENTRY_SIZE_BYTES))))
                                                 + ENTRIES_PER_CACHELINE * ENTRY_SIZE_BYTES * 8) - 1 downto 0);
                                    
        read_addr : in std_logic_vector(ADDR_SIZE_BITS - 1 downto 0);
        write_addr : in std_logic_vector(ADDR_SIZE_BITS - 1 downto 0);
                             
        clear_pipeline : in std_logic;       
        stall : in std_logic;
                                    
        read_en : in std_logic;
        write_en : in std_logic;
        
        hit : out std_logic;
        miss : out std_logic;
        miss_cacheline_addr : out std_logic_vector(ADDR_SIZE_BITS - 1 downto 0);
        cacheline_valid : out std_logic;
                        
        clk : in std_logic;
        reset : in std_logic
    );
end cache;

architecture rtl of cache is
    constant TAG_SIZE : integer := ADDR_SIZE_BITS - integer(ceil(log2(real(ENTRIES_PER_CACHELINE)))) - integer(ceil(log2(real(NUM_SETS)))) - integer(ceil(log2(real(ENTRY_SIZE_BYTES))));
    constant INDEX_SIZE : integer := integer(ceil(log2(real(NUM_SETS))));
    constant CACHELINE_SIZE : integer := (TAG_SIZE + ENTRIES_PER_CACHELINE * ENTRY_SIZE_BYTES * 8);                      -- Total size of a cacheline in bits including control bits
    constant CACHELINE_ALIGNMENT : integer := integer(ceil(log2(real(ENTRIES_PER_CACHELINE * ENTRY_SIZE_BYTES))));    -- Number of bits at the end of the address which have to be 0

    constant RADDR_TAG_START : integer := ADDR_SIZE_BITS - 1;
    constant RADDR_TAG_END : integer := ADDR_SIZE_BITS - TAG_SIZE;
    constant RADDR_INDEX_START : integer := ADDR_SIZE_BITS - TAG_SIZE - 1;
    constant RADDR_INDEX_END : integer := ADDR_SIZE_BITS - TAG_SIZE - INDEX_SIZE;
    
    constant CACHELINE_TAG_START : integer := CACHELINE_SIZE - 1;
    constant CACHELINE_TAG_END : integer := CACHELINE_SIZE - TAG_SIZE;
    constant CACHELINE_DATA_START : integer := CACHELINE_SIZE - TAG_SIZE - 1;
    constant CACHELINE_DATA_END : integer := CACHELINE_SIZE - TAG_SIZE - ENTRIES_PER_CACHELINE * ENTRY_SIZE_BYTES * 8;
    
    type icache_block_type is array (0 to ASSOCIATIVITY - 1) of std_logic_vector(CACHELINE_SIZE - 1 downto 0);
    --type icache_type is array(0 to ICACHE_NUM_SETS - 1) of icache_block_type;
    --signal icache : icache_type;
    
    -- icache_valid_bits bits have to be outside of BRAM so that they can be reset
    signal icache_valid_bits : std_logic_vector(NUM_SETS * ASSOCIATIVITY - 1 downto 0);
    
    signal icache_set_out_bram : icache_block_type;
    signal icache_set_out : icache_block_type;
    signal icache_set_valid : std_logic_vector(ASSOCIATIVITY - 1 downto 0);
    
    signal hit_bits : std_logic_vector(ASSOCIATIVITY - 1 downto 0);          -- Only one bit can be active at a time
    signal i_hit : std_logic;
    signal i_bus_addr_read : std_logic_vector(ADDR_SIZE_BITS - 1 downto 0);
    
    signal cacheline_with_hit : std_logic_vector(CACHELINE_SIZE - 1 downto 0);
    signal cacheline_write : std_logic_vector(CACHELINE_SIZE - 1 downto 0);
    signal cacheline_update_en : std_logic;
    signal cacheline_update_en_delayed : std_logic;
    signal cacheline_update_sel : std_logic_vector(ASSOCIATIVITY - 1 downto 0);
    signal cacheline_update_sel_delayed : std_logic_vector(ASSOCIATIVITY - 1 downto 0);

    signal addr_read_cache : std_logic_vector(INDEX_SIZE - 1 downto 0);
    
    type c1_c2_pipeline_reg_type is record
        valid : std_logic;
        read_addr_tag : std_logic_vector(ADDR_SIZE_BITS - 1 downto 0);
        read_addr_offset : std_logic_vector(CACHELINE_ALIGNMENT - 3 downto 0);
    end record;
    
    type c2_c3_pipeline_reg_type is record
        valid : std_logic;
        read_addr_tag : std_logic_vector(ADDR_SIZE_BITS - 1 downto 0);
        read_addr_offset : std_logic_vector(CACHELINE_ALIGNMENT - 3 downto 0);
        cacheline : std_logic_vector(CACHELINE_SIZE - 1 downto 0);
        hit : std_logic;
    end record;
    
    signal c1_c2_pipeline_reg_1 : c1_c2_pipeline_reg_type;
    signal c2_c3_pipeline_reg_1 : c2_c3_pipeline_reg_type;
    
    signal c1_c2_pipeline_reg_2 : c1_c2_pipeline_reg_type;
    signal c2_c3_pipeline_reg_2 : c2_c3_pipeline_reg_type;
begin
    cacheline_update_en <= write_en;
    cacheline_write <= write_addr(RADDR_TAG_START downto RADDR_TAG_END) & cacheline_data_write;

    bram_gen : for i in 0 to ASSOCIATIVITY - 1 generate
        bram_inst : entity work.bram_primitive(rtl)
                    generic map(DATA_WIDTH => CACHELINE_SIZE,
                                SIZE => NUM_SETS)
                    port map(d => cacheline_write,
                             q => icache_set_out_bram(i),
                               
                             addr_read => addr_read_cache,
                             addr_write => write_addr(RADDR_INDEX_START downto RADDR_INDEX_END),
                                
                             read_en => read_en,
                             write_en => cacheline_update_sel(i) and cacheline_update_en,
                                 
                             clk => clk,
                             reset => reset);
    end generate;
    addr_read_cache <= read_addr(RADDR_INDEX_START downto RADDR_INDEX_END) when stall = '0' else c1_c2_pipeline_reg_1.read_addr_tag(RADDR_INDEX_START downto RADDR_INDEX_END);
    
    -- Used to generate pseudo-random signal used to select which cacheline to evict in case of an associative cache
    ring_counter_inst : entity work.ring_counter(rtl)
                        generic map(SIZE_BITS => ASSOCIATIVITY)
                        port map(q => cacheline_update_sel,
                                 clk => clk,
                                 reset => reset);

    pipeline_reg_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                c1_c2_pipeline_reg_1.valid <= '0';
                c1_c2_pipeline_reg_1.read_addr_tag <= (others => '0');
                
                c2_c3_pipeline_reg_1.cacheline <= (others => '0');
                c2_c3_pipeline_reg_1.read_addr_tag <= (others => '0');
                c2_c3_pipeline_reg_1.hit <= '0';
                c2_c3_pipeline_reg_1.read_addr_offset <= (others => '0');
                c2_c3_pipeline_reg_1.valid <= '0';
            else
                if (clear_pipeline = '1') then
                    c1_c2_pipeline_reg_1.valid <= '0';
                    c2_c3_pipeline_reg_1.valid <= '0';
                elsif (stall = '0') then
                    c1_c2_pipeline_reg_1.valid <= read_en;
                    c2_c3_pipeline_reg_1.valid <= c1_c2_pipeline_reg_1.valid;
                end if;
                
                if (stall = '0') then
                    c1_c2_pipeline_reg_1.read_addr_offset <= read_addr(CACHELINE_ALIGNMENT - 1 downto 2);
                    c1_c2_pipeline_reg_1.read_addr_tag <= read_addr(ADDR_SIZE_BITS - 1 downto CACHELINE_ALIGNMENT) & std_logic_vector(to_unsigned(0, CACHELINE_ALIGNMENT));
                    
                    c2_c3_pipeline_reg_1.cacheline <= cacheline_with_hit;
                    c2_c3_pipeline_reg_1.read_addr_tag <= c1_c2_pipeline_reg_1.read_addr_tag;
                    c2_c3_pipeline_reg_1.hit <= i_hit;
                    c2_c3_pipeline_reg_1.read_addr_offset <= c1_c2_pipeline_reg_1.read_addr_offset;
                else
                    c2_c3_pipeline_reg_1.hit <= write_en;
                    c2_c3_pipeline_reg_1.cacheline <= cacheline_write;
                end if; 
                cacheline_update_en_delayed <= cacheline_update_en;
                cacheline_update_sel_delayed <= cacheline_update_sel;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                icache_valid_bits <= (others => '0');
            else
                if (stall = '0') then
                    for i in 0 to ASSOCIATIVITY - 1 loop
                        icache_set_valid(i) <= icache_valid_bits(to_integer(unsigned(read_addr(RADDR_INDEX_START downto RADDR_INDEX_END))) * ASSOCIATIVITY + i);
                    end loop;
                else
                    for i in 0 to ASSOCIATIVITY - 1 loop
                        icache_set_valid(i) <= icache_valid_bits(to_integer(unsigned(c1_c2_pipeline_reg_1.read_addr_tag(RADDR_INDEX_START downto RADDR_INDEX_END))) * ASSOCIATIVITY + i);
                    end loop;
                end if;
                
                if (cacheline_update_en = '1') then
                    for i in 0 to ASSOCIATIVITY - 1 loop
                        if (cacheline_update_sel(i) = '1') then
                            icache_valid_bits(to_integer(unsigned(write_addr(RADDR_INDEX_START downto RADDR_INDEX_END))) * ASSOCIATIVITY + i) <= '1';
                            icache_set_valid(i) <= '1';
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;
    
    process(all)
    begin
        for i in 0 to ASSOCIATIVITY - 1 loop
            icache_set_out(i) <= icache_set_out_bram(i);
        end loop;
    end process;

    hit_detector_proc : process(all)
    begin
        for i in 0 to ASSOCIATIVITY - 1 loop
            hit_bits(i) <= '1' when (c1_c2_pipeline_reg_1.valid = '1' and icache_set_valid(i) = '1' and 
                                     c1_c2_pipeline_reg_1.read_addr_tag(RADDR_TAG_START downto RADDR_TAG_END) = icache_set_out(i)(CACHELINE_TAG_START downto CACHELINE_TAG_END)) 
                                     else '0';
        end loop;
    end process;
    
    process(all)
        variable temp : std_logic;
    begin
        temp := '0';
        for i in 0 to ASSOCIATIVITY - 1 loop
            temp := temp or hit_bits(i);
        end loop;
        i_hit <= temp;
    end process;
    
    cacheline_with_hit_gen : process(all)
    begin
        cacheline_with_hit <= (others => '0');
        for i in 0 to ASSOCIATIVITY - 1 loop
            if (hit_bits(i) = '1') then
                cacheline_with_hit <= icache_set_out(i);
            end if;
        end loop; 
    end process;
    
    data_out_gen : process(all)
    begin
        cacheline_read <= c2_c3_pipeline_reg_1.cacheline;
        data_read <= (others => '0');
        for j in 0 to ENTRIES_PER_CACHELINE - 1 loop
            if (to_integer(unsigned(c2_c3_pipeline_reg_1.read_addr_offset)) = j) then
                data_read <= c2_c3_pipeline_reg_1.cacheline(CACHELINE_DATA_END + ENTRY_SIZE_BYTES * 8 * (j + 1) - 1 downto CACHELINE_DATA_END + ENTRY_SIZE_BYTES * 8 * (j));
            end if;
        end loop;
    end process;
    
    hit <= c2_c3_pipeline_reg_1.hit and c2_c3_pipeline_reg_1.valid;
    miss <= not c2_c3_pipeline_reg_1.hit and c2_c3_pipeline_reg_1.valid;
    miss_cacheline_addr <= c2_c3_pipeline_reg_1.read_addr_tag;
    cacheline_valid <= c2_c3_pipeline_reg_1.valid and c2_c3_pipeline_reg_1.hit;
end rtl;
