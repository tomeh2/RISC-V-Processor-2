`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/22/2022 01:45:53 PM
// Design Name: 
// Module Name: dcache_tb
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


module dcache_tb(

    );
    logic[127:0] cacheline_write;
    logic[153:0] cacheline_read;
    logic[31:0] data_read, addr_1, data_1, write_addr, miss_cacheline_addr;
    logic is_write, clear_pipeline, stall, read_en, write_en, hit, miss, cacheline_valid, clk, reset;
    logic[1:0] write_size;
   
    cache #(.ADDR_SIZE_BITS(32),
              .ENTRY_SIZE_BYTES(4),
              .ENTRIES_PER_CACHELINE(4),
              .ASSOCIATIVITY(2),
              .NUM_SETS(16),
              .ENABLE_WRITES(1),
              .ENABLE_FORWARDING(0))
             uut (.cacheline_write_1(cacheline_write),
              .cacheline_read_1(cacheline_read),
              .data_read(data_read),
              .addr_1(addr_1),
              .data_1(data_1),
              .is_write(is_write),
              .write_size(write_size),
              .write_addr(write_addr),
              .clear_pipeline(clear_pipeline),
              .stall(stall),
              .read_en(read_en),
              .write_en(write_en),
              .hit(hit),
              .miss(miss),
              .miss_cacheline_addr(miss_cacheline_addr),
              .cacheline_valid(cacheline_valid),
              
               .clk(clk),
               .reset(reset));
               
    task t_reset();
        reset = 1;
        @(posedge clk);
        #1;
        reset = 0;
    endtask;
               
    task t_read_req(input [31:0] addr, input [31:0] expected_data);
        addr_1 = addr;
        read_en = 1;
        @(posedge clk);
        #1;
        read_en = 0;
        addr_1 = 0;
        @(posedge clk);
        #1;
        if (hit == 1) begin
            assert(data_read == expected_data) else 
                $fatal("Expected Data: %h | Got Data: %h", expected_data, data_read);
        end;
        @(posedge clk);
        #1;
    endtask;
    
    task t_write_req(input [31:0] addr, input [31:0] data);
        addr_1 = addr;
        data_1 = data;
        write_en = 1;
        @(posedge clk);
        #1;
        write_en = 0;
        addr_1 = 0;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
    endtask;
    
    task t_run();
        t_read_req('h0000_0000, 'h0000_0000);
        t_read_req('h0000_0004, 'h0000_0000);
        t_read_req('h0000_0008, 'h0000_0000);
        t_read_req('h0000_000C, 'h0000_0000);
        
        t_write_req('h0000_0000, 'h0000_FFFF);
        t_write_req('h0000_0004, 'h0000_FFFF);
        t_write_req('h0000_0008, 'h0000_FFFF);
        t_write_req('h0000_000C, 'h0000_FFFF);
    endtask;
    
    initial begin
        clk = 0;
        is_write = 0;
        stall = 0;
        write_addr = 0;
        write_en = 0;
        clear_pipeline = 0;
        write_size = 0;
        
        t_reset();
        t_run();
    end
    
    always #10 clk = ~clk;
endmodule



















