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

entity uart_simple is
    port(
        bus_data_write : in std_logic_vector(31 downto 0);
        bus_data_read : out std_logic_vector(31 downto 0);
        bus_addr_write : in std_logic_vector(3 downto 0);
        bus_addr_read : in std_logic_vector(3 downto 0);
        bus_ack : out std_logic;
        
        tx : out std_logic;
        rx : in std_logic;
        
        wr_en : in std_logic;
        rd_en : in std_logic;
        clk : in std_logic;
        reset : in std_logic
    );
end uart_simple;

architecture rtl of uart_simple is
    -- REGISTERS
    signal div_h_reg : std_logic_vector(7 downto 0);
    signal div_l_reg : std_logic_vector(7 downto 0);
    signal data_tx_reg : std_logic_vector(7 downto 0);
    signal data_rx_reg : std_logic_vector(7 downto 0);
    signal status_reg : std_logic_vector(7 downto 0);       -- [0: TX START | 1: TX FINISHED | 2 - 7: RESERVED]
    signal status_reg_en : std_logic;       -- [0: TX START | 1: TX FINISHED | 2 - 7: RESERVED]
    
    signal baud_div : std_logic_vector(15 downto 0);
    
    -- INTERNAL SIGNALS
    signal baud_gen_counter_reg : unsigned(15 downto 0);
    signal baud_gen_counter_next : unsigned(15 downto 0);
    signal baud_gen_counter_en : std_logic;
    signal baud_tick : std_logic;
    
    signal tx_start : std_logic;
    signal tx_end : std_logic;
    
    signal bits_transmitted : unsigned(2 downto 0);
    
    type uart_tx_state_type is (IDLE, START_BIT, BUSY, END_BIT);
    signal uart_tx_state : uart_tx_state_type;
    signal uart_tx_state_next : uart_tx_state_type;
    
    -- BUS INTERNAL SIGNALS
    signal bus_data_read_i : std_logic_vector(31 downto 0);
    signal ack_i : std_logic;
begin
    -- REGISTER CONTROL
    status_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                status_reg <= (others => '0');
            elsif (status_reg_en = '1') then
                if (tx_end = '1') then
                    status_reg(0) <= '0';
                elsif (tx_start = '1') then
                    status_reg(0) <= '1';
                end if;
            end if;
        end if;
    end process;
    
    status_reg_en <= tx_start or tx_end;
    tx_start <= '1' when wr_en = '1' and bus_addr_write = X"2" else '0';
    tx_end <= '1' when uart_tx_state = END_BIT and baud_tick = '1' else '0'; 
    
    registers_write_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                div_l_reg <= (others => '1');
                div_h_reg <= (others => '1');
            elsif (wr_en = '1') then
                case bus_addr_write is 
                    when X"0" =>
                        div_l_reg <= bus_data_write(7 downto 0);
                    when X"1" =>
                        div_h_reg <= bus_data_write(15 downto 8);
                    when X"2" =>
                        data_tx_reg <= bus_data_write(23 downto 16);
                    when others =>
                    
                end case;
            end if;
        end if;
    end process;

    bus_data_read_i <= status_reg & data_tx_reg & div_h_reg & div_l_reg;
    registers_read_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            bus_data_read <= bus_data_read_i;
        end if;
    end process;
    
    -- BAUD GENERATION
    baud_gen_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                baud_gen_counter_reg <= (others => '0');
            elsif (baud_gen_counter_en = '1') then
                baud_gen_counter_reg <= baud_gen_counter_next;
            end if;
        end if;
    end process;
    
    baud_div <= div_h_reg & div_l_reg;
    baud_gen_counter_next_sel : process(all)
    begin
        if ((uart_tx_state = IDLE) or (std_logic_vector(baud_gen_counter_reg) = baud_div)) then
            baud_gen_counter_next <= (others => '0');
        else
            baud_gen_counter_next <= baud_gen_counter_reg + 1;
        end if;
    end process;
    
    baud_tick <= '1' when std_logic_vector(baud_gen_counter_reg) = baud_div else '0';
    
    -- TX ENGINE
    bits_transmitted_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                bits_transmitted <= (others => '0');
            else
                if (uart_tx_state = BUSY) then
                    if (baud_tick = '1') then
                        bits_transmitted <= bits_transmitted + 1;
                    end if;
                else
                    bits_transmitted <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    tx_sm_state_reg_proc : process(clk) 
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                uart_tx_state <= IDLE;
            else
                uart_tx_state <= uart_tx_state_next;
            end if;
        end if;
    end process;
    
    tx_sm_state_next : process(all)
    begin
        case uart_tx_state is
            when IDLE =>
                if (status_reg(0) = '1') then
                    uart_tx_state_next <= START_BIT;
                else
                    uart_tx_state_next <= IDLE;
                end if;
            when START_BIT =>
                if (baud_tick = '1') then
                    uart_tx_state_next <= BUSY;
                else
                    uart_tx_state_next <= START_BIT;                
                end if;
            when BUSY =>
                if (bits_transmitted = 7 and baud_tick = '1') then
                    uart_tx_state_next <= END_BIT;
                else
                    uart_tx_state_next <= BUSY;
                end if;
            when END_BIT =>
                if (baud_tick = '1') then
                    uart_tx_state_next <= IDLE;
                else
                    uart_tx_state_next <= END_BIT;
                end if;
            when others =>
                uart_tx_state_next <= IDLE;
        end case;
    end process;
    
    tx_proc : process(all)
    begin
        case uart_tx_state is
            when IDLE =>
                tx <= '1';
                baud_gen_counter_en <= '0';
            when START_BIT =>
                tx <= '0';
                baud_gen_counter_en <= '1';
            when BUSY =>
                tx <= data_tx_reg(to_integer(bits_transmitted));
                baud_gen_counter_en <= '1';
            when END_BIT =>
                tx <= '1';
                baud_gen_counter_en <= '1';
        end case;
    end process;
    
    -- BUS INTERNAL SIGNALS
    ack_generate_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                ack_i <= '0';
            else
                ack_i <= (wr_en or rd_en) and not ack_i; 
            end if;
        end if;
    end process;
    
    bus_ack <= ack_i;

end rtl;















