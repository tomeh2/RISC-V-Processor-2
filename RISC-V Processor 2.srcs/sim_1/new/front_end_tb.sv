`timescale 1ns / 1ps

import pkg_cpu::*;

module front_end_tb(
    
    );
    logic [31:0] read_addr, bus_addr_read, bus_data_read;
    logic bus_stbr, bus_ackr, clk, reset;
    logic [31:0] data_out, expected, dbg_imm, dbg_pc, debug_cdb_targ_addr;
    logic [3:0] debug_addr;
    logic uop_valid, dbg_clr_pipe, dbg_stall, debug_cdb_valid, debug_cdb_mispred;
    
    reg [31:0] mem[31:0];
    
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
    
    task t_seq_n_instr(int n, int start_index);
        automatic int i = start_index;
        
        while (i < n)
        begin
            if (uop_valid == 1) begin
                assert (dbg_imm == {5'h00000, mem[i][31:20]}) else $fatal("EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[i][31:20]}, dbg_imm);
                $display("t_seq_n_instr: EXPECTED IMM: %h | GOT IMM: %h!", {5'h00000, mem[i][31:20]}, dbg_imm);
                i++;
            end
            @(negedge clk);
        end
        $display("t_seq_n_instr: FINISHED");
    endtask;
    
    // Jump to addr zero and load first 16 instructions
    task t_after_mispred(int n);
        debug_cdb_valid = 1;
        debug_cdb_mispred = 1;
        debug_cdb_targ_addr = 8'h0000_0010;
        
        @(negedge clk);
        
        debug_cdb_valid = 0;
        debug_cdb_mispred = 0;
        debug_cdb_targ_addr = 0;
        
        t_seq_n_instr(n, 4);
    endtask;
    
    task t_seq_exec();
        dbg_stall = 0;
        t_seq_n_instr(31, 0);
        
        dbg_stall = 1;
        #500;
        dbg_stall = 0;
        #1
        t_after_mispred(31);
        
        dbg_stall = 1;
        #500;
        dbg_stall = 0;
        #1;
    endtask;
    
    front_end uut(.cdb(0),
               .fifo_full(1'b0),
               .debug_sv_immediate(dbg_imm),
               .debug_sv_pc(dbg_pc),
               .debug_clear_pipeline(0),
               .debug_stall(dbg_stall),
               .debug_cdb_valid(debug_cdb_valid),
               .debug_cdb_targ_addr(debug_cdb_targ_addr),
               .debug_cdb_mispred(debug_cdb_mispred),
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
    
    assign bus_data_read = mem[bus_addr_read[6:2]];
    
    initial begin
        $readmemh("../../../../front_end_tb_mem_init.mem", mem);
        clk = 0;
        bus_ackr = 0;
        debug_cdb_valid = 0;
        debug_cdb_mispred = 0;
        debug_cdb_targ_addr = 0;

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
        #50000;
        
    end;
    
endmodule
