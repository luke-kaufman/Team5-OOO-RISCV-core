`include "misc/global_defs.svh"

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
    input wire reg_data_t src1,
    input wire reg_data_t src2,
    input wire imm_t imm,
    input wire addr_t pc,
    input wire [2:0] funct3, // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    input wire is_r_type,
    input wire is_i_type,
    input wire is_u_type, // lui and auipc only
    input wire is_b_type,
    input wire is_j_type, // jal only
    input wire is_sub, // if is_r_type, 0 = add, 1 = sub
    input wire is_sra_srai, // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    input wire is_lui, // if is_u_type, 0 = auipc, 1 = lui
    input wire is_jalr, // if is_i_type, 0 = else, 1 = jalr
    input wire rob_id_t instr_rob_id_in, // received from issue
    input wire br_dir_pred, // received from issue (0: not taken, 1: taken)
    output wire rob_id_t instr_rob_id_out, // sent to bypass paths, iiq for capture, used for indexing into rob for writeback
    output wire dst_valid, // to guard broadcast (iiq and lsq) and bypass (dispatch and issue) capture
    output wire reg_data_t dst,
    output wire br_wb_valid, // change pc to npc in rob only if instr is b_type or jalr
    output wire addr_t npc, // next pc, to be written back to rob.pc_npc (b_type or jalr)
    output wire br_mispred // to be written back to rob.br_mispred (0: no misprediction, 1: misprediction)
);
    // FIXME: convert to structural
    wire word_t main_adder_op1 = (is_r_type || is_i_type) ?
                                    src1 :
                                    (is_lui) ?
                                        `WORD_WIDTH'b0:
                                        pc;
    wire word_t minus_src2 = ~src2 + 1;
    wire word_t main_adder_op2 = (!is_r_type) ?
                                    imm :
                                    is_sub ?
                                        minus_src2 :
                                        src2;
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
    wire word_t cmp_op2 = is_i_type ? imm : src2;
    wire unsigned_cmp_eq;
    wire unsigned_cmp_lt;
    wire unsigned_cmp_ge;
    wire signed_cmp_eq;
    wire signed_cmp_lt;
    wire signed_cmp_ge;
    unsigned_cmp_ #(
        .WIDTH(`WORD_WIDTH)
    ) unsigned_cmp (
        .a(cmp_op1),
        .b(cmp_op2),
        .eq(unsigned_cmp_eq),
        .lt(unsigned_cmp_lt),
        .ge(unsigned_cmp_ge)
    );
    signed_cmp_ #(
        .WIDTH(`WORD_WIDTH)
    ) signed_cmp (
        .a(cmp_op1),
        .b(cmp_op2),
        .eq(signed_cmp_eq),
        .lt(signed_cmp_lt),
        .ge(signed_cmp_ge)
    );

    wire word_t and_op1 = src1;
    wire word_t and_op2 = is_i_type ? imm : src2;
    wire word_t and_out;
    bitwise_and #(
        .WIDTH(`WORD_WIDTH)
    ) _bitwise_and (
        .a(and_op1),
        .b(and_op2),
        .y(and_out)
    );
    wire word_t or_op1 = src1;
    wire word_t or_op2 = is_i_type ? imm : src2;
    wire word_t or_out;
    bitwise_or #(
        .WIDTH(`WORD_WIDTH)
    ) _bitwise_or (
        .a(or_op1),
        .b(or_op2),
        .y(or_out)
    );
    wire word_t xor_op1 = src1;
    wire word_t xor_op2 = is_i_type ? imm : src2;
    wire word_t xor_out;
    bitwise_xor #(
        .WIDTH(`WORD_WIDTH)
    ) _bitwise_xor (
        .a(xor_op1),
        .b(xor_op2),
        .y(xor_out)
    );

    wire word_t sll_op1 = src1;
    wire word_t sll_op2 = is_i_type ? imm[4:0] : src2[4:0];
    wire word_t sll_out = sll_op1 << sll_op2;
    wire word_t srl_op1 = src1;
    wire word_t srl_op2 = is_i_type ? imm[4:0] : src2[4:0];
    wire word_t srl_out = srl_op1 >> srl_op2;
    wire word_t sra_op1 = src1;
    wire word_t sra_op2 = is_i_type ? imm[4:0] : src2[4:0];
    wire word_t sra_out = sra_op1 >>> sra_op2;

    assign instr_rob_id_out = instr_rob_id_in;

    assign dst_valid = !is_b_type;
    wire sel_main_adder_sum = is_u_type | (~|funct3); // funct3 = 3'b000
    wire sel_sll_out = ~funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b001
    wire sel_srl_out = funct3[2] & ~funct3[1] & funct3[0] & ~is_sra_srai; // funct3 = 3'b101
    wire sel_sra_out = funct3[2] & ~funct3[1] & funct3[0] & is_sra_srai; // funct3 = 3'b101
    wire sel_unsigned_cmp_lt = ~funct3[2] & funct3[1] & funct3[0]; // funct3 = 3'b011
    wire sel_signed_cmp_lt = ~funct3[2] & funct3[1] & ~funct3[0]; // funct3 = 3'b010
    wire sel_and_out = &funct3; // funct3 = 3'b111
    wire sel_or_out = funct3[2] & funct3[1] & ~funct3[0]; // funct3 = 3'b110
    wire sel_xor_out = funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b100
    wire sel_pc_plus_4 = is_j_type | is_jalr; // jal or jalr
    onehot_mux_ #(
        .WIDTH(`WORD_WIDTH),
        .N_INS(10)
    ) dst_mux (
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

    wire sel_beq_taken = ~|funct3; // funct3 = 3'b000
    wire sel_bne_taken = ~funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b001
    wire sel_blt_taken = funct3[2] & ~funct3[1] & ~funct3[0]; // funct3 = 3'b100
    wire sel_bge_taken = funct3[2] & ~funct3[1] & funct3[0]; // funct3 = 3'b101
    wire sel_bltu_taken = funct3[2] & funct3[1] & ~funct3[0]; // funct3 = 3'b110
    wire sel_bgeu_taken = &funct3; // funct3 = 3'b111
    wire br_taken;
    onehot_mux_ #(
        .WIDTH(1),
        .N_INS(6)
    ) br_taken_mux (
        .ins({
            unsigned_cmp_eq,
            ~unsigned_cmp_eq,
            signed_cmp_lt,
            signed_cmp_ge,
            unsigned_cmp_lt,
            unsigned_cmp_ge
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
    assign br_wb_valid = is_b_type | is_jalr; // only write to rob.pc_npc (change pc to npc) if instr is b_type or jalr
    assign npc = {main_adder_sum[31:1], is_jalr ? 1'b0 : main_adder_sum[0]};
    assign br_mispred = (br_dir_pred ^ br_taken) | is_jalr;
endmodule
