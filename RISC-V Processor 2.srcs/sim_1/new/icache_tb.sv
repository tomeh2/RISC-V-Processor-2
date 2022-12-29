`timescale 1ns / 1ps

module icache_tb(
    
    );
    logic [31:0] read_addr, bus_addr_read, bus_data_read;
    logic read_en, hit, bus_stbr, bus_ackr, clk, reset;
    logic [31:0] data_out, expected;
    logic [3:0] debug_addr;
    
    reg [31:0] mem[15:0];
    
    task t_run();
        forever begin
            t_send_req($random());
            wait (hit == 1);
            #50;
        end
    endtask;
        
    task t_reset();
        reset = 1;
        @(negedge clk)
        @(negedge clk)
        reset = 0;
    endtask
    
    task t_send_req(input [31:0] addr);
        @(negedge clk)
        read_addr = addr;
        read_en = 1;
        @(posedge clk)
        #1;
        read_en = 0;
        wait (hit == 1)
        @(negedge clk)
        read_en = 0;
        read_addr = 0;
        debug_addr = addr[5:2]; 
        expected = mem[debug_addr]; 
        assert (data_out == expected)
            else $fatal("Expected: %h | Got: %h", expected, data_out);
    endtask
    
    task t_send_req_norst(input [31:0] addr);
        @(negedge clk)
        read_addr = addr;
        read_en = 1;
        wait (hit == 1)
        debug_addr = addr[5:2];
        expected = mem[debug_addr]; 
        assert (data_out == expected)
            else $fatal("Expected: %h | Got: %h", expected, data_out);
    endtask
    
    icache uut(.read_addr(read_addr),
               .read_cancel(0),
               .data_out(data_out),
               .read_en(read_en),
               .data_valid(hit),
               .stall(0),
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
        clk = 0;
        bus_ackr = 0;
        read_en = 0;

        t_reset();
        #50
        t_send_req('h00000000);         //MISS
        t_send_req('h00000004);         //HIT
        t_send_req('h00000008);         //HIT
        t_send_req('h0000000C);         //HIT
        t_send_req('h00000038);         //MISS
        #50
        t_send_req('h000001F8);         //MISS
        #500
        //t_run();
        #1000000;
    end;
    
endmodule
