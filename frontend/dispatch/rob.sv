`ifndef ROB_V
`define ROB_V

`include "misc/global_defs.svh"
`include "freepdk-45nm/stdcells.v"
`include "misc/fifo_ram.v"
`include "misc/mux/mux_.v"
`include "misc/and/and_.v"
`include "misc/inv.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module rob (
    input wire clk,
    input wire rst_aL,

    // READY-THEN-VALID INTERFACE TO FETCH (ENQUEUE)
    // ififo triple handshake with ROB, IIQ, and LSQ
    input wire dispatch_valid, // demanding valid
    output wire dispatch_ready, // helping ready (ROB)
    output wire rob_id_t dispatch_rob_id, // helping data (ROB)
    input wire rob_dispatch_data_t dispatch_data,

    // INTERFACE TO ARF (DEQUEUE)
    // ARF is always ready to accept data
    output wire retire,
    output wire rob_id_t retire_rob_id,
    output wire arf_id_t retire_arf_id,
    output wire reg_data_t retire_reg_data,

    // src1 (ready, data) info (REGISTER READ)
    input wire rob_id_t rob_id_src1,
    output wire rob_reg_ready_src1,
    output wire reg_data_t rob_reg_data_src1,
    // src2 (ready, data) info (REGISTER READ)
    input wire rob_id_t rob_id_src2,
    output wire rob_reg_ready_src2,
    output wire reg_data_t rob_reg_data_src2,

    // INTERFACE TO IIQ (INTEGER WAKEUP)
    input wire int_wakeup_valid,
    input wire rob_id_t int_wakeup_rob_id,

    // INTERFACE TO ALU (INTEGER WRITEBACK)
    input wire alu_wb_valid,
    input wire rob_id_t alu_wb_rob_id,
    input wire reg_data_t alu_wb_reg_data,
    input wire alu_wb_br_mispred,

    // INTERFACE TO LSU (LOAD-STORE WRITEBACK + WAKEUP)
    input wire lsu_wb_valid,
    input wire rob_id_t lsu_wb_rob_id,
    input wire reg_data_t lsu_wb_reg_data,
    input wire lsu_wb_ld_mispred
);
    wire rob_entry_t [`ROB_N_ENTRIES-1:0] rob_state;
    wire rob_entry_t entry_rd_data_src1;
    wire rob_entry_t entry_rd_data_src2;
    wire rob_entry_t dispatch_entry_data;
    wire rob_entry_t retire_entry_data;

    assign dispatch_entry_data.dst_valid = dispatch_data.dst_valid;
    assign dispatch_entry_data.dst_arf_id = dispatch_data.dst_arf_id;
    assign dispatch_entry_data.pc = dispatch_data.pc;
    assign dispatch_entry_data.ld_mispredict = 1'b0;
    assign dispatch_entry_data.br_mispredict = 1'b0;
    assign dispatch_entry_data.reg_ready = 1'b0;
    assign dispatch_entry_data.reg_data = {`REG_DATA_WIDTH{1'b0}};

    wire rob_entry_t [`ROB_N_ENTRIES-1:0] entry_wr_data_int_wakeup;
    wire rob_entry_t [`ROB_N_ENTRIES-1:0] entry_wr_data_alu_wb;
    wire rob_entry_t [`ROB_N_ENTRIES-1:0] entry_wr_data_lsu_wb;
    wire rob_entry_t [`ROB_N_ENTRIES-1:0] [2:0] entry_wr_data;

    for (genvar i = 0; i < `ROB_N_ENTRIES; i++) begin
        assign entry_wr_data_int_wakeup[i].dst_valid = rob_state[i].dst_valid;
        assign entry_wr_data_int_wakeup[i].dst_arf_id = rob_state[i].dst_arf_id;
        assign entry_wr_data_int_wakeup[i].pc = rob_state[i].pc;
        assign entry_wr_data_int_wakeup[i].ld_mispredict = rob_state[i].ld_mispredict;
        assign entry_wr_data_int_wakeup[i].br_mispredict = rob_state[i].br_mispredict;
        assign entry_wr_data_int_wakeup[i].reg_ready = 1'b1;
        assign entry_wr_data_int_wakeup[i].reg_data = rob_state[i].reg_data;

        assign entry_wr_data_alu_wb[i].dst_valid = rob_state[i].dst_valid;
        assign entry_wr_data_alu_wb[i].dst_arf_id = rob_state[i].dst_arf_id;
        assign entry_wr_data_alu_wb[i].pc = rob_state[i].pc;
        assign entry_wr_data_alu_wb[i].ld_mispredict = rob_state[i].ld_mispredict;
        assign entry_wr_data_alu_wb[i].br_mispredict = alu_wb_br_mispred;
        assign entry_wr_data_alu_wb[i].reg_ready = rob_state[i].reg_ready; // NOTE: should already be 1'b1
        assign entry_wr_data_alu_wb[i].reg_data = alu_wb_reg_data;

        assign entry_wr_data_lsu_wb[i].dst_valid = rob_state[i].dst_valid;
        assign entry_wr_data_lsu_wb[i].dst_arf_id = rob_state[i].dst_arf_id;
        assign entry_wr_data_lsu_wb[i].pc = rob_state[i].pc;
        assign entry_wr_data_lsu_wb[i].ld_mispredict = lsu_wb_ld_mispred;
        assign entry_wr_data_lsu_wb[i].br_mispredict = rob_state[i].br_mispredict;
        assign entry_wr_data_lsu_wb[i].reg_ready = 1'b1; // TODO: verify that ld wb and wakeup always happen in the same cycle
        assign entry_wr_data_lsu_wb[i].reg_data = lsu_wb_reg_data;

        assign entry_wr_data[i][0] = entry_wr_data_int_wakeup[i];
        assign entry_wr_data[i][1] = entry_wr_data_alu_wb[i];
        assign entry_wr_data[i][2] = entry_wr_data_lsu_wb[i];
    end

    fifo_ram #(
        .ENTRY_WIDTH(`ROB_ENTRY_WIDTH),
        .N_ENTRIES(`ROB_N_ENTRIES),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(3)
    ) rob_mem (
        .clk(clk),
        .rst_aL(rst_aL),
        
        .enq_ready(dispatch_ready),
        .enq_valid(dispatch_valid),
        .enq_data(dispatch_entry_data),
        .enq_addr(dispatch_rob_id),

        .deq_ready(1'b1), // ARF is always ready to accept data
        .deq_valid(retire),
        .deq_data(retire_entry_data),
        .deq_addr(retire_rob_id),

        .rd_addr({rob_id_src1, rob_id_src2}),
        .rd_data({entry_rd_data_src1, entry_rd_data_src2}),

        .wr_en({alu_wb_valid, lsu_wb_valid, int_wakeup_valid}),
        .wr_addr({alu_wb_rob_id, lsu_wb_rob_id, int_wakeup_rob_id}),
        .wr_data(d),

        .entry_douts(rob_state)
    );

    // NOTE: currently ignoring load mispredicts while reading reg data
    assign rob_reg_ready_src1 = entry_rd_data_src1.reg_ready;
    assign rob_reg_data_src1 = entry_rd_data_src1.reg_data;
    assign rob_reg_ready_src2 = entry_rd_data_src2.reg_ready;
    assign rob_reg_data_src2 = entry_rd_data_src2.reg_data;

    wire not_br_mispredict;
    wire not_ld_mispredict;
    inv br_mispredict_inv (
        .a(retire_entry_data.br_mispredict),
        .y(not_br_mispredict)
    );
    inv ld_mispredict_inv (
        .a(retire_entry_data.ld_mispredict),
        .y(not_ld_mispredict)
    );
    and_ #(.N_INS(4)) retire_and (
        .a({
            retire_entry_data.dst_valid,
            retire_entry_data.reg_ready,
            not_br_mispredict,
            not_ld_mispredict
        }),
        .y(retire)
    );
    assign retire_arf_id = retire_entry_data.dst_arf_id;
    assign retire_reg_data = retire_entry_data.reg_data;
endmodule

`endif
