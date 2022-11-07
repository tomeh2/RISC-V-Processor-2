`timescale 1ns / 1ps

import pkg_cpu::*;

module front_end_tb(
    
    );
    logic [31:0] read_addr, bus_addr_read, bus_data_read;
    logic bus_stbr, bus_ackr, clk, reset;
    logic [31:0] data_out, expected, dbg_imm, dbg_pc;
    logic [3:0] debug_addr;
    logic uop_valid, dbg_clr_pipe, dbg_stall;
    
    reg [31:0] mem[15:0];
    
    cdb_type cdb1;
    uop_decoded_type uop;
    
    task t_run();
        forever begin
            #50;
        end
    endtask;
        
    task t_reset();
        reset = 1;
        @(negedge clk)
        @(negedge clk)
        reset = 0;
    endtask
    
    task t_seq_exec();
        static int i = 0;
        
        dbg_stall = 0;
        dbg_clr_pipe = 0;
        while (i < 16)
        begin
            if (uop_valid == 1) begin
                assert (dbg_imm == {5'h00000, mem[i][31:20]}) else $fatal("EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[i][31:20]}, dbg_imm);
                $display("EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[i][31:20]}, dbg_imm);
                i++;
            end
            @(negedge clk);
        end
        
        dbg_stall = 1;
        #500;
        dbg_stall = 0;
        
        i = 0;
        while (i < 16)
        begin
            if (uop_valid == 1) begin
                assert (dbg_imm == {5'h00000, mem[i][31:20]}) else $fatal("EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[i][31:20]}, dbg_imm);
                $display("EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[i][31:20]}, dbg_imm);
                i++;
            end
            @(negedge clk);
        end
    endtask;
    
//    always @(posedge clk)
//    begin
//        #5
//        if (uop_valid == 1) begin
//            assert (dbg_imm == {5'h00000, mem[dbg_pc[5:2]][31:20]}) else $fatal("EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[dbg_pc[5:2]][31:20]}, dbg_imm);
//        end
//    end
    //({5'h00000, mem[dbg_pc[5:2]][31:20]})
    front_end uut(.cdb(0),
               .fifo_full(1'b0),
               .debug_sv_immediate(dbg_imm),
               .debug_sv_pc(dbg_pc),
               .debug_clear_pipeline(dbg_clr_pipe),
               .debug_stall(dbg_stall),
               .decoded_uop_valid(uop_valid),
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
        $readmemh("../../../../front_end_tb_mem_init.mem", mem);
        clk = 0;
        bus_ackr = 0;

//        cdb1.pc_low_bits = 4'b0000;
//        cdb1.instr_tag = 4'b0000;
//        cdb1.phys_dest_reg = 7'b0000000;
//        cdb1.data = 8'h00000000;
//        cdb1.target_addr = 8'h00000000;
//        cdb1.branch_mask = 4'b0000;
//        cdb1.branch_taken = 1'b0;
//        cdb1.branch_mispredicted = 1'b0;
//        cdb1.is_jalr = 1'b0;
//        cdb1.valid = 1'b0;
        
        
        t_reset();
        t_seq_exec();
        #50;
        
    end;
    
endmodule
