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
use WORK.PKG_AXI.ALL;

entity core is
    port(
        -- TEMPORARY BUS STUFF
        bus_addr_read : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_addr_write : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_data_read : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_data_write : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_stbr : out std_logic;
        bus_stbw : out std_logic_vector(3 downto 0);
        bus_ackr : in std_logic;
        bus_ackw : in std_logic;
    
        clk : in std_logic;
        reset : in std_logic
    );
end core;

architecture structural of core is
    signal uop_ee_in : uop_decoded_type;
    signal uop_fe_out : uop_decoded_type;
    signal instruction_ready : std_logic;
    
    signal stall : std_logic;
    
    signal fifo_full : std_logic;
    signal fifo_ready : std_logic;
    signal fifo_read_en : std_logic;
    
    signal bus_stbr_fe : std_logic;
    signal bus_stbr_ee : std_logic;
    signal bus_ackr_fe : std_logic;
    signal bus_ackr_ee : std_logic;
    signal bus_addr_read_fe : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal bus_addr_read_ee : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal selected_master : std_logic;
    
    signal branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal branch_predicted_pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal branch_prediction : std_logic;
    
    signal cdb : cdb_type;
begin
    front_end : entity work.front_end(structural)
                port map(debug_clear_pipeline => '0',
                         debug_stall => '0',
                
                         cdb => cdb,
                
                         fifo_full => fifo_full,
                
                         bus_data_read => bus_data_read,
                         bus_addr_read => bus_addr_read_fe,
                         bus_ackr => bus_ackr_fe,
                         bus_stbr => bus_stbr_fe,
                         
                         decoded_uop => uop_fe_out,
                         decoded_uop_valid => instruction_ready,
                         
                         branch_mask => branch_mask,
                         branch_predicted_pc => branch_predicted_pc,
                         branch_prediction => branch_prediction,
                        
                         clk => clk,
                         reset => reset);
                         
    your_instance_name : entity work.decoded_uop_fifo
        generic map(DEPTH => DECODED_INSTR_QUEUE_ENTRIES)
      PORT MAP (
        cdb => cdb,
        clk => clk,
        reset => reset or (cdb.branch_mispredicted and cdb.valid),
        uop_in => uop_fe_out,
        wr_en => instruction_ready,
        rd_en => fifo_read_en,
        uop_out => uop_ee_in,
        full => fifo_full,
        rd_ready => fifo_ready
      );

    execution_engine : entity work.execution_engine(structural)
                       port map(bus_addr_read => bus_addr_read_ee,
                                bus_addr_write => bus_addr_write,
                                bus_data_read => bus_data_read,
                                bus_data_write => bus_data_write,
                                bus_stbr => bus_stbr_ee,
                                bus_stbw => bus_stbw,
                                bus_ackr => bus_ackr_ee,
                                bus_ackw => bus_ackw,

                                cdb_out => cdb,
                                   
                                fifo_ready => fifo_ready,
                                fifo_read_en => fifo_read_en,
                                   
                                fe_branch_mask => branch_mask,
                                fe_branch_predicted_pc => branch_predicted_pc,
                                fe_branch_prediction => branch_prediction,
                                   
                                next_uop => uop_ee_in,
                                clk => clk,
                                reset => reset);

    process(all)
    begin
        case selected_master is
            when '0' =>
                bus_addr_read <= bus_addr_read_fe;
                bus_stbr <= bus_stbr_fe;
                bus_ackr_fe <= bus_ackr;
                bus_ackr_ee <= '0';
            when '1' =>
                bus_addr_read <= bus_addr_read_ee;
                bus_stbr <= bus_stbr_ee;
                bus_ackr_ee <= bus_ackr;
                bus_ackr_fe <= '0';
            when others =>
                bus_addr_read <= (others => 'X');
                bus_stbr <= 'X';
                bus_ackr_fe <= 'X';
                bus_ackr_ee <= 'X';        
        end case;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                selected_master <= '0';
            else
                case selected_master is
                    when '0' =>
                        if((bus_ackr = '1' or bus_stbr_fe = '0') and bus_stbr_ee = '1') then
                            selected_master <= '1';
                        else
                            selected_master <= '0';
                        end if;
                    when '1' =>
                        if (bus_stbr_ee = '1') then 
                            selected_master <= '1';
                        else
                            selected_master <= '0';
                        end if;
                    when others =>
                        selected_master <= 'X';
                end case;
            end if;
        end if;
    end process;

end structural;







