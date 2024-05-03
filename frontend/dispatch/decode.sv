`include "misc/global_defs.svh"
`include "misc/cmp/unsigned_cmp.v"
`include "misc/and/and_.v"
`include "misc/or/or_.v"
`include "misc/inv.v"
`include "misc/onehot_mux/onehot_mux.v"

module decode (
    input wire clk,
    input wire instr_t instr,
    output wire rs1_valid, // valid stands for "exists"
    output wire rs2_valid,
    output wire rd_valid,
    output wire arf_id_t rs1,
    output wire arf_id_t rs2,
    output wire arf_id_t rd,
    output wire funct3_t funct3, // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    output wire imm_t imm,
    output wire is_r_type,
    output wire is_i_type,
    output wire is_s_type,
    output wire is_b_type,
    output wire is_u_type, // lui and auipc only
    output wire is_j_type, // jal only
    output wire is_sub, // if is_r_type, 0 = add, 1 = sub
    output wire is_sra_srai, // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    output wire is_lui, // if is_u_type, 0 = auipc, 1 = lui
    output wire is_jalr, // if is_i_type, 0 = else, 1 = jalr
    output wire is_int_instr,
    output wire is_ls_instr,
    output req_width_t ls_width,
    output wire ld_sign
);
    wire opcode_t opcode = instr[`opcode_bits];

    wire is_op_opcode;
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) op_opcode_cmp (
        .a(opcode),
        .b(`OP_OPCODE),
        .eq(is_op_opcode),
        .lt(),
        .ge()
    );
    assign is_r_type = is_op_opcode;

    wire is_op_imm_opcode;
    wire is_ld_opcode;
    wire is_jalr_opcode;
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) op_imm_opcode_cmp (
        .a(opcode),
        .b(`OP_IMM_OPCODE),
        .eq(is_op_imm_opcode),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) ld_opcode_cmp (
        .a(opcode),
        .b(`LD_OPCODE),
        .eq(is_ld_opcode),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) jalr_opcode_cmp (
        .a(opcode),
        .b(`JALR_OPCODE),
        .eq(is_jalr_opcode),
        .lt(),
        .ge()
    );
    or_ #(.N_INS(3)) is_i_type_or (
        .a({is_op_imm_opcode, is_ld_opcode, is_jalr_opcode}),
        .y(is_i_type)
    );

    wire is_st_opcode;
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) st_opcode_cmp (
        .a(opcode),
        .b(`ST_OPCODE),
        .eq(is_st_opcode),
        .lt(),
        .ge()
    );
    assign is_s_type = is_st_opcode;

    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) br_opcode_cmp (
        .a(opcode),
        .b(`BR_OPCODE),
        .eq(is_b_type),
        .lt(),
        .ge()
    );

    wire is_lui_opcode;
    wire is_auipc_opcode;
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) lui_opcode_cmp (
        .a(opcode),
        .b(`LUI_OPCODE),
        .eq(is_lui_opcode),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) auipc_opcode_cmp (
        .a(opcode),
        .b(`AUIPC_OPCODE),
        .eq(is_auipc_opcode),
        .lt(),
        .ge()
    );
    or_ #(.N_INS(2)) is_u_type_or (
        .a({is_lui_opcode, is_auipc_opcode}),
        .y(is_u_type)
    );

    unsigned_cmp #(.WIDTH(`OPCODE_WIDTH)) jal_opcode_cmp (
        .a(opcode),
        .b(`JAL_OPCODE),
        .eq(is_j_type),
        .lt(),
        .ge()
    );

    or_ #(.N_INS(4)) rs1_valid_or (
        .a({is_r_type, is_i_type, is_s_type, is_b_type}),
        .y(rs1_valid)
    );
    or_ #(.N_INS(3)) rs2_valid_or (
        .a({is_r_type, is_s_type, is_b_type}),
        .y(rs2_valid)
    );
    or_ #(.N_INS(4)) rd_valid_or (
        .a({is_r_type, is_i_type, is_u_type, is_j_type}),
        .y(rd_valid)
    );

    assign rs1           = instr[`rs1_bits];
    assign rs2           = instr[`rs2_bits];
    assign rd            = instr[`rd_bits];
    assign funct3        = instr[`funct3_bits];
    wire funct7_t funct7 = instr[`funct7_bits];

    wire imm_t i_imm = `I_IMM(instr);
    wire imm_t s_imm = `S_IMM(instr);
    wire imm_t b_imm = `B_IMM(instr);
    wire imm_t u_imm = `U_IMM(instr);
    wire imm_t j_imm = `J_IMM(instr);

    onehot_mux #(
        .WIDTH(`IMM_WIDTH),
        .N_INS(5)
    ) imm_mux (
        .clk(clk),
        .ins({i_imm,     s_imm,     b_imm,     u_imm,     j_imm    }),
        .sel({is_i_type, is_s_type, is_b_type, is_u_type, is_j_type}),
        .out(imm)
    );

    // assign is_sub      =  (opcode == `OP_OPCODE)      && (funct3 == `SUB_FUNCT3)  && (funct7[5]);
    wire is_sub_funct3;
    unsigned_cmp #(.WIDTH(`FUNCT3_WIDTH)) sub_funct3_cmp (
        .a(funct3),
        .b(`SUB_FUNCT3),
        .eq(is_sub_funct3),
        .lt(),
        .ge()
    );
    and_ #(.N_INS(3)) is_sub_and (
        .a({is_op_opcode, is_sub_funct3, funct7[5]}),
        .y(is_sub)
    );

    // assign is_sra_srai = ((opcode == `OP_OPCODE)      && (funct3 == `SRA_FUNCT3)  && (funct7[5])) ||
    //                      ((opcode == `OP_IMM_OPCODE)  && (funct3 == `SRAI_FUNCT3) && (funct7[5]));
    wire is_sra_funct3;
    wire is_srai_funct3;
    unsigned_cmp #(.WIDTH(`FUNCT3_WIDTH)) sra_funct3_cmp (
        .a(funct3),
        .b(`SRA_FUNCT3),
        .eq(is_sra_funct3),
        .lt(),
        .ge()
    );
    unsigned_cmp #(.WIDTH(`FUNCT3_WIDTH)) srai_funct3_cmp (
        .a(funct3),
        .b(`SRAI_FUNCT3),
        .eq(is_srai_funct3),
        .lt(),
        .ge()
    );
    wire is_sra;
    wire is_srai;
    and_ #(.N_INS(3)) is_sra_and (
        .a({is_op_opcode, is_sra_funct3, funct7[5]}),
        .y(is_sra)
    );
    and_ #(.N_INS(3)) is_srai_and (
        .a({is_op_imm_opcode, is_srai_funct3, funct7[5]}),
        .y(is_srai)
    );
    or_ #(.N_INS(2)) is_sra_srai_or (
        .a({is_sra, is_srai}),
        .y(is_sra_srai)
    );

    // assign is_lui      =  (opcode == `LUI_OPCODE) ;
    assign is_lui = is_lui_opcode;

    // assign is_jalr     =  (opcode == `JALR_OPCODE);
    assign is_jalr = is_jalr_opcode;

    // assign is_ls_instr  = (opcode == `LD_OPCODE)  || (opcode == `ST_OPCODE);
    or_ #(.N_INS(2)) is_ls_instr_or (
        .a({is_ld_opcode, is_st_opcode}),
        .y(is_ls_instr)
    );

    // assign is_int_instr = ~is_ls_instr;
    inv is_int_instr_inv (
        .a(is_ls_instr),
        .y(is_int_instr)
    );

    // assign ls_width = funct3[1:0] == 2'b00 ? BYTE     :
    //                   funct3[1:0] == 2'b01 ? HALFWORD :
    //                   funct3[1:0] == 2'b10 ? WORD     :
    //                                          ERROR    ;
    assign ls_width = req_width_t'(funct3[1:0]);

    assign ld_sign  = funct3[2];
endmodule
