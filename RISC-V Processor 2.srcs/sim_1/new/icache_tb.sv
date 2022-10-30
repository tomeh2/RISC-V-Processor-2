`timescale 1ns / 1ps

module icache_tb(
    
    );
    logic [31:0] read_addr, bus_addr_read, bus_data_read;
    logic read_en, hit, bus_stbr, bus_ackr, clk, reset;
    logic [63:0] data_out;
    
    icache uut(.read_addr(read_addr),
               .read_en(read_en),
               .hit(hit),
               .bus_addr_read(bus_addr_read),
               .bus_data_read(bus_data_read),
               .bus_stbr(bus_stbr),
               .bus_ackr(bus_ackr),
               .clk(clk),
               .reset(reset));
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        bus_ackr = 0;
        @(posedge clk)
        @(negedge clk)
        reset = 0;
        bus_data_read = 'hFFFFFFFF;
        read_addr = 'h10000000;
        read_en = 1;
        @(negedge clk)
        read_en = 0;
        @(negedge clk)
        @(negedge clk)
        @(negedge clk)
        @(negedge clk)
        @(posedge clk)
        #1
        bus_ackr = 1;
        @(posedge clk)
        #1
        bus_ackr = 0;
        @(posedge clk)
        #1
        bus_ackr = 1;
        @(posedge clk)
        #1
        bus_ackr = 0;
        @(posedge clk)
        #1
        #500;
    end;
    
endmodule
