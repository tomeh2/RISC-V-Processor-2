`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2023 12:53:10 PM
// Design Name: 
// Module Name: btb_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module btb_tb(

    );
    
    logic clk, reset, read_en, write_en, hit;
    logic[31:0] branch_addr, target_addr, branch_write_addr, branch_write_target_addr;

        
    task t_reset();
        reset = 1;
        @(negedge clk)
        @(negedge clk)
        reset = 0;
    endtask
    
    task t_write_entry(logic[31:0] write_addr, logic[31:0] targ_addr);
        branch_write_addr = write_addr;
        branch_write_target_addr = targ_addr;
        write_en = 1;
        @(posedge clk);
        #1;
        branch_write_addr = 0;
        branch_write_target_addr = 0;
        write_en = 0;
    endtask
    
    task t_read_entry(logic[31:0] read_addr);
        branch_addr = read_addr;
        read_en = 1;
        @(posedge clk);
        #1;
        branch_addr = 0;
        read_en = 0;
    endtask
    
    branch_target_buffer uut(
               .branch_addr(branch_addr),
               .target_addr(target_addr),
               .read_en(read_en),
               .hit(hit),
               .branch_write_addr(branch_write_addr),
               .branch_write_target_addr(branch_write_target_addr),
               .write_en(write_en),
               .clk(clk),
               .reset(reset));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        read_en = 0;

        t_reset();
        t_write_entry('hAAAA_A000, 'h1111_1111);
        t_write_entry('hBBBB_B004, 'h2222_2222);
        t_write_entry('hCCCC_C008, 'h3333_3333);
        t_write_entry('hFFFF_FFCC, 'h4444_4444);
        
        t_read_entry('hAAAA_A000);  // HIT
        t_read_entry('hBBBB_C004);  // MISS
        t_read_entry('hFFCC_C008);  // HIT (DUE TO LESS TAG BITS THEN IDEAL)
        t_read_entry('h0000_000C);  // MISS
    end;
endmodule
