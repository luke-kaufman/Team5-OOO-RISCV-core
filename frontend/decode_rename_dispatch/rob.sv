`ifndef ROB_V
`define ROB_V

`include "misc/fifo_ram.v"
`include "misc/global_defs.svh"
`include "misc/mux/mux_.v"
`include "misc/and/and_.v"
`include "misc/inv.v"
`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module rob #(
    localparam ENTRY_WIDTH = $bits(rob_entry_t)
) (
    input wire clk,
    input wire rst_aL,

    // READY-THEN-VALID INTERFACE TO FETCH (ENQUEUE)
<<<<<<< HEAD
    // ififo triple handshake with ROB, IIQ, and LSQ
    input wire dispatch_valid, // demanding valid
    output wire dispatch_ready, // helping ready (ROB)
    output wire [`ROB_ID_WIDTH-1:0] dispatch_rob_id, // helping data (ROB)
    input var rob_dispatch_data_t dispatch_data,
=======
    output wire rob_dispatch_ready, // helping ready (ROB)
    input wire dispatch_valid, // demanding valid (ififo triple handshake with ROB, IIQ, and LSQ)
    input var rob_dispatch_data_t rob_dispatch_data,
>>>>>>> bdb773ec31f813181f1ac430eab207919b4f47d1

    // INTERFACE TO ARF (DEQUEUE)
    // ARF is always ready to accept data
    output wire retire,
    output wire [`ROB_ID_WIDTH-1:0] retire_rob_id,
    output wire [`ARF_ID_WIDTH-1:0] retire_arf_id,
    output wire [`REG_WIDTH-1:0] retire_reg_data,

    // src1 ready/data info (REGISTER READ)
    input wire [`ROB_ID_WIDTH-1:0] rob_id_src1,
    output wire rob_reg_ready_src1,
    output wire [`REG_WIDTH-1:0] rob_reg_data_src1,
    // src2 ready/data info (REGISTER READ)
    input wire [`ROB_ID_WIDTH-1:0] rob_id_src2,
    output wire rob_reg_ready_src2,
    output wire [`REG_WIDTH-1:0] rob_reg_data_src2,

    // INTERFACE TO ALU (WRITEBACK)
    input wire alu_wb_valid,
    input wire [`ROB_ID_WIDTH-1:0] alu_wb_rob_id,
    input wire [`REG_WIDTH-1:0] alu_wb_reg_data,
    input wire alu_wb_br_mispredict,

    // INTERFACE TO LSU (WRITEBACK)
    input wire lsu_wb_valid,
    input wire [`ROB_ID_WIDTH-1:0] lsu_wb_rob_id,
    input wire [`REG_WIDTH-1:0] lsu_wb_reg_data,
    input wire lsu_wb_ld_mispredict
);
    rob_entry_t [`ROB_N_ENTRIES-1:0] rob_state;
    rob_entry_t entry_rd_data_src1;
    rob_entry_t entry_rd_data_src2;
    rob_entry_t dispatch_entry_data;
    rob_entry_t retire_entry_data;

    assign dispatch_entry_data = '{
        dst_valid: dispatch_data.dst_valid,
        dst_arf_id: dispatch_data.dst_arf_id,
        pc: dispatch_data.pc,
        ld_mispredict: 1'b0,
        br_mispredict: 1'b0,
        reg_ready: 1'b0,
        reg_data: {`REG_WIDTH{1'b0}}
    };
    
    rob_entry_t [`ROB_N_ENTRIES-1:0] entry_wr_data_alu;
    rob_entry_t [`ROB_N_ENTRIES-1:0] entry_wr_data_lsu;
    rob_entry_t [`ROB_N_ENTRIES-1:0] entry_wr_data;

    for (genvar i = 0; i < `ROB_N_ENTRIES; i++) begin
<<<<<<< HEAD
        assign entry_wr_data_alu[i] = '{
            dst_valid: rob_state[i].dst_valid,
            dst_arf_id: rob_state[i].dst_arf_id,
            pc: rob_state[i].pc,
            ld_mispredict: rob_state[i].ld_mispredict,
            br_mispredict: alu_wb_br_mispredict,
            reg_ready: 1'b1,
            reg_data: alu_wb_reg_data
        };
        assign entry_wr_data_lsu[i] = '{
            dst_valid: rob_state[i].dst_valid,
            dst_arf_id: rob_state[i].dst_arf_id,
            pc: rob_state[i].pc,
            ld_mispredict: lsu_wb_ld_mispredict,
            br_mispredict: rob_state[i].br_mispredict,
            reg_ready: 1'b1,
            reg_data: lsu_wb_reg_data
=======
        var rob_entry_t entry_wr_data_alu = {
            rob_state[i].dst_valid,
            rob_state[i].dst_arf_id,
            rob_state[i].pc,
            rob_state[i].ld_mispredict,
            wb_br_mispredict,
            1'b1,
            wb_reg_data_alu
        };
        var rob_entry_t entry_wr_data_lsu = {
            rob_state[i].dst_valid,
            rob_state[i].dst_arf_id,
            rob_state[i].pc,
            wb_ld_mispredict,
            rob_state[i].br_mispredict,
            1'b1,
            wb_reg_data_lsu
>>>>>>> bdb773ec31f813181f1ac430eab207919b4f47d1
        };
        assign entry_wr_data[i] = {entry_wr_data_alu, entry_wr_data_lsu};
    end

    fifo_ram #(
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_ENTRIES(`ROB_N_ENTRIES),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(2)
    ) _rob (
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

        .wr_en({alu_wb_valid, lsu_wb_valid}),
        .wr_addr({alu_wb_rob_id, lsu_wb_rob_id}),
        .wr_data(entry_wr_data),

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
