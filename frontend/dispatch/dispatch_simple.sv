`ifndef DISPATCH_V
`define DISPATCH_V

`include "misc/global_defs.svh"
// `include "freepdk-45nm/stdcells.v"
`include "misc/regfile.sv"
`include "golden/misc/regfile_golden.sv"
`include "frontend/dispatch/rob_simple.sv"
`include "frontend/dispatch/decode.sv"
`include "misc/mux/mux_.v"
`include "misc/onehot_mux/onehot_mux.v"
`include "misc/or/or_.v"
`include "misc/nor/nor_.v"
`include "misc/and/and_.v"
`include "misc/reg_.v"

// FIXME: convert pc -> pc_npc, add npc_wb coming from alu
module dispatch_simple ( // DECODE, RENAME, and REGISTER READ happen during this stage
    input wire clk,
    input wire init,
    input wire [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] init_arf_state,
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
    output lsq_simple_entry_t lsq_dispatch_data, // TODO: figure out the enum? 2-state vs. 4-state problem
    // INTERFACE TO ARITHMETIC-LOGIC UNIT (ALU)
    input wire execute_valid,
    input wire alu_broadcast_valid,
    input wire rob_id_t alu_broadcast_rob_id,
    input wire reg_data_t alu_broadcast_reg_data,
    input wire alu_npc_wb_valid, // only true when instr is b_type or jalr
    input wire alu_npc_mispred, // always true for jalr, only true for b_type when actual mispredict
    input wire addr_t alu_npc,
    // INTERFACE TO LOAD-STORE UNIT (LSU)
    input wire lsu_rob_wb_valid,
    input wire ld_broadcast_valid,
    input wire rob_id_t ld_broadcast_rob_id,
    input wire reg_data_t ld_broadcast_reg_data,
    // input wire ld_mispred,
    // INTERFACE TO FETCH
    output wire fetch_redirect_valid,
    output wire addr_t fetch_redirect_pc,

    output logic [`ARF_N_ENTRIES-1:0][`REG_DATA_WIDTH-1:0] ARF_OUT
);
    // ififo_dispatch_data fields
    wire instr_t instr         = ififo_dispatch_data.instr;
    wire addr_t pc             = ififo_dispatch_data.pc;
    wire is_cond_br            = ififo_dispatch_data.is_cond_br;
    wire br_dir_pred           = ififo_dispatch_data.br_dir_pred;
    wire addr_t br_target_pred = ififo_dispatch_data.br_target_pred;

    // decode signals
    wire rs1_valid;
    wire rs2_valid;
    wire rd_valid;
    wire arf_id_t rs1;
    wire arf_id_t rs2;
    wire arf_id_t rd;
    wire funct3_t funct3; // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    wire imm_t imm;
    wire is_r_type;
    wire is_i_type;
    wire is_s_type;
    wire is_b_type;
    wire is_u_type; // lui and auipc only
    wire is_j_type; // jal only
    wire is_sub; // if is_r_type, 0 = add, 1 = sub
    wire is_sra_srai; // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    wire is_lui; // if is_u_type, 0 = auipc, 1 = lui
    wire is_jalr; // if is_i_type, 0 = else, 1 = jalr
    wire is_int_instr; // is integer instruction?
    wire is_ls_instr; // is load-store instruction?
    req_width_t ls_width;
    wire ld_sign;
    // NOTE: is_int_instr and is_ls_instr should be mutually exclusive

    decode _decode (
        .clk(clk),
        .instr(instr),
        .rs1_valid(rs1_valid), // valid stands for "exists"
        .rs2_valid(rs2_valid),
        .rd_valid(rd_valid),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3), // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
        .imm(imm),
        .is_r_type(is_r_type),
        .is_i_type(is_i_type),
        .is_s_type(is_s_type),
        .is_b_type(is_b_type),
        .is_u_type(is_u_type), // lui and auipc only
        .is_j_type(is_j_type), // jal only
        .is_sub(is_sub), // if is_r_type, 0 = add, 1 = sub
        .is_sra_srai(is_sra_srai), // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
        .is_lui(is_lui), // if is_u_type, 0 = auipc, 1 = lui
        .is_jalr(is_jalr), // if is_i_type, 0 = else, 1 = jalr
        .is_int_instr(is_int_instr),
        .is_ls_instr(is_ls_instr),
        .ls_width(ls_width),
        .ld_sign(ld_sign)
    );

    // quadruple dispatch handshake (IFIFO vs. ROB, IIQ, LSQ, ST_BUF)
    wire iiq_dispatch_ok;
    wire lsq_dispatch_ok;
    wire st_buf_dispatch_ok;
    or_ #(.N_INS(2)) iiq_dispatch_ok_or (
        .a({iiq_dispatch_ready, is_ls_instr}),
        .y(iiq_dispatch_ok)
    );
    or_ #(.N_INS(2)) lsq_dispatch_ok_or (
        .a({lsq_dispatch_ready, is_int_instr}),
        .y(lsq_dispatch_ok)
    );
    // NOTE: switch between lsu and lsu_simple by comenting/uncommenting the relevant line
    // assign st_buf_dispatch_ok = ~is_s_type | st_buf_dispatch_ready;
    assign st_buf_dispatch_ok = 1'b1;
    wire rob_dispatch_ready;
    wire dispatch;
    and_ #(.N_INS(5)) dispatch_and (
        .a({
            ififo_dispatch_valid,
            rob_dispatch_ready,
            iiq_dispatch_ok,
            lsq_dispatch_ok,
            st_buf_dispatch_ok
        }),
        .y(dispatch)
    );

    // logic to decide if arf_id of the ROB head should be marked as retired (0) in the ARF/ROB table
    wire retire;
    wire rob_id_t retire_rob_id;
    wire retire_arf_id_not_renamed;
    wire rob_id_t retire_arf_id_curr_rob_id;
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) retire_arf_id_not_renamed_cmp (
        .a(retire_rob_id),
        .b(retire_arf_id_curr_rob_id),
        .eq(retire_arf_id_not_renamed),
        .lt(),
        .ge()
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
    wire rs1_arf_rob;
    wire rs2_arf_rob;
    wire rs1_retired = ~rs1_arf_rob;
    wire rs2_retired = ~rs2_arf_rob;
    wire arf_id_t retire_arf_id;
    regfile_golden #(
        .ENTRY_WIDTH(1),
        .N_ENTRIES(32),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(2)
    ) arf_rob_table (
        .clk(clk),
        .init(init),
        .rst_aL(rst_aL),

        .rd_addr({rs1, rs2}),
        .rd_data({rs1_arf_rob, rs2_arf_rob}),

        // (synchronous) reset (1'b0) port to mark as retired (point to ARF)
        // (synchronous) set (1'b1) port to mark as speculative (point to ROB)
        .wr_en({retire_arf_id_mark_as_retired, rename_rd}),
        .wr_addr({retire_arf_id, rd}),
        .wr_data({1'b0, 1'b1}),

        // FLUSH ON REDIRECT
        .flush(fetch_redirect_valid),

        .init_regfile_state('0),
        .current_regfile_state()
    );

    // register alias table: tag table
    wire rob_id_t rob_id_src1;
    wire rob_id_t rob_id_src2;
    wire rob_id_t dispatch_rob_id;
    regfile_golden #(
        .ENTRY_WIDTH(4),
        .N_ENTRIES(32),
        .N_READ_PORTS(3),
        .N_WRITE_PORTS(1)
    ) tag_table (
        .clk(clk),
        .init(init),
        .rst_aL(rst_aL),

        .rd_addr({rs1, rs2, retire_arf_id}),
        .rd_data({rob_id_src1, rob_id_src2, retire_arf_id_curr_rob_id}),

        // write port to rename rd to a new speculative (ROB) tag
        .wr_en(rename_rd),
        .wr_addr(rd),
        .wr_data(dispatch_rob_id),

        // flush on redirect
        .flush(fetch_redirect_valid),

        .init_regfile_state('0),
        .current_regfile_state()
    );

    wire rob_dispatch_data_t rob_dispatch_data = '{
        dst_valid: rd_valid,
        dst_arf_id: rd,
        pc: pc
    };
    wire reg_data_t retire_reg_data;
    wire rob_reg_ready_src1;
    wire reg_data_t rob_reg_data_src1;
    wire rob_reg_ready_src2;
    wire reg_data_t rob_reg_data_src2;
    rob_simple _rob (
        .clk(clk),
        .init(init),
        .rst_aL(rst_aL),
        .fetch_redirect_valid(),
        .fetch_redirect_pc(fetch_redirect_pc),

        .dispatch_ready(rob_dispatch_ready),
        .dispatch_valid(dispatch),
        .dispatch_rob_id(dispatch_rob_id),
        .dispatch_data(rob_dispatch_data),

        .retire(retire),
        .retire_rob_id(retire_rob_id),
        .retire_arf_id(retire_arf_id),
        .retire_reg_data(retire_reg_data),
        .retire_redirect_pc_valid(fetch_redirect_valid),
        .retire_redirect_pc(fetch_redirect_pc),

        .rob_id_src1(rob_id_src1),
        .rob_reg_ready_src1(rob_reg_ready_src1),
        .rob_reg_data_src1(rob_reg_data_src1),

        .rob_id_src2(rob_id_src2),
        .rob_reg_ready_src2(rob_reg_ready_src2),
        .rob_reg_data_src2(rob_reg_data_src2),

        .iiq_wakeup_valid(iiq_wakeup_valid),
        .iiq_wakeup_rob_id(iiq_wakeup_rob_id),

        .alu_wb_valid(execute_valid),
        .alu_wb_rob_id(alu_broadcast_rob_id),
        .alu_wb_reg_data(alu_broadcast_reg_data),
        .alu_npc_wb_valid(alu_npc_wb_valid),
        .alu_npc_mispred(alu_npc_mispred),
        .alu_npc(alu_npc),

        .ld_wb_valid(lsu_rob_wb_valid), // TODO: double-check if separating lsu_rob_wb_valid and ld_broadcast_valid is necessary
        .ld_wb_rob_id(ld_broadcast_rob_id),
        .ld_wb_reg_data(ld_broadcast_reg_data)
        // , .ld_wb_ld_mispred(ld_mispred)
    );

    wire reg_data_t arf_reg_data_src1;
    wire reg_data_t arf_reg_data_src2;
    regfile_golden #(
        .ENTRY_WIDTH(32),
        .N_ENTRIES(32),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(1)
    ) arf (
        .clk(clk),
        .init(init),
        .rst_aL(rst_aL),

        .rd_addr({rs1, rs2}),
        .rd_data({arf_reg_data_src1, arf_reg_data_src2}),

        .wr_en(retire),
        .wr_addr(retire_arf_id),
        .wr_data(retire_reg_data),

        // NOT FLUSHED ON REDIRECT
        .flush(1'b0),

        .init_regfile_state(init_arf_state),
        .current_regfile_state(ARF_OUT)
    );

    // INTERFACE TO FETCH
    assign ififo_dispatch_ready = dispatch;

    wire src1_iiq_wakeup_match;
    wire src1_alu_broadcast_match;
    wire src1_ld_broadcast_match;
    wire src2_iiq_wakeup_match;
    wire src2_alu_broadcast_match;
    wire src2_ld_broadcast_match;
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) src1_iiq_wakeup_cmp (
        .a(rob_id_src1),
        .b(iiq_wakeup_rob_id),
        .eq(src1_iiq_wakeup_match),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) src1_alu_broadcast_cmp (
        .a(rob_id_src1),
        .b(alu_broadcast_rob_id),
        .eq(src1_alu_broadcast_match),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) src1_ld_broadcast_cmp (
        .a(rob_id_src1),
        .b(ld_broadcast_rob_id),
        .eq(src1_ld_broadcast_match),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) src2_iiq_wakeup_cmp (
        .a(rob_id_src2),
        .b(iiq_wakeup_rob_id),
        .eq(src2_iiq_wakeup_match),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) src2_alu_broadcast_cmp (
        .a(rob_id_src2),
        .b(alu_broadcast_rob_id),
        .eq(src2_alu_broadcast_match),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`ROB_ID_WIDTH)) src2_ld_broadcast_cmp (
        .a(rob_id_src2),
        .b(ld_broadcast_rob_id),
        .eq(src2_ld_broadcast_match),
        .lt(),
        .ge()
    );
    wire src1_iiq_wakeup_capture;
    wire src1_alu_broadcast_capture;
    wire src1_ld_broadcast_capture;
    wire src2_iiq_wakeup_capture;
    wire src2_alu_broadcast_capture;
    wire src2_ld_broadcast_capture;
    and_ #(.N_INS(3)) src1_iiq_wakeup_capture_and (
        .a({iiq_wakeup_valid, rs1_valid, src1_iiq_wakeup_match}),
        .y(src1_iiq_wakeup_capture)
    );
    and_ #(.N_INS(3)) src1_alu_broadcast_capture_and (
        .a({alu_broadcast_valid, rs1_valid, src1_alu_broadcast_match}),
        .y(src1_alu_broadcast_capture)
    );
    and_ #(.N_INS(3)) src1_ld_broadcast_capture_and (
        .a({ld_broadcast_valid, rs1_valid, src1_ld_broadcast_match}),
        .y(src1_ld_broadcast_capture)
    );
    and_ #(.N_INS(3)) src2_iiq_wakeup_capture_and (
        .a({iiq_wakeup_valid, rs2_valid, src2_iiq_wakeup_match}),
        .y(src2_iiq_wakeup_capture)
    );
    and_ #(.N_INS(3)) src2_alu_broadcast_capture_and (
        .a({alu_broadcast_valid, rs2_valid, src2_alu_broadcast_match}),
        .y(src2_alu_broadcast_capture)
    );
    and_ #(.N_INS(3)) src2_ld_broadcast_capture_and (
        .a({ld_broadcast_valid, rs2_valid, src2_ld_broadcast_match}),
        .y(src2_ld_broadcast_capture)
    );

    wire src1_ready;
    wire src2_ready;
    or_ #(.N_INS(4)) src1_ready_or (
        .a({src1_iiq_wakeup_capture, src1_ld_broadcast_capture, rs1_retired, rob_reg_ready_src1}),
        .y(src1_ready)
    );
    or_ #(.N_INS(4)) src2_ready_or (
        .a({src2_iiq_wakeup_capture, src2_ld_broadcast_capture, rs2_retired, rob_reg_ready_src2}),
        .y(src2_ready)
    );

    wire sel_rob_reg_data_src1;
    wire sel_rob_reg_data_src2;
    nor_ #(.N_INS(3)) sel_rob_reg_data_src1_nor (
        .a({src1_alu_broadcast_capture, src1_ld_broadcast_capture, rs1_retired}),
        .y(sel_rob_reg_data_src1)
    );
    nor_ #(.N_INS(3)) sel_rob_reg_data_src2_nor (
        .a({src2_alu_broadcast_capture, src2_ld_broadcast_capture, rs2_retired}),
        .y(sel_rob_reg_data_src2)
    );

    wire reg_data_t src1_data;
    wire reg_data_t src2_data;
    onehot_mux #(
        .WIDTH(`REG_DATA_WIDTH),
        .N_INS(4)
    ) src1_data_mux (
        .clk(clk),
        .sel({src1_alu_broadcast_capture, src1_ld_broadcast_capture, rs1_retired, sel_rob_reg_data_src1}),
        .ins({alu_broadcast_reg_data, ld_broadcast_reg_data, arf_reg_data_src1, rob_reg_data_src1}),
        .out(src1_data)
    );
    onehot_mux #(
        .WIDTH(`REG_DATA_WIDTH),
        .N_INS(4)
    ) src2_data_mux (
        .clk(clk),
        .sel({src2_alu_broadcast_capture, src2_ld_broadcast_capture, rs2_retired, sel_rob_reg_data_src2}),
        .ins({alu_broadcast_reg_data, ld_broadcast_reg_data, arf_reg_data_src2, rob_reg_data_src2}),
        .out(src2_data)
    );

    // INTERFACE TO INTEGER ISSUE QUEUE (IIQ)
    and_ #(.N_INS(2)) iiq_dispatch_valid_and (
        .a({dispatch, is_int_instr}),
        .y(iiq_dispatch_valid)
    );
    assign iiq_dispatch_data = '{
        src1_valid: rs1_valid,
        src1_rob_id: rob_id_src1,
        // issue2dispatch wakeup bypass
        src1_ready: src1_ready,
        // execute2dispatch data bypass
        src1_data: src1_data,
        src2_valid: rs2_valid,
        src2_rob_id: rob_id_src2,
        // issue2dispatch wakeup bypass
        src2_ready: src2_ready,
        // execute2dispatch data bypass
        src2_data: src2_data,
        dst_valid: rd_valid,
        instr_rob_id: dispatch_rob_id,
        imm: imm,
        pc: pc,
        funct3: funct3, // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
        is_r_type: is_r_type,
        is_i_type: is_i_type,
        is_u_type: is_u_type, // lui and auipc only
        is_b_type: is_b_type,
        is_j_type: is_j_type, // jal only
        is_sub: is_sub, // if is_r_type, 0 = add, 1 = sub
        is_sra_srai: is_sra_srai, // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
        is_lui: is_lui, // if is_u_type, 0 = auipc, 1 = lui
        is_jalr: is_jalr, // if is_i_type, 0 = else, 1 = jalr
        br_dir_pred: br_dir_pred, // (0: not taken, 1: taken)
        br_target_pred: br_target_pred
    };

    // INTERFACE TO LOAD-STORE QUEUE (LSQ)
    and_ #(.N_INS(2)) lsq_dispatch_valid_and (
        .a({dispatch, is_ls_instr}),
        .y(lsq_dispatch_valid)
    );
    assign lsq_dispatch_data = '{
        ld_st:            is_s_type, // 0: ld, 1: st
        base_addr_rob_id: rob_id_src1,
        base_addr_ready:  src1_ready,
        base_addr:        src1_data,
        imm: imm,
        st_data_rob_id:   rob_id_src2,
        st_data_ready:    src2_ready,
        st_data:          src2_data,
        instr_rob_id:     dispatch_rob_id,
        width:            ls_width,              // 00: byte (8 bits), 01: half-word (16 bits), 10: word (32 bits)
        ld_sign:          ld_sign             // 0: signed (LB, LH, LW), 1: unsigned (LBU, LHU)
        // , st_buf_id: 0 // only st_buf is allocated during dispatch, not ld_buf
    };
endmodule

`endif
