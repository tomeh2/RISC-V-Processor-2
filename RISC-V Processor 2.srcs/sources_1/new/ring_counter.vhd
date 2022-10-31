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

entity ring_counter is
    generic(
        SIZE_BITS : integer 
    );
    port(
        q : out std_logic_vector(SIZE_BITS - 1 downto 0);
        
        clk : in std_logic;
        reset : in std_logic
    );
end ring_counter;

architecture rtl of ring_counter is
    signal rc_reg : std_logic_vector(SIZE_BITS - 1 downto 0);
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rc_reg <= std_logic_vector(to_unsigned(1, SIZE_BITS));
            else
                rc_reg(SIZE_BITS - 1 downto 1) <= rc_reg(SIZE_BITS - 2 downto 0);
                rc_reg(0) <= rc_reg(SIZE_BITS - 1);
            end if;
        end if;
    end process;
    
    q <= rc_reg;

end rtl;
