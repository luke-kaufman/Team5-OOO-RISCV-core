`include "misc/global_defs.svh"
// `include "freepdk-45nm/stdcells.v"
`include "misc/regfile.v"
`include "frontend/dispatch/rob.sv"
`include "misc/mux/mux_.v"
`include "misc/onehot_mux/onehot_mux_.v"
`include "misc/or/or_.v"
`include "misc/reg_.v"

// FIXME: convert pc -> pc_npc, add npc_wb coming from alu
module dispatch ( // DECODE, RENAME, and REGISTER READ happen during this stage
    input wire clk,
    input wire rst_aL,
    // INTERFACE TO INSRUCTION FIFO (IFIFO)
    output wire ififo_dispatch_ready,
    input wire ififo_dispatch_valid,
    input wire ififo_entry_t ififo_dispatch_data,
    // INTERFACE TO INTEGER ISSUE QUEUE (IIQ)
    input wire iiq_dispatch_ready,
    output wire iiq_dispatch_valid,
    output wire iiq_entry_t iiq_dispatch_data,
    // integer wakeup (from IIQ)
    input wire iiq_wakeup_valid,
    input wire rob_id_t iiq_wakeup_rob_id,
    // INTERFACE TO LOAD-STORE QUEUE (LSQ)
    input wire lsq_dispatch_ready,
    output wire lsq_dispatch_valid,
    output wire lsq_entry_t lsq_dispatch_data,
    // INTERFACE TO ARITHMETIC-LOGIC UNIT (ALU)
    input wire alu_broadcast_valid,
    input wire rob_id_t alu_broadcast_rob_id,
    input wire reg_data_t alu_broadcast_reg_data,
    input wire alu_br_mispred,
    // INTERFACE TO LOAD-STORE UNIT (LSU)
    input wire ld_broadcast_valid,
    input wire rob_id_t ld_broadcast_rob_id,
    input wire reg_data_t ld_broadcast_reg_data,
    input wire ld_mispred
);
    // decode signals
    wire is_int_instr; // is integer instruction?
    wire is_ls_instr; // is load-store instruction?
    // NOTE: is_int_instr and is_ls_instr should be mutually exclusive
    wire rs1_valid;
    wire rs2_valid;
    wire rd_valid;
    wire arf_id_t rs1;
    wire arf_id_t rs2;
    wire arf_id_t rd;

    // TODO: implement
    // instr_decode instr_decode (
    //     .instr(instr),
    //     .is_int_instr(is_int_instr),
    //     .is_ls_instr(is_ls_instr),
    //     .rs1_valid(rs1_valid),
    //     .rs2_valid(rs2_valid),
    //     .rd_valid(rd_valid),
    //     .rs1(rs1),
    //     .rs2(rs2),
    //     .rd(rd)
    //     // .imm(imm),
    //     // .branch(branch),
    //     // .branch_target(branch_target),
    // );

    // triple dispatch handshake (IFIFO vs. ROB, IIQ, LSQ)
    wire iiq_dispatch_ok;
    wire lsq_dispatch_ok;
    or_ #(.N_INS(2)) iiq_dispatch_ok_or (
        .a({iiq_dispatch_ready, is_ls_instr}),
        .y(iiq_dispatch_ok)
    );
    or_ #(.N_INS(2)) lsq_dispatch_ok_or (
        .a({lsq_dispatch_ready, is_int_instr}),
        .y(lsq_dispatch_ok)
    );
    wire rob_dispatch_ready;
    wire dispatch;
    and_ #(.N_INS(4)) dispatch_and (
        .a({
            ififo_dispatch_valid,
            rob_dispatch_ready,
            iiq_dispatch_ok,
            lsq_dispatch_ok
        }),
        .y(dispatch)
    );

    // logic to decide if arf_id of the ROB head should be marked as retired (0) in the ARF/ROB table
    wire retire;
    wire rob_id_t retire_rob_id;
    wire retire_arf_id_not_renamed;
    wire rob_id_t retire_arf_id_curr_rob_id;
    unsigned_cmp_ #(.WIDTH(`ROB_ID_WIDTH)) retire_arf_id_not_renamed_cmp (
        .a(retire_rob_id),
        .b(retire_arf_id_curr_rob_id),
        .y(retire_arf_id_not_renamed)
    );
    wire retire_arf_id_mark_as_retired;
    and_ #(.N_INS(2)) retire_arf_id_mark_as_retired_and (
        .a({retire_arf_id_not_renamed, retire}),
        .y(retire_arf_id_mark_as_retired)
    );

    // logic to decide if rd should be marked as speculative (1) in the ARF/ROB table
    wire rename_rd;
    and_ #(.N_INS(2)) rename_rd_and (
        .a({rd_valid, dispatch}),
        .y(rename_rd)
    );

    // register alias table: ARF/ROB table
    // [0: ARF (retired), 1: ROB (speculative)]
    wire rs1_retired;
    wire rs2_retired;
    wire rob_id_t retire_arf_id;
    regfile #(
        .ENTRY_WIDTH(4),
        .N_ENTRIES(32),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(2)
    ) arf_rob_table (
        .clk(clk),
        .rst_aL(rst_aL),

        .rd_addr({rs1, rs2}),
        .rd_data({rs1_retired, rs2_retired}),

        // (synchronous) reset (1'b0) port to mark as retired (point to ARF)
        // (synchronous) set (1'b1) port to mark as speculative (point to ROB)
        .wr_en({retire_arf_id_mark_as_retired, rename_rd}),
        .wr_addr({retire_arf_id, rd}),
        .wr_data({1'b0, 1'b1})
    );

    // register alias table: tag table
    wire rob_id_t rob_id_src1;
    wire rob_id_t rob_id_src2;
    wire rob_id_t dispatch_rob_id;
    regfile #(
        .ENTRY_WIDTH(1),
        .N_ENTRIES(32),
        .N_READ_PORTS(3),
        .N_WRITE_PORTS(1)
    ) tag_table (
        .clk(clk),
        .rst_aL(rst_aL),

        .rd_addr({rs1, rs2, retire_arf_id}),
        .rd_data({rob_id_src1, rob_id_src2, retire_arf_id_curr_rob_id}),

        // write port to rename rd to a new speculative (ROB) tag
        .wr_en(rename_rd),
        .wr_addr(rd),
        .wr_data(dispatch_rob_id)
    );

    wire rob_dispatch_data_t rob_dispatch_data;
    assign rob_dispatch_data.dst_valid = rd_valid;
    assign rob_dispatch_data.dst_arf_id = rd;
    assign rob_dispatch_data.pc = ififo_dispatch_data.pc;
    wire reg_data_t retire_reg_data;
    wire rob_reg_ready_src1;
    wire reg_data_t rob_reg_data_src1;
    wire rob_reg_ready_src2;
    wire reg_data_t rob_reg_data_src2;
    rob _rob (
        .clk(clk),
        .rst_aL(rst_aL),

        .dispatch_ready(rob_dispatch_ready),
        .dispatch_valid(dispatch),
        .dispatch_rob_id(dispatch_rob_id),
        .dispatch_data(rob_dispatch_data),

        .retire(retire),
        .retire_rob_id(retire_rob_id),
        .retire_arf_id(retire_arf_id),
        .retire_reg_data(retire_reg_data),

        .rob_id_src1(rob_id_src1),
        .rob_reg_ready_src1(rob_reg_ready_src1),
        .rob_reg_data_src1(rob_reg_data_src1),

        .rob_id_src2(rob_id_src2),
        .rob_reg_ready_src2(rob_reg_ready_src2),
        .rob_reg_data_src2(rob_reg_data_src2),

        .iiq_wakeup_valid(iiq_wakeup_valid),
        .iiq_wakeup_rob_id(iiq_wakeup_rob_id),

        .alu_wb_valid(alu_broadcast_valid),
        .alu_wb_rob_id(alu_broadcast_rob_id),
        .alu_wb_reg_data(alu_broadcast_reg_data),
        .alu_br_mispred(alu_br_mispred),

        .ld_wb_valid(ld_broadcast_valid),
        .ld_wb_rob_id(ld_broadcast_rob_id),
        .ld_wb_reg_data(ld_broadcast_reg_data),
        .ld_mispred(ld_mispred)
    );

    wire reg_data_t arf_reg_data_src1;
    wire reg_data_t arf_reg_data_src2;
    regfile #(
        .ENTRY_WIDTH(32),
        .N_ENTRIES(32),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(1)
    ) arf (
        .clk(clk),
        .rst_aL(rst_aL),

        .rd_addr({rs1, rs2}),
        .rd_data({arf_reg_data_src1, arf_reg_data_src2}),

        .wr_en(retire),
        .wr_addr(retire_arf_id),
        .wr_data(retire_reg_data)
    );

    // INTERFACE TO FETCH
    assign ififo_dispatch_ready = dispatch;

    // INTERFACE TO INTEGER ISSUE QUEUE (IIQ)
    assign iiq_dispatch_valid = dispatch && is_int_instr; // FIXME: convert to structural

    // TODO: add lsu wakeup & data bypass (simultaneous wakeup and data bypass)
    // FIXME: convert to structural
    assign iiq_dispatch_data.src1_valid = rs1_valid;
    assign iiq_dispatch_data.src1_rob_id = rob_id_src1;
    // issue2dispatch wakeup bypass
    assign iiq_dispatch_data.src1_ready = (iiq_wakeup_valid && rs1_valid && (iiq_wakeup_rob_id == rob_id_src1)) ?
                                            1'b1 :
                                            rob_reg_ready_src1;
    // execute2dispatch data bypass
    assign iiq_dispatch_data.src1_data = (alu_broadcast_valid && rs1_valid && (alu_broadcast_rob_id == rob_id_src1)) ?
                                            alu_broadcast_reg_data :
                                            (rs1_retired ?
                                                arf_reg_data_src1 :
                                                rob_reg_data_src1);
    assign iiq_dispatch_data.src2_valid = rs2_valid;
    assign iiq_dispatch_data.src2_rob_id = rob_id_src2;
    // issue2dispatch wakeup bypass
    assign iiq_dispatch_data.src2_ready = (iiq_wakeup_valid && rs2_valid && (iiq_wakeup_rob_id == rob_id_src2)) ?
                                            1'b1 :
                                            rob_reg_ready_src2;
    // execute2dispatch data bypass
    assign iiq_dispatch_data.src2_data = (alu_broadcast_valid && rs2_valid && (alu_broadcast_rob_id == rob_id_src2)) ?
                                            alu_broadcast_reg_data :
                                            (rs2_retired ?
                                                arf_reg_data_src2 :
                                                rob_reg_data_src2);
    assign iiq_dispatch_data.dst_valid = rd_valid;
    assign iiq_dispatch_data.instr_rob_id = dispatch_rob_id;
    assign iiq_dispatch_data.alu_ctrl = 0; // FIXME
    assign iiq_dispatch_data.pc = ififo_dispatch_data.pc;
    assign iiq_dispatch_data.br_dir_pred = 0; // FIXME
    assign iiq_dispatch_data.br_target_pred = 0; // FIXME

    // INTERFACE TO LOAD-STORE QUEUE (LSQ)
    assign lsq_dispatch_valid = 0; // FIXME
    assign lsq_dispatch_data = 0; // FIXME
endmodule
