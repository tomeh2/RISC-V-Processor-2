library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reorder_buffer_tb is

end reorder_buffer_tb;

architecture Behavioral of reorder_buffer_tb is
    constant ENTRIES : integer range 1 to 1024 := 8;
    constant REGFILE_ENTRIES : integer range 1 to 1024 := 8;
    constant OPERAND_BITS : integer range 1 to 128 := 4;
    constant OPERATION_TYPE_BITS : integer range 1 to 64 := 4;

    signal head_dest_reg : std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
    signal head_result : std_logic_vector(OPERAND_BITS - 1 downto 0);
    
    signal cdb_data : std_logic_vector(OPERAND_BITS - 1 downto 0);
    signal cdb_tag : std_logic_vector(integer(ceil(log2(real(ENTRIES)))) - 1 downto 0);
    
    signal operation_1_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
    signal dest_reg_1 : std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
    signal write_1_en : std_logic;
    signal commit_1_en : std_logic;
    
    signal full : std_logic;
    signal empty : std_logic;
    
    signal clk : std_logic;
    signal reset : std_logic;

    constant T : time := 20ns;
begin
    reset <= '1', '0' after T * 2;

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    uut : entity work.reorder_buffer(rtl)
          generic map(ENTRIES => ENTRIES,
                      REGFILE_ENTRIES => REGFILE_ENTRIES,
                      OPERAND_BITS => OPERAND_BITS,
                      OPERATION_TYPE_BITS => OPERATION_TYPE_BITS)
          port map(head_dest_reg => head_dest_reg,
                   head_result => head_result,
                   cdb_data => cdb_data,
                   cdb_tag => cdb_tag,
                   operation_1_type => operation_1_type,
                   dest_reg_1 => dest_reg_1,
                   write_1_en => write_1_en,
                   commit_1_en => commit_1_en,
                   full => full,
                   empty => empty,
                   clk => clk,
                   reset => reset);
                   
    process
    begin
        operation_1_type <= (others => '0');
        dest_reg_1 <= (others => '0');
        write_1_en <= '0';
        commit_1_en <= '0';
        cdb_data <= (others => '0');
        cdb_tag <= (others => '0');
    
        wait for T * 10;
        
        operation_1_type <= (others => '1');
        dest_reg_1 <= (others => '1');
        write_1_en <= '1';
        
        wait for T * 20;
        
        write_1_en <= '0';
        commit_1_en <= '1';
        
        wait for T * 20;
        
        commit_1_en <= '0';
        cdb_tag <= "011";
        cdb_data <= (others => '1');
        
        wait for T;
        
        cdb_tag <= "110";
        cdb_data <= (others => '1');
        
        wait for T;
        
        cdb_tag <= "000";
        cdb_data <= (others => '1');
        
        wait for T;
        
        wait for T  * 1000;
        
    end process;

end Behavioral;
