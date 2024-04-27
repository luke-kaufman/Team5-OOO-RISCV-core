`include "misc/global_defs.svh"
`include "top/top.sv"

module top_tb #(
    parameter int unsigned VERBOSE = 0,
    parameter int unsigned CLOCK_PERIOD = 10,
    localparam int unsigned HALF_PERIOD = CLOCK_PERIOD / 2,
    parameter addr_t HIGHEST_PC = 32'h80000,
    localparam main_mem_block_addr_t HIGHEST_INSTR_BLOCK_ADDR = HIGHEST_PC >> `MAIN_MEM_BLOCK_OFFSET_WIDTH
);
    bit clk = 1;
    bit init = 0;
    initial forever #HALF_PERIOD clk = ~clk;

    addr_t init_pc = 32'h1018c;
    addr_t init_sp = init_pc - 4;
    logic [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] init_arf_state = {
        32'h00000000 /* x31 (t6)    */,
        32'h00000000 /* x30 (t5)    */,
        32'h00000000 /* x29 (t4)    */,
        32'h00000000 /* x28 (t3)    */,
        32'h00000000 /* x27 (s11)   */,
        32'h00000000 /* x26 (s10)   */,
        32'h00000000 /* x25 (s9)    */,
        32'h00000000 /* x24 (s8)    */,
        32'h00000000 /* x23 (s7)    */,
        32'h00000000 /* x22 (s6)    */,
        32'h00000000 /* x21 (s5)    */,
        32'h00000000 /* x20 (s4)    */,
        32'h00000000 /* x19 (s3)    */,
        32'h00000000 /* x18 (s2)    */,
        32'h00000000 /* x17 (a7)    */,
        32'h00000000 /* x16 (a6)    */,
        32'h00000000 /* x15 (a5)    */,
        32'h00000000 /* x14 (a4)    */,
        32'h00000000 /* x13 (a3)    */,
        32'h00000000 /* x12 (a2)    */,
        32'h00000000 /* x11 (a1)    */,
        32'h00000000 /* x10 (a0)    */,
        32'hDEADBEEF /* x9  (s1)    */,
        32'hDEADBABE /* x8  (s0/fp) */,
        32'h00000000 /* x7  (t2)    */,
        32'h00000000 /* x6  (t1)    */,
        32'h00000000 /* x5  (t0)    */,
        32'h00000000 /* x4  (tp)    */,
        32'h00000000 /* x3  (gp)    */,
        init_sp      /* x2  (sp)    */,
        32'h00000000 /* x1  (ra)    */,
        32'h00000000 /* x0  (zero)  */
    };
    instr_t instrs[] = {
        32'hfe010113, // add sp,sp,-32
        32'h00812e23, // sw s0,28(sp)
        32'h00912c23, // sw s1,24(sp)
        32'h02010413, // add s0,sp,32
        32'h00f00493, // li s1,15
        32'h01c12403, // lw s0,28(sp)
        32'h01812483  // lw s1,24(sp)
    };
    block_data_t init_main_mem_state [HIGHEST_INSTR_BLOCK_ADDR:0];

    wire [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] arf_out_data;
    wire block_data_t main_mem_out_data[HIGHEST_INSTR_BLOCK_ADDR:0];

    addr_t pc = init_pc;
    wire main_mem_block_addr_t   pc_block_addr;
    wire main_mem_block_offset_t pc_block_offset;
    assign {pc_block_addr, pc_block_offset} = pc;
    initial begin
        foreach (instrs[i]) begin
            init_main_mem_state[pc_block_addr][8*pc_block_offset+:32] = instrs[i];
            pc = pc + 4;
        end
    end

    top #(
        .VERBOSE(VERBOSE),
        .HIGHEST_PC(HIGHEST_PC)
    ) _top (
        .clk(clk),
        .init(init),
        .init_pc(init_pc),
        .init_main_mem_state(init_main_mem_state),
        .init_arf_state(init_arf_state),
        .rst_aL(),
        .ARF_OUT(arf_out_data),
        .MAIN_MEM_OUT(main_mem_out_data)
    );

    task dump_arf();
        $display("ARF OUT AT TIME %5d===================", $time);
        for(int i = 0; i < `ARF_N_ENTRIES; i++) begin
            $display("ARF[%0d]: 0x%8h", i, arf_out_data[i]);
        end
        $display("END ARF OUT =======================================");
    endtask

    task dump_main_mem(addr_t start_addr, addr_t end_addr);
        addr_t addr;
        main_mem_block_addr_t block_addr;
        main_mem_block_offset_t block_offset;
        assign {block_addr, block_offset} = addr;
        $display("MAIN MEM OUT AT TIME %5d===================", $time);
        for (addr = start_addr; addr < end_addr; addr += 4) begin
            $display("MAIN_MEM[0x%8h]: 0x%8h", addr, main_mem_out_data[block_addr][8*block_offset+:32]);
        end
        $display("END MAIN MEM OUT =======================================");
    endtask

    initial begin
        #1;
        init = 1;
        #1;
        init = 0;

        repeat (30)
            @(posedge clk);

        #1;
        dump_arf();
        dump_main_mem(init_pc - 32, init_pc + 32);
        $finish;
    end

    always @(negedge clk) begin #1 $display();
        for (int i = 0; i < 8; i++) begin
            $display("%0t rob_state[%0d].pc_npc: %h", $time, i, _top._core._dispatch._rob.rob_state[i].pc_npc);
            $display("%0t rob_state[%0d].is_executed: %b", $time, i, _top._core._dispatch._rob.rob_state[i].is_executed);
            $display("%0t rob_state[%0d].reg_ready: %b", $time, i, _top._core._dispatch._rob.rob_state[i].reg_ready);
        end
        for (int i = 0; i < 4; i++) begin
            $display("%0t iiq_state[%0d].src1_valid: %h", $time, i, _top._core._integer_issue.entries[i].src1_valid);
            $display("%0t iiq_state[%0d].src2_valid: %h", $time, i, _top._core._integer_issue.entries[i].src2_valid);
            $display("%0t iiq_state[%0d].src1_rob_id: %d", $time, i, _top._core._integer_issue.entries[i].src1_rob_id);
            $display("%0t iiq_state[%0d].src2_rob_id: %d", $time, i, _top._core._integer_issue.entries[i].src2_rob_id);
            $display("%0t iiq_state[%0d].src1_ready: %b", $time, i, _top._core._integer_issue.entries[i].src1_ready);
            $display("%0t iiq_state[%0d].src2_ready: %b", $time, i, _top._core._integer_issue.entries[i].src2_ready);
            $display("%0t iiq_state[%0d].src1_data: %h", $time, i, _top._core._integer_issue.entries[i].src1_data);
            $display("%0t iiq_state[%0d].src2_data: %h", $time, i, _top._core._integer_issue.entries[i].src2_data);
            $display("%0t iiq_state[%0d].dst_valid: %b", $time, i, _top._core._integer_issue.entries[i].dst_valid);
            $display("%0t iiq_state[%0d].instr_rob_id: %d", $time, i, _top._core._integer_issue.entries[i].instr_rob_id);
        end
        for (int i = 0; i < 4; i++) begin
            $display("%0t lsq_state[%0d].ld_st: %b", $time, i, _top._core.lsu.lsq_entries[i].ld_st);
            $display("%0t lsq_state[%0d].base_addr_rob_id: %d", $time, i, _top._core.lsu.lsq_entries[i].base_addr_rob_id);
            $display("%0t lsq_state[%0d].base_addr_ready: %b", $time, i, _top._core.lsu.lsq_entries[i].base_addr_ready);
            $display("%0t lsq_state[%0d].base_addr: %h", $time, i, _top._core.lsu.lsq_entries[i].base_addr);
            $display("%0t lsq_state[%0d].st_data_rob_id: %d", $time, i, _top._core.lsu.lsq_entries[i].st_data_rob_id);
            $display("%0t lsq_state[%0d].st_data_ready: %b", $time, i, _top._core.lsu.lsq_entries[i].st_data_ready);
            $display("%0t lsq_state[%0d].st_data: %h", $time, i, _top._core.lsu.lsq_entries[i].st_data);
            $display("%0t lsq_state[%0d].instr_rob_id: %d", $time, i, _top._core.lsu.lsq_entries[i].instr_rob_id);
        end
    end
endmodule