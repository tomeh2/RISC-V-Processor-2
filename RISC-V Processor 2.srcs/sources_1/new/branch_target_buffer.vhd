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

-- The BTB helps to speed up JALR instructions by predicting the target address. 

entity branch_target_buffer is
    port(
            source_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
            target_addr : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
            
            write_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
            write_en : in std_logic;
            
            clk : in std_logic
        );
end branch_target_buffer;

architecture rtl of branch_target_buffer is
    constant BTB_ADDR_WIDTH : integer := integer(ceil(log2(real(BTB_ENTRIES))));
    
    type btb_type is array (BTB_ENTRIES - 1 downto 0) of std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal btb : btb_type  := (
        others => (others => '0')
    );
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (write_en = '1') then
                btb(to_integer(unsigned(write_addr(BTB_ADDR_WIDTH - 1 downto 0)))) <= target_pc;
            end if;
        end if;
    end process;
    
    predicted_pc <= btb(to_integer(unsigned(read_addr(BTB_ADDR_WIDTH - 1 downto 0))));

end rtl;








