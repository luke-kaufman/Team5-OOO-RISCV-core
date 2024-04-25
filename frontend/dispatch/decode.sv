`include "misc/global_defs.svh"

module decode (
    // FIXME: convert logic to wire
    input instr_t instr,
    output logic rs1_valid, // valid stands for "exists"
    output logic rs2_valid,
    output logic rd_valid,
    output arf_id_t rs1,
    output arf_id_t rs2,
    output arf_id_t rd,
    output funct3_t funct3, // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    output imm_t imm,
    output logic is_r_type,
    output logic is_i_type,
    output logic is_s_type,
    output logic is_b_type,
    output logic is_u_type, // lui and auipc only
    output logic is_j_type, // jal only
    output logic is_sub, // if is_r_type, 0 = add, 1 = sub
    output logic is_sra_srai, // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    output logic is_lui, // if is_u_type, 0 = auipc, 1 = lui
    output logic is_jalr, // if is_i_type, 0 = else, 1 = jalr
    output logic is_int_instr,
    output logic is_ls_instr,
    output req_width_t ls_width,
    output logic ld_sign
);
    // FIXME: convert to structural
    wire opcode_t opcode = instr[`opcode_bits];

    assign is_r_type =  opcode == `OP_OPCODE;
    assign is_i_type =  opcode == `OP_IMM_OPCODE;
    assign is_s_type =  opcode == `ST_OPCODE;
    assign is_b_type =  opcode == `BR_OPCODE;
    assign is_u_type = (opcode == `LUI_OPCODE) || (opcode == `AUIPC_OPCODE);
    assign is_j_type =  opcode == `JAL_OPCODE;

    assign rs1_valid = is_r_type || is_i_type || is_s_type || is_b_type;
    assign rs2_valid = is_r_type || is_s_type || is_b_type             ;
    assign rd_valid  = is_r_type || is_i_type || is_u_type || is_j_type;

    assign rs1 = instr[`rs1_bits];
    assign rs2 = instr[`rs2_bits];
    assign rd  = instr[`rd_bits] ;

    assign        funct3 = instr[`funct3_bits];
    wire funct7_t funct7 = instr[`funct7_bits];

    wire imm_t i_imm = `I_IMM(instr);
    wire imm_t s_imm = `S_IMM(instr);
    wire imm_t b_imm = `B_IMM(instr);
    wire imm_t u_imm = `U_IMM(instr);
    wire imm_t j_imm = `J_IMM(instr);
    assign imm = is_r_type ? 0     :
                 is_i_type ? i_imm :
                 is_s_type ? s_imm :
                 is_b_type ? b_imm :
                 is_u_type ? u_imm :
                 is_j_type ? j_imm :
                             0     ;

    assign is_sub      =  (opcode == `OP_OPCODE)      && (funct3 == `SUB_FUNCT3)  && (funct7[5]);
    assign is_sra_srai = ((opcode == `OP_OPCODE)      && (funct3 == `SRA_FUNCT3)  && (funct7[5])) ||
                         ((opcode == `OP_IMM_OPCODE)  && (funct3 == `SRAI_FUNCT3) && (funct7[5]));
    assign is_lui      =  (opcode == `LUI_OPCODE) ;
    assign is_jalr     =  (opcode == `JALR_OPCODE);

    assign is_ls_instr  = (opcode == `LD_OPCODE)  || (opcode == `ST_OPCODE);
    assign is_int_instr = ~is_ls_instr;

    assign ls_width = funct3[1:0] == 2'b00 ? BYTE     :
                      funct3[1:0] == 2'b01 ? HALFWORD :
                      funct3[1:0] == 2'b10 ? WORD     :
                                             ERROR    ;
    assign ld_sign  = funct3[2]  ;
endmodule
