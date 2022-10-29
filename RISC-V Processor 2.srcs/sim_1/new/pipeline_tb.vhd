library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pipeline_tb is
end pipeline_tb;

architecture Behavioral of pipeline_tb is
    signal instruction_bus : std_logic_vector(31 downto 0);
    signal reset, clk : std_logic;
    
    
    type test_instructions_array is array (natural range <>) of std_logic_vector(31 downto 0);
    constant test_instructions : test_instructions_array := (
        ("00000000000100001000000010010011"),         -- ADDI x1, x1, 1
        ("11111111111100010000000100010011"),         -- ADDI x2, x2, 0xFFF
        ("10000000000000011000000110010011"),         -- ADDI x3, x3, 0x400
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000010100100000001000010011"),         -- ADDI x4, x4, 5
        ("00000000111100101000001010010011"),         -- ADDI x5, x5, 15
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000010100100000001100110011"),         -- ADD x6, x4, x5
        ("01000000010100100000001110110011"),         -- SUB x7, x4, x5
        ("00000000010000001001010000110011"),         -- SLL x8, x1, x4
        ("01000000010000011101010010110011"),         -- SRA x9, x3, x4
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("10101010101010101010010100110111"),         -- LUI x10, 0xAAAAA
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000"),         -- NOP
        ("00000000000000000000000000000000")         -- NOP
        
        
        --("00000000000100001000000010110011"),         -- ADD x1, x1, x1
        --("00000000000000000000000000000000"),         -- NOP
        --("00000000000000000000000000000000"),         -- NOP
        --("00000000000000000000000000000000")          -- NOP
    );
    
    constant T : time := 20ns;
begin
    pipeline : entity work.pipeline(structural)
               port map(instruction_debug => instruction_bus,
                        reset => reset,
                        clk => clk);

    reset <= '1', '0' after T * 2;

    clock : process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;

    tb : process
    begin
        wait for T * 2;
        for i in test_instructions'range loop
            instruction_bus <= test_instructions(i);
        
            wait for T;
        
        end loop;
        
        wait for 100ns;
        
        report "Simulation Finished." severity FAILURE;
    end process;

end Behavioral;
