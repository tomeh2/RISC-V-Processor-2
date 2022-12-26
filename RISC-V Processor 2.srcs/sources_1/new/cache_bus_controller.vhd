----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/24/2022 03:17:50 PM
-- Design Name: 
-- Module Name: cache_bus_controller - rtl
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity cache_bus_controller is
    generic(
        ADDR_SIZE : integer;
        ENTRY_SIZE_BYTES : integer;
        ENTRIES_PER_CACHELINE : integer
    );
    port(
        bus_addr_read : out std_logic_vector(ADDR_SIZE - 1 downto 0);
        bus_data_read : in std_logic_vector(ENTRY_SIZE_BYTES * 8 - 1 downto 0);
        bus_stbr : out std_logic;
        bus_ackr : in std_logic;
    
        load_addr : in std_logic_vector(ADDR_SIZE - 1 downto 0);
        load_en : in std_logic;
        load_cancel : in std_logic;
        loader_busy : out std_logic;
        
        cache_writeback_en : out std_logic;
        cache_writeback_addr : out std_logic_vector(ADDR_SIZE - 1 downto 0);
        cache_writeback_cacheline : out std_logic_vector(ENTRY_SIZE_BYTES * 8 * ENTRIES_PER_CACHELINE - 1 downto 0);
        
        clk : in std_logic;
        reset : in std_logic
    );
end cache_bus_controller;

architecture rtl of cache_bus_controller is
    constant CACHELINE_DATA_SIZE : integer := ENTRY_SIZE_BYTES * 8 * ENTRIES_PER_CACHELINE;

    type bus_read_state_type is (IDLE,
                                 BUSY,
                                 WRITEBACK);
                                 
    signal bus_read_state : bus_read_state_type;
    signal bus_read_state_next : bus_read_state_type;
    
    signal fetched_instrs_counter : unsigned(integer(ceil(log2(real(ENTRIES_PER_CACHELINE)))) - 1 downto 0);
    signal fetched_cacheline_data : std_logic_vector(CACHELINE_DATA_SIZE - 1 downto 0);
    
    signal i_bus_curr_addr_read : std_logic_vector(ADDR_SIZE - 1 downto 0); 
    signal i_writeback_addr : std_logic_vector(ADDR_SIZE - 1 downto 0); 
begin
    -- ==================== BUS SIDE LOGIC ====================
    loader_busy <= '1' when bus_read_state /= IDLE else '0';
    
    bus_addr_read_cntrl : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                i_bus_curr_addr_read <= (others => '0');
                i_writeback_addr <= (others => '0');
            else
                if (bus_read_state = IDLE and load_en = '1') then
                    i_bus_curr_addr_read <= load_addr;
                    i_writeback_addr <= load_addr;
                elsif (bus_ackr = '1') then
                    i_bus_curr_addr_read <= std_logic_vector(unsigned(i_bus_curr_addr_read) + 4);
                end if;
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
            if (load_en = '1') then
                bus_read_state_next <= BUSY;
            else
                bus_read_state_next <= IDLE;
            end if;
        elsif (bus_read_state = BUSY) then
            if (load_cancel = '1') then
                bus_read_state_next <= IDLE;
            elsif (fetched_instrs_counter = ENTRIES_PER_CACHELINE - 1 and bus_ackr = '1') then
                bus_read_state_next <= WRITEBACK;
            else
                bus_read_state_next <= BUSY;
            end if;
        elsif (bus_read_state = WRITEBACK) then
            bus_read_state_next <= IDLE;
        end if;
    end process;
    
    bus_read_sm_actions : process(all)
    begin
        cache_writeback_en <= '0';
        bus_stbr <= '0';

        if (bus_read_state = IDLE) then

        elsif (bus_read_state = BUSY) then
            bus_stbr <= '1';
        elsif (bus_read_state = WRITEBACK) then
            cache_writeback_en <= not load_cancel;
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
    
    bus_addr_read <= i_bus_curr_addr_read;
    cache_writeback_cacheline <= fetched_cacheline_data;
    cache_writeback_addr <= i_writeback_addr;
    -- ========================================================
end rtl;
















