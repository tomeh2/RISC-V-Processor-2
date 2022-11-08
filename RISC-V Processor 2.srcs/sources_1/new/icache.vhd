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

use WORK.PKG_CPU.ALL;

entity icache is
    port(
        read_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        read_en : in std_logic;
        read_cancel : in std_logic;
        stall : in std_logic;
        
        resolving_miss : out std_logic; 
        data_valid : out std_logic;
        data_out : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
        bus_addr_read : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_data_read : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_stbr : out std_logic;
        bus_ackr : in std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end icache;

architecture rtl of icache is
    constant TAG_SIZE : integer := CPU_ADDR_WIDTH_BITS - integer(ceil(log2(real(ICACHE_INSTR_PER_CACHELINE)))) - integer(ceil(log2(real(ICACHE_NUM_SETS)))) - 2;
    constant INDEX_SIZE : integer := integer(ceil(log2(real(ICACHE_NUM_SETS))));
    constant CACHELINE_SIZE : integer := (TAG_SIZE + ICACHE_INSTR_PER_CACHELINE * 32);                      -- Total size of a cacheline in bits including control bits
    constant CACHELINE_ALIGNMENT : integer := integer(ceil(log2(real(ICACHE_INSTR_PER_CACHELINE * 4))));    -- Number of bits at the end of the address which have to be 0

    constant RADDR_TAG_START : integer := CPU_ADDR_WIDTH_BITS - 1;
    constant RADDR_TAG_END : integer := CPU_ADDR_WIDTH_BITS - TAG_SIZE;
    constant RADDR_INDEX_START : integer := CPU_ADDR_WIDTH_BITS - TAG_SIZE - 1;
    constant RADDR_INDEX_END : integer := CPU_ADDR_WIDTH_BITS - TAG_SIZE - INDEX_SIZE;
    
    constant CACHELINE_TAG_START : integer := CACHELINE_SIZE - 1;
    constant CACHELINE_TAG_END : integer := CACHELINE_SIZE - TAG_SIZE;
    constant CACHELINE_DATA_START : integer := CACHELINE_SIZE - TAG_SIZE - 1;
    constant CACHELINE_DATA_END : integer := CACHELINE_SIZE - TAG_SIZE - ICACHE_INSTR_PER_CACHELINE * 32;
   
    type icache_block_type is array (0 to ICACHE_ASSOCIATIVITY - 1) of std_logic_vector(CACHELINE_SIZE - 1 downto 0);
    type icache_type is array(0 to ICACHE_NUM_SETS - 1) of icache_block_type;
    signal icache : icache_type;
    
    -- icache_valid_bits bits have to be outside of BRAM so that they can be reset
    signal icache_valid_bits : std_logic_vector(ICACHE_NUM_SETS * ICACHE_ASSOCIATIVITY - 1 downto 0);
    
    signal icache_set_out : icache_block_type;
    signal icache_set_valid : std_logic_vector(ICACHE_ASSOCIATIVITY - 1 downto 0);
    
    signal hit_bits : std_logic_vector(ICACHE_ASSOCIATIVITY - 1 downto 0);          -- Only one bit can be active at a time
    signal i_hit : std_logic;
    
    signal valid_pipeline_reg : std_logic;
    signal read_addr_tag_pipeline_reg : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal read_addr_offset_pipeline_reg : std_logic_vector(CACHELINE_ALIGNMENT - 3 downto 0);
    signal i_bus_addr_read : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    
    signal cacheline_update_en : std_logic;
    signal cacheline_update_sel : std_logic_vector(ICACHE_ASSOCIATIVITY - 1 downto 0);
    
    -- ==================== BUS SIGNALS ====================
    type bus_read_state_type is (IDLE,
                                BUSY,
                                FINALIZE);
    signal bus_read_state : bus_read_state_type;
    signal bus_read_state_next : bus_read_state_type;
    
    signal fetched_cacheline_data : std_logic_vector(ICACHE_INSTR_PER_CACHELINE * 32 - 1 downto 0); 
    signal fetched_cacheline : std_logic_vector(CACHELINE_SIZE - 1 downto 0);
    signal fetched_instrs_counter : unsigned(integer(ceil(log2(real(ICACHE_INSTR_PER_CACHELINE)))) - 1 downto 0);
    
    -- =====================================================
begin
    -- ==================== BUS SIDE LOGIC ====================
    bus_addr_read_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                i_bus_addr_read <= (others => '0');
            end if;
            
            if (bus_read_state_next = IDLE and stall = '0') then
                i_bus_addr_read <= read_addr(CPU_ADDR_WIDTH_BITS - 1 downto CACHELINE_ALIGNMENT) & std_logic_vector(to_unsigned(0, CACHELINE_ALIGNMENT));
            elsif (bus_ackr = '1') then
                i_bus_addr_read <= std_logic_vector(unsigned(i_bus_addr_read) + 4);
            end if;
        end if;
    end process;
    
    bus_read_sm_state_reg_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                bus_read_state <= IDLE;
            else
                bus_read_state <= bus_read_state_next;
            end if;
        end if;
    end process;
    
    bus_read_sm_next_state : process(all)
    begin
        if (bus_read_state = IDLE) then
            if (valid_pipeline_reg = '1' and i_hit = '0') then
                bus_read_state_next <= BUSY;
            else
                bus_read_state_next <= IDLE;
            end if;
        elsif (bus_read_state = BUSY) then
            if (read_cancel = '1') then
                bus_read_state_next <= IDLE;
            elsif (fetched_instrs_counter = ICACHE_INSTR_PER_CACHELINE - 1 and bus_ackr = '1') then
                bus_read_state_next <= FINALIZE;
            else
                bus_read_state_next <= BUSY;
            end if;
        elsif (bus_read_state = FINALIZE) then
            bus_read_state_next <= IDLE;
        end if;
    end process;
    
    bus_read_sm_actions : process(all)
    begin
        cacheline_update_en <= '0';
        bus_stbr <= '0';
        if (bus_read_state = IDLE) then
        elsif (bus_read_state = BUSY) then
            bus_stbr <= '1';
        elsif (bus_read_state = FINALIZE) then
            cacheline_update_en <= not read_cancel;
        end if;
    end process;
    
    fetched_cacheline_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (bus_read_state = BUSY and bus_ackr = '1') then
                fetched_cacheline_data(32 * (to_integer(fetched_instrs_counter) + 1) - 1 downto 32 * to_integer(fetched_instrs_counter)) <= bus_data_read;
            end if;
        end if;
    end process;
    
    fetched_instrs_counter_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (bus_read_state = IDLE) then
                fetched_instrs_counter <= (others => '0');
            elsif (bus_read_state = BUSY and bus_ackr = '1') then
                fetched_instrs_counter <= fetched_instrs_counter + 1;
            end if;
        end if;
    end process;
    
    resolving_miss <= '1' when bus_read_state /= IDLE or bus_read_state_next = BUSY else '0';
    fetched_cacheline <= read_addr_tag_pipeline_reg(RADDR_TAG_START downto RADDR_TAG_END) & fetched_cacheline_data;
    bus_addr_read <= i_bus_addr_read;
    -- ========================================================
    
    -- ==================== CACHE LOGIC ====================
    -- Used to generate pseudo-random signal used to select which cacheline to evict in case of an associative cache
    ring_counter_inst : entity work.ring_counter(rtl)
                        generic map(SIZE_BITS => ICACHE_ASSOCIATIVITY)
                        port map(q => cacheline_update_sel,
                                 clk => clk,
                                 reset => reset);
    
    pipeline_reg_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                valid_pipeline_reg <= '0';
                read_addr_tag_pipeline_reg <= (others => '0');
            end if;
            
            if (read_cancel = '1') then
                valid_pipeline_reg <= '0';
            elsif (stall = '0') then
                valid_pipeline_reg <= read_en;
            end if;
            
            if (stall = '0') then
                read_addr_offset_pipeline_reg <= read_addr(CACHELINE_ALIGNMENT - 1 downto 2);
                read_addr_tag_pipeline_reg <= read_addr(CPU_ADDR_WIDTH_BITS - 1 downto CACHELINE_ALIGNMENT) & std_logic_vector(to_unsigned(0, CACHELINE_ALIGNMENT));
            end if; 
        end if;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                icache_valid_bits <= (others => '0');
            end if;
            
            if (stall = '0') then
                icache_set_out <= icache(to_integer(unsigned(read_addr(RADDR_INDEX_START downto RADDR_INDEX_END))));
                
                for i in 0 to ICACHE_ASSOCIATIVITY - 1 loop
                    icache_set_valid(i) <= icache_valid_bits(to_integer(unsigned(read_addr(RADDR_INDEX_START downto RADDR_INDEX_END))) * ICACHE_ASSOCIATIVITY + i);
                end loop;
            end if;
            
            if (cacheline_update_en = '1') then
                for i in 0 to ICACHE_ASSOCIATIVITY - 1 loop
                    if (cacheline_update_sel(i) = '1') then
                        icache(to_integer(unsigned(read_addr_tag_pipeline_reg(RADDR_INDEX_START downto RADDR_INDEX_END))))(i) <= fetched_cacheline;
                        
                        icache_valid_bits(to_integer(unsigned(read_addr_tag_pipeline_reg(RADDR_INDEX_START downto RADDR_INDEX_END))) * ICACHE_ASSOCIATIVITY + i) <= '1';
                        icache_set_valid(i) <= '1';
                        icache_set_out(i) <= fetched_cacheline;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    hit_detector_proc : process(all)
    begin
        for i in 0 to ICACHE_ASSOCIATIVITY - 1 loop
            hit_bits(i) <= '1' when (valid_pipeline_reg = '1' and icache_set_valid(i) = '1' and read_addr_tag_pipeline_reg(RADDR_TAG_START downto RADDR_TAG_END) = icache_set_out(i)(CACHELINE_TAG_START downto CACHELINE_TAG_END)) else '0';
        end loop;
    end process;
    
    process(all)
        variable temp : std_logic;
    begin
        temp := '0';
        for i in 0 to ICACHE_ASSOCIATIVITY - 1 loop
            temp := temp or hit_bits(i);
        end loop;
        i_hit <= temp;
    end process;
    data_valid <= i_hit and valid_pipeline_reg;
    
    data_out_gen : process(all)
    begin
        for i in 0 to ICACHE_ASSOCIATIVITY - 1 loop
            if (hit_bits(i) = '1') then
                for j in 0 to ICACHE_INSTR_PER_CACHELINE - 1 loop
                    if (to_integer(unsigned(read_addr_offset_pipeline_reg)) = j) then
                        data_out <= icache_set_out(i)(CACHELINE_DATA_END + 32 * (j + 1) - 1 downto CACHELINE_DATA_END + 32 * (j));
                    end if;
                end loop;
            end if;
        end loop; 
    end process;
    -- ========================================================

end rtl;













