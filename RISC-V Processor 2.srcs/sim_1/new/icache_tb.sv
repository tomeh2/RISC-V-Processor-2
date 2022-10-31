`timescale 1ns / 1ps

module icache_tb(
    
    );
    logic [31:0] read_addr, bus_addr_read, bus_data_read;
    logic read_en, hit, bus_stbr, bus_ackr, clk, reset;
    logic [63:0] data_out;
    
    reg [31:0] mem[15:0];
    
    
    task t_reset();
        reset <= 1;
        @(negedge clk)
        @(negedge clk)
        reset <= 0;
    endtask
    
    task t_send_req(input [31:0] addr);
        read_addr = addr;
        read_en = 1;
        wait (hit == 1)
        #4
        read_en = 0;
        read_addr = 0;
        assert (data_out[63:32] == mem[addr[5:3] + 1] && data_out[31:0] == mem[addr[5:3]]);
    endtask
    
    icache uut(.read_addr(read_addr),
               .data_out(data_out),
               .read_en(read_en),
               .hit(hit),
               .bus_addr_read(bus_addr_read),
               .bus_data_read(bus_data_read),
               .bus_stbr(bus_stbr),
               .bus_ackr(bus_ackr),
               .clk(clk),
               .reset(reset));

    always #5 clk = ~clk;
    
    always @(posedge clk) begin
        bus_ackr <= !bus_ackr && bus_stbr;
    end
    
    assign bus_data_read = mem[bus_addr_read[5:2]];
    
    initial begin
        $readmemh("../../../../icache_tb_mem_init.mem", mem);
        clk <= 0;
        bus_ackr <= 0;

        t_reset();
        
        t_send_req('h10000000);     // MISS
        #50
        t_send_req('h10000004);     // HIT
        #50
        t_send_req('h1000000B);     // MISS
    end;
    
endmodule
