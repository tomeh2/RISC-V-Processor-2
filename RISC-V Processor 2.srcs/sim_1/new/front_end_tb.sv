`timescale 1ns / 1ps

import pkg_cpu::*;

module front_end_tb(
    
    );
    logic [31:0] read_addr, bus_addr_read, bus_data_read;
    logic bus_stbr, bus_ackr, clk, reset;
    logic [31:0] data_out, expected, dbg_imm, dbg_pc, debug_cdb_targ_addr, debug_f2_d1_pc, debug_f2_d1_instr;
    logic [3:0] debug_addr;
    logic uop_valid, dbg_clr_pipe, dbg_stall, debug_cdb_valid, debug_cdb_mispred, debug_f2_d1_valid;
    
    reg [31:0] mem[31:0];
    
    cdb_type cdb1;
    uop_decoded_type uop;
    
    static int simulated_pc = 0;
    
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
    
    task t_seq_n_instr(int n, logic [31:0] start_pc);
        for (int i = 0; i < n; i++) begin
            wait (debug_f2_d1_valid == 1'b1);
            
            /* Make sure that the PC corresponds to the correct instruction in memory */
            assert (mem[debug_f2_d1_pc[6:2]] == debug_f2_d1_instr && debug_f2_d1_pc == start_pc) else 
                $fatal("Instruction mismatch! F2_D1_PC = %h | INSTR_F2_D1 = %h | PC = %h | INSTR_MEM = %h\n", debug_f2_d1_pc, debug_f2_d1_instr, start_pc, mem[debug_f2_d1_pc[6:2]]);
                
            start_pc += 4;
            @(posedge clk);
            #1;
        end
        $info("OK");
    endtask;

    task t_cdb_mispred(logic [31:0] targ_addr);
        debug_cdb_valid = 1;
        debug_cdb_mispred = 1;
        debug_cdb_targ_addr = targ_addr;
        
        @(posedge clk);
        #1;
        
        debug_cdb_valid = 0;
        debug_cdb_mispred = 0;
        debug_cdb_targ_addr = 0;
        
        //t_seq_n_instr(n, 4);
    endtask;
    
    task t_run_stall_run(int n, logic [31:0] start_pc);
        t_seq_n_instr(n / 2, start_pc);
        
        dbg_stall = 1;
        #1000;
        dbg_stall = 0;
        
        t_seq_n_instr(n / 2, start_pc + (n / 2 * 4));
    endtask;
    
    task t_seq_exec();
        dbg_stall = 0;
        
        t_seq_n_instr(32, 8'h0000_0000);
        t_cdb_mispred(8'h0000_0020);
        t_seq_n_instr(32, 8'h0000_0020);
        t_cdb_mispred(8'h0000_0000);
        t_run_stall_run(32, 8'h0000_0000);
    endtask;
    
    front_end uut(.cdb(0),
               .debug_sv_immediate(dbg_imm),
               .debug_sv_pc(dbg_pc),
               .debug_clear_pipeline(0),
               .debug_cdb_valid(debug_cdb_valid),
               .debug_cdb_targ_addr(debug_cdb_targ_addr),
               .debug_cdb_mispred(debug_cdb_mispred),
               .debug_f2_d1_pc(debug_f2_d1_pc),
               .debug_f2_d1_instr(debug_f2_d1_instr),
               .debug_f2_d1_valid(debug_f2_d1_valid),
               .decoded_uop_valid(uop_valid),
               .fifo_full(dbg_stall),
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
