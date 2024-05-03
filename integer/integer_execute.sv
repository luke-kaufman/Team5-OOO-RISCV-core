`ifndef ALU_V
`define ALU_V

`include "misc/global_defs.svh"
`include "misc/onehot_mux/onehot_mux.v"
`include "misc/cmp/unsigned_cmp.v"
`include "misc/cmp/signed_cmp.v"
`include "misc/and/bitwise_and.v"
`include "misc/or/bitwise_or.v"
`include "misc/xor/bitwise_xor.v"
`include "misc/adder.v"
`include "misc/mux/mux_.v"
`include "misc/inv/inv.v"
`include "misc/nor/nor_.v"
`include "misc/inv/bitwise_inv.v"

// R-type: adder_op1 = src1, adder_op2 = src2/minus_src2, dst = src1 op src2, no npc
// I-type: adder_op1 = src1, adder_op2 = imm,
    // (jalr) dst = pc_plus_4, npc = {(src1 + imm)[31:1], 1'b0}
    // (else) dst = src1 op imm
// B-type: adder_op1 = pc, adder_op2 = imm, npc ?= pc + imm
// U-type: adder_op1 = pc, adder_op2 = imm (lui, auipc)
// J-type (jal): adder_op1 = pc, adder_op2 = imm, dst = pc_plus_4, npc = pc + imm

// main_adder_op1 + main_adder_op2 = src1 + src2 (add: R)                     |
//                                   src1 + minus_src2 (sub: R)               |
//                                   src1 + imm (addi: I, jalr: I)            |
//                                   pc   + imm (auipc: U, jal: J, b_type: B) |
//                                   0    + imm (lui: U)

// unsigned_cmp_op1, unsigned_cmp_op2 = src1, src2 (beq: B, bne: B, bltu: B, bgeu: B, sltu: R) |
//                                      src1, imm  (sltiu: I)                                  |

// signed_cmp_op1, signed_cmp_op2 = src1, src2 (blt: B, bge: B, slt: R) |
//                                  src1, imm  (slti: I)                |

// and_op1, and_op2 = src1, src2 (and: R)  |
//                    src1, imm  (andi: I) |

// or_op1, or_op2 = src1, src2 (or: R)  |
//                  src1, imm  (ori: I) |

// xor_op1, xor_op2 = src1, src2 (xor: R)  |
//                    src1, imm  (xori: I) |

// sll_op1, sll_op2 = src1, src2[4:0] (sll: R)  |
//                    src1, imm[4:0]  (slli: I) |

// srl_op1, srl_op2 = src1, src2[4:0] (srl: R)  |
//                    src1, imm[4:0]  (srli: I) |

// sra_op1, sra_op2 = src1, src2[4:0] (sra: R)  |
//                    src1, imm[4:0]  (srai: I) |

// dst = main_adder_sum      (auipc: U, lui: U, addi: I, add: R, sub: R) |
//       sll_out             (slli: I, sll: R)                           |
//       srl_out             (srli: I, srl: R)                           |
//       sra_out             (srai: I, sra: R)                           |
//       unsigned_cmp_lt     (sltiu: I, sltu: R)                         |
//       signed_cmp_lt       (slti: I, slt: R)                           |
//       and_out             (andi: I, and: R)                           |
//       or_out              (ori: I, or: R)                             |
//       xor_out             (xori: I, xor: R)                           |
//       pc_plus_4_adder_sum (jal: J, jalr: I)                           |

// npc[31:1] = main_adder_sum[31:1] (b_type: B, jal: J, jalr: I)
// npc[0] = 1'b0 (jalr: I)                        |
//          main_adder_sum[0] (b_type: B, jal: J)

// main_adder_op1 = pc | src1 | 0
// main_adder_op2 = imm | src2 | minus_src2

