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
    logic[31:0] data_read, addr_1, data_1, write_addr, miss_cacheline_addr, bus_data_read, bus_addr_read;
    logic is_write, clear_pipeline, stall, valid_1, hit, miss, cacheline_valid, clk, reset, bus_ackr, bus_stbr;
    logic[1:0] write_size;
    reg [31:0] mem[15:0];
   
    cache #(.ADDR_SIZE_BITS(32),
              .ENTRY_SIZE_BYTES(4),
              .ENTRIES_PER_CACHELINE(4),
              .ASSOCIATIVITY(2),
              .NUM_SETS(16),
              .ENABLE_WRITES(1),
              .ENABLE_FORWARDING(0),
              .IS_BLOCKING(0))
             uut (
              .bus_data_read(bus_data_read),
              .bus_addr_read(bus_addr_read),
              .bus_ackr(bus_ackr),
              .bus_stbr(bus_stbr),
              .cacheline_read_1(cacheline_read),
              .data_read(data_read),
              .addr_1(addr_1),
              .data_1(data_1),
              .is_write_1(is_write),
              .write_size_1(write_size),
              .clear_pipeline(clear_pipeline),
              .stall(stall),
              .valid_1(valid_1),
              .hit(hit),
              .miss(miss),
              .cacheline_valid(cacheline_valid),
              
               .clk(clk),
               .reset(reset));
               
    task t_reset();
        reset = 1;
        @(posedge clk);
        #1;
        reset = 0;
    endtask;
               
    task t_read_req(input [31:0] addr, input [31:0] expected_data, input block);
        addr_1 = addr;
        valid_1 = 1;
        @(posedge clk);
        #1;
        valid_1 = 0;
        addr_1 = 0;
        @(posedge clk);
        #1;
        if (block == 1) begin
            wait(hit == 1);
        end;
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
        is_write = 1;
        valid_1 = 1;
        @(posedge clk);
        #1;
        is_write = 0;
        valid_1 = 0;
        addr_1 = 0;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
    endtask;
    
    always @(posedge clk) begin
        bus_ackr <= !bus_ackr && bus_stbr;
    end
    
    assign bus_data_read = mem[bus_addr_read[5:2]];
    
    task t_run();
        t_read_req('h0000_0000, 'h0000_0000, 0);
        t_read_req('h0000_0004, 'h0000_0000, 0);
        t_read_req('h0000_0008, 'h0000_0000, 0);
        t_read_req('h0000_000C, 'h0000_0000, 0);
        
        t_write_req('h0000_0000, 'h0000_FFFF);
        t_write_req('h0000_0004, 'h0000_FFFF);
        t_write_req('h0000_0008, 'h0000_FFFF);
        t_write_req('h0000_000C, 'h0000_FFFF);
    endtask;
    
    initial begin
        $readmemh("../../../../icache_tb_mem_init.mem", mem);
        clk = 0;
        is_write = 0;
        stall = 0;
        write_addr = 0;
        valid_1 = 0;
        clear_pipeline = 0;
        write_size = 0;
        
        t_reset();
        t_run();
    end
    
    always #10 clk = ~clk;
endmodule



