module integer_execute (
    input wire clk,
    input wire rst_aL,
    input wire iiq_issue_data_t iiq_issue_data,
    output wire rob_id_t instr_rob_id_out, // sent to bypass paths, iiq for capture, used for indexing into rob for writeback
    output wire execute_valid, // to guard broadcast (iiq, and lsq) and bypass (dispatch and issue) capture
    output wire alu_broadcast_valid,
    output wire reg_data_t dst,
    output wire npc_wb_valid, // change pc to npc in rob only if instr is b_type or jalr
    output wire npc_mispred, // to be written back to rob.br_mispred (0: no misprediction, 1: misprediction)
    output wire addr_t npc // next pc, to be written back to rob.pc_npc (b_type or jalr)
);
    // extract the iiq_issue_data fields
    wire entry_valid = iiq_issue_data.entry_valid;
    wire reg_data_t src1 = iiq_issue_data.src1_data;
    wire reg_data_t src2 = iiq_issue_data.src2_data;
    wire rob_id_t instr_rob_id_in = iiq_issue_data.instr_rob_id;
    wire imm_t imm = iiq_issue_data.imm;
    wire addr_t pc = iiq_issue_data.pc;
    wire funct3_t funct3 = iiq_issue_data.funct3; // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    wire is_r_type = iiq_issue_data.is_r_type;
    wire is_i_type = iiq_issue_data.is_i_type;
    wire is_u_type = iiq_issue_data.is_u_type; // lui and auipc only
    wire is_b_type = iiq_issue_data.is_b_type;
    wire is_j_type = iiq_issue_data.is_j_type; // jal only
    wire is_sub = iiq_issue_data.is_sub; // if is_r_type, 0 = add, 1 = sub
    wire is_sra_srai = iiq_issue_data.is_sra_srai; // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    wire is_lui = iiq_issue_data.is_lui; // if is_u_type, 0 = auipc, 1 = lui
    wire is_jalr = iiq_issue_data.is_jalr; // if is_i_type, 0 = else, 1 = jalr
    wire br_dir_pred = iiq_issue_data.br_dir_pred; // received from issue (0: not taken, 1: taken)

    // FIXME: convert to structural
    wire word_t main_adder_op1 = (is_r_type || is_i_type) ?
                                    src1 :
                                    (is_lui) ?
                                        `WORD_WIDTH'b0:
                                        pc;
    // wire is_r_or_i_type;
    // or_ #(
    //     .N_INS(2)
    // ) is_r_or_i_type_or (
    //     .a({is_r_type, is_i_type}),
    //     .y(is_r_or_i_type)
    // );
    // wire is_not_lui;
    // inv is_not_lui_inv (
    //     .a(is_lui),
    //     .y(is_not_lui)
    // );
    // wire word_t main_adder_op1;
    // onehot_mux #(
    //     .WIDTH(`WORD_WIDTH),
    //     .N_INS(2)
    // ) main_adder_op1_mux (
    //     .clk(clk),
    //     .ins({src1, pc}),
    //     .sel({is_r_or_i_type, is_not_lui}),
    //     .out(main_adder_op1)
    // );

    // wire word_t minus_src2 = ~src2 + 1;
    wire word_t inv_src2;
    bitwise_inv #(
        .WIDTH(`WORD_WIDTH)
    ) src2_inv (
        .a(src2),
        .y(inv_src2)
    );
    wire word_t minus_src2;
    adder #(
        .WIDTH(`WORD_WIDTH)
    ) minus_src2_adder (
        .a(inv_src2),
        .b(`WORD_WIDTH'b1),
        .sum(minus_src2)
    );

    wire word_t main_adder_op2 = (!is_r_type) ?
                                    imm :
                                    is_sub ?
                                        minus_src2 :
                                        src2;
    // wire is_not_r_type;
    // inv is_not_r_type_inv (
    //     .a(is_r_type),
    //     .y(is_not_r_type)
    // );
    // wire is_not_sub;
    // inv is_not_sub_inv (
    //     .a(is_sub),
    //     .y(is_not_sub)
    // );
    // wire word_t main_adder_op2;
    // onehot_mux #(
    //     .WIDTH(`WORD_WIDTH),
    //     .N_INS(3)
    // ) main_adder_op2_mux (
    //     .clk(clk),
    //     .ins({src2,       minus_src2, imm}),
    //     .sel({is_not_sub, is_sub,     is_not_r_type}),
    //     .out(main_adder_op2)
    // );

    wire word_t main_adder_sum;
    adder #(
        .WIDTH(`WORD_WIDTH)
    ) main_adder (
        .a(main_adder_op1),
        .b(main_adder_op2),
        .sum(main_adder_sum)
    );
    wire addr_t pc_plus_4;
    adder #(
        .WIDTH(`ADDR_WIDTH)
    ) pc_plus_4_adder (
        .a(pc),
        .b(`ADDR_WIDTH'd4),
        .sum(pc_plus_4)
    );

    wire word_t cmp_op1 = src1;
    // wire word_t cmp_op2 = is_i_type ? imm : src2;
    wire word_t cmp_op2;
    mux_ #(
        .WIDTH(`WORD_WIDTH),
        .N_INS(2)
    ) cmp_op2_mux (
        .ins({imm, src2}),
        .sel(is_i_type),
        .out(cmp_op2)
    );

    wire word_t unsigned_cmp_eq;
    wire word_t unsigned_cmp_lt;
    wire word_t unsigned_cmp_ge;
    wire word_t signed_cmp_eq;
    wire word_t signed_cmp_lt;
    wire word_t signed_cmp_ge;
    unsigned_cmp #(
        .WIDTH(`WORD_WIDTH)
    ) unsigned_cmp (
        .a(cmp_op1),
        .b(cmp_op2),
        .eq(),
        .lt(),
        .ge()
    );
    assign unsigned_cmp_eq = {31'b0, unsigned_cmp.eq};
    assign unsigned_cmp_lt = {31'b0, unsigned_cmp.lt};
    assign unsigned_cmp_ge = {31'b0, unsigned_cmp.ge};

    signed_cmp #(
        .WIDTH(`WORD_WIDTH)
    ) signed_cmp (
        .a(cmp_op1),
        .b(cmp_op2),
        .eq(),
        .lt(),
        .ge()
    );
    assign signed_cmp_eq = {31'b0, unsigned_cmp.eq};
    assign signed_cmp_lt = {31'b0, unsigned_cmp.lt};
    assign signed_cmp_ge = {31'b0, unsigned_cmp.ge};

    wire word_t and_op1 = src1;
    // wire word_t and_op2 = is_i_type ? imm : src2;
    wire word_t and_op2;
    mux_ #(
        .WIDTH(`WORD_WIDTH),
        .N_INS(2)
    ) and_op2_mux (
        .ins({imm, src2}),
        .sel(is_i_type),
        .out(and_op2)
    );

    wire word_t and_out;
    bitwise_and #(
        .WIDTH(`WORD_WIDTH)
    ) _bitwise_and (
        .a(and_op1),
        .b(and_op2),
        .y(and_out)
    );
    wire word_t or_op1 = src1;
    // wire word_t or_op2 = is_i_type ? imm : src2;
    wire word_t or_op2;
    mux_ #(
        .WIDTH(`WORD_WIDTH),
        .N_INS(2)
    ) or_op2_mux (
        .ins({imm, src2}),
        .sel(is_i_type),
        .out(or_op2)
    );

    wire word_t or_out;
    bitwise_or #(
        .WIDTH(`WORD_WIDTH)
    ) _bitwise_or (
        .a(or_op1),
        .b(or_op2),
        .y(or_out)
    );
    wire word_t xor_op1 = src1;
    // wire word_t xor_op2 = is_i_type ? imm : src2;
    wire word_t xor_op2;
    mux_ #(
        .WIDTH(`WORD_WIDTH),
        .N_INS(2)
    ) xor_op2_mux (
        .ins({imm, src2}),
        .sel(is_i_type),
        .out(xor_op2)
    );

    wire word_t xor_out;
    bitwise_xor #(
        .WIDTH(`WORD_WIDTH)
    ) _bitwise_xor (
        .a(xor_op1),
        .b(xor_op2),
        .y(xor_out)
    );

    wire word_t sll_op1 = src1;
    // wire [4:0] sll_op2 = is_i_type ? imm[4:0] : src2[4:0]; TODO: double-check the width
    wire [4:0] sll_op2;
    mux_ #(
        .WIDTH(5),
        .N_INS(2)
    ) sll_op2_mux (
        .ins({imm[4:0], src2[4:0]}),
        .sel(is_i_type),
        .out(sll_op2)
    );
    wire word_t sll_out = sll_op1 << sll_op2;
    wire word_t srl_op1 = src1;
    // wire [4:0] srl_op2 = is_i_type ? imm[4:0] : src2[4:0];  TODO: double-check the width
    wire [4:0] srl_op2;
    mux_ #(
        .WIDTH(5),
        .N_INS(2)
    ) srl_op2_mux (
        .ins({imm[4:0], src2[4:0]}),
        .sel(is_i_type),
        .out(srl_op2)
    );
    wire word_t srl_out = srl_op1 >> srl_op2;
    wire word_t sra_op1 = src1;
    // wire [4:0] sra_op2 = is_i_type ? imm[4:0] : src2[4:0];  TODO: double-check the width
    wire [4:0] sra_op2;
    mux_ #(
        .WIDTH(5),
        .N_INS(2)
    ) sra_op2_mux (
        .ins({imm[4:0], src2[4:0]}),
        .sel(is_i_type),
        .out(sra_op2)
    );
    wire word_t sra_out = sra_op1 >>> sra_op2;

    assign instr_rob_id_out = instr_rob_id_in;

    assign execute_valid = entry_valid;

    // wire dst_valid = !is_b_type;
    wire dst_valid;
    inv dst_valid_inv (
        .a(is_b_type),
        .y(dst_valid)
    );
    // assign alu_broadcast_valid = entry_valid & dst_valid;
    and_ #(
        .N_INS(2)
    ) alu_broadcast_valid_and (
        .a({entry_valid, dst_valid}),
        .y(alu_broadcast_valid)
    );
    // wire sel_main_adder_sum = is_u_type | (~|funct3); // funct3 = 3'b000
    wire funct3_nor;
    nor_ #(
        .N_INS(`FUNCT3_WIDTH)
    ) _funct3_nor (
        .a(funct3),
        .y(funct3_nor)
    );
    wire sel_main_adder_sum;
    or_ #(
        .N_INS(2)
    ) sel_main_adder_sum_or (
        .a({is_u_type, funct3_nor}),
        .y(sel_main_adder_sum)
    );

    wire not_funct3_2;
    wire not_funct3_1;
    wire not_funct3_0;
    inv not_funct3_2_inv (
        .a(funct3[2]),
        .y(not_funct3_2)
    );
    inv not_funct3_1_inv (
        .a(funct3[1]),
        .y(not_funct3_1)
    );
    inv not_funct3_0_inv (
        .a(funct3[0]),
        .y(not_funct3_0)
    );

    // wire sel_sll_out = ~funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b001
    wire sel_sll_out;
    and_ #(
        .N_INS(3)
    ) sel_sll_out_and (
        .a({not_funct3_2, not_funct3_1, funct3[0]}),
        .y(sel_sll_out)
    );

    // wire sel_srl_out = funct3[2] & ~funct3[1] & funct3[0] & ~is_sra_srai; // funct3 = 3'b101
    wire not_is_sra_srai;
    inv not_is_sra_srai_inv (
        .a(is_sra_srai),
        .y(not_is_sra_srai)
    );

    wire sel_srl_out;
    and_ #(
        .N_INS(4)
    ) sel_srl_out_and (
        .a({funct3[2], not_funct3_1, funct3[0], not_is_sra_srai}),
        .y(sel_srl_out)
    );

    // wire sel_sra_out = funct3[2] & ~funct3[1] & funct3[0] & is_sra_srai; // funct3 = 3'b101
    wire sel_sra_out;
    and_ #(
        .N_INS(4)
    ) sel_sra_out_and (
        .a({funct3[2], not_funct3_1, funct3[0], is_sra_srai}),
        .y(sel_sra_out)
    );

    // wire sel_unsigned_cmp_lt = ~funct3[2] & funct3[1] & funct3[0]; // funct3 = 3'b011
    wire sel_unsigned_cmp_lt;
    and_ #(
        .N_INS(3)
    ) sel_unsigned_cmp_lt_and (
        .a({not_funct3_2, funct3[1], funct3[0]}),
        .y(sel_unsigned_cmp_lt)
    );

    // wire sel_signed_cmp_lt = ~funct3[2] & funct3[1] & ~funct3[0]; // funct3 = 3'b010
    wire sel_signed_cmp_lt;
    and_ #(
        .N_INS(3)
    ) sel_signed_cmp_lt_and (
        .a({not_funct3_2, funct3[1], not_funct3_0}),
        .y(sel_signed_cmp_lt)
    );

    // wire sel_and_out = &funct3; // funct3 = 3'b111
    wire sel_and_out;
    and_ #(
        .N_INS(`FUNCT3_WIDTH)
    ) sel_and_out_and (
        .a(funct3),
        .y(sel_and_out)
    );

    // wire sel_or_out = funct3[2] & funct3[1] & ~funct3[0]; // funct3 = 3'b110
    wire sel_or_out;
    and_ #(
        .N_INS(3)
    ) sel_or_out_and (
        .a({funct3[2], funct3[1], not_funct3_0}),
        .y(sel_or_out)
    );

    // wire sel_xor_out = funct3[2] & ~funct3[1] & ~funct3[0]; // funct3 = 3'b100
    wire sel_xor_out;
    and_ #(
        .N_INS(3)
    ) sel_xor_out_and (
        .a({funct3[2], not_funct3_1, not_funct3_0}),
        .y(sel_xor_out)
    );

    // wire sel_pc_plus_4 = is_j_type | is_jalr; // jal or jalr
    wire sel_pc_plus_4;
    or_ #(
        .N_INS(2)
    ) sel_pc_plus_4_or (
        .a({is_j_type, is_jalr}),
        .y(sel_pc_plus_4)
    );

    onehot_mux #(
        .WIDTH(`WORD_WIDTH),
        .N_INS(10)
    ) dst_mux (
        .clk(clk),
        .ins({
            main_adder_sum,
            sll_out,
            srl_out,
            sra_out,
            unsigned_cmp_lt,
            signed_cmp_lt,
            and_out,
            or_out,
            xor_out,
            pc_plus_4
        }),
        .sel({
            sel_main_adder_sum,
            sel_sll_out,
            sel_srl_out,
            sel_sra_out,
            sel_unsigned_cmp_lt,
            sel_signed_cmp_lt,
            sel_and_out,
            sel_or_out,
            sel_xor_out,
            sel_pc_plus_4
        }),
        .out(dst)
    );

    // wire sel_beq_taken = ~|funct3; // funct3 = 3'b000
    wire sel_beq_taken;
    nor_ #(
        .N_INS(`FUNCT3_WIDTH)
    ) sel_beq_taken_nor (
        .a(funct3),
        .y(sel_beq_taken)
    );

    // wire sel_bne_taken = ~funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b001
    wire sel_bne_taken;
    and_ #(
        .N_INS(3)
    ) sel_bne_taken_and (
        .a({not_funct3_2, not_funct3_1, funct3[0]}),
        .y(sel_bne_taken)
    );

    // wire sel_blt_taken = funct3[2] & ~funct3[1] & ~funct3[0]; // funct3 = 3'b100
    wire sel_blt_taken;
    and_ #(
        .N_INS(3)
    ) sel_blt_taken_and (
        .a({funct3[2], not_funct3_1, not_funct3_0}),
        .y(sel_blt_taken)
    );

    // wire sel_bge_taken = funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b101
    wire sel_bge_taken;
    and_ #(
        .N_INS(3)
    ) sel_bge_taken_and (
        .a({funct3[2], not_funct3_1, funct3[0]}),
        .y(sel_bge_taken)
    );

    // wire sel_bltu_taken = funct3[2] & funct3[1] & ~funct3[0]; // funct3 = 3'b110
    wire sel_bltu_taken;
    and_ #(
        .N_INS(3)
    ) sel_bltu_taken_and (
        .a({funct3[2], funct3[1], not_funct3_0}),
        .y(sel_bltu_taken)
    );

    // wire sel_bgeu_taken = &funct3; // funct3 = 3'b111
    wire sel_bgeu_taken;
    and_ #(
        .N_INS(`FUNCT3_WIDTH)
    ) sel_bgeu_taken_and (
        .a(funct3),
        .y(sel_bgeu_taken)
    );

    wire unsigned_cmp_eq_or;
    wire unsigned_cmp_eq_nor;
    wire signed_cmp_lt_or;
    wire signed_cmp_ge_or;
    wire unsigned_cmp_lt_or;
    wire unsigned_cmp_ge_or;
    or_ #(
        .N_INS(`WORD_WIDTH)
    ) _unsigned_cmp_eq_or (
        .a(unsigned_cmp_eq),
        .y(unsigned_cmp_eq_or)
    );
    nor_ #(
        .N_INS(`WORD_WIDTH)
    ) _unsigned_cmp_eq_nor (
        .a(unsigned_cmp_eq),
        .y(unsigned_cmp_eq_nor)
    );
    or_ #(
        .N_INS(`WORD_WIDTH)
    ) _signed_cmp_lt_or (
        .a(signed_cmp_lt),
        .y(signed_cmp_lt_or)
    );
    or_ #(
        .N_INS(`WORD_WIDTH)
    ) _signed_cmp_ge_or (
        .a(signed_cmp_ge),
        .y(signed_cmp_ge_or)
    );
    or_ #(
        .N_INS(`WORD_WIDTH)
    ) _unsigned_cmp_lt_or (
        .a(unsigned_cmp_lt),
        .y(unsigned_cmp_lt_or)
    );
    or_ #(
        .N_INS(`WORD_WIDTH)
    ) _unsigned_cmp_ge_or (
        .a(unsigned_cmp_ge),
        .y(unsigned_cmp_ge_or)
    );

    wire br_taken;
    onehot_mux #(
        .WIDTH(1),
        .N_INS(6)
    ) br_taken_mux (
        .clk(clk),
        .ins({
            // |{unsigned_cmp_eq},
            // ~|{unsigned_cmp_eq},
            // |{signed_cmp_lt},
            // |{signed_cmp_ge},
            // |{unsigned_cmp_lt},
            // |{unsigned_cmp_ge}
            unsigned_cmp_eq_or,
            unsigned_cmp_eq_nor,
            signed_cmp_lt_or,
            signed_cmp_ge_or,
            unsigned_cmp_lt_or,
            unsigned_cmp_ge_or
        }),
        .sel({
            sel_beq_taken,
            sel_bne_taken,
            sel_blt_taken,
            sel_bge_taken,
            sel_bltu_taken,
            sel_bgeu_taken
        }),
        .out(br_taken)
    );
    // assign npc_wb_valid = is_b_type | is_jalr; // only write to rob.pc_npc (change pc to npc) if instr is b_type or jalr
    or_ #(
        .N_INS(2)
    ) npc_wb_valid_or (
        .a({is_b_type, is_jalr}),
        .y(npc_wb_valid)
    );
    // assign npc = {main_adder_sum[31:1], is_jalr ? 1'b0 : main_adder_sum[0]};
    mux_ #(
        .WIDTH(1),
        .N_INS(2)
    ) npc_0_mux (
        .ins({1'b0, main_adder_sum[0]}),
        .sel(is_jalr),
        .out(npc[0])
    );
    assign npc[31:1] = main_adder_sum[31:1];

    // assign npc_mispred = (br_dir_pred ^ br_taken) | is_jalr;
    wire br_dir_pred_xor_br_taken;
    xor_ #(
        .N_INS(2)
    ) _br_dir_pred_xor_br_taken (
        .a({br_dir_pred, br_taken}),
        .y(br_dir_pred_xor_br_taken)
    );
    or_ #(
        .N_INS(2)
    ) npc_mispred_or (
        .a({br_dir_pred_xor_br_taken, is_jalr}),
        .y(npc_mispred)
    );
endmodule

`endif
