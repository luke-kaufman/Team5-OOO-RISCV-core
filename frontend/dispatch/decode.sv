module decode (
    // FIXME: convert logic to wire
    input wire ififo_entry_t ififo_dispatch_data,
    output logic src1_valid, // valid stands for "exists"
    output logic src2_valid,
    output logic dst_valid,
    output imm_t imm,
    output addr_t pc,
    output logic [2:0] funct3, // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
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
    output logic is_ls_instr
);
    // FIXME: convert to structural
    wire instr_t instr;
    wire addr_t pc;
    wire logic is_cond_br;
    wire logic br_dir_pred;
    wire addr_t br_target_pred;
    assign {instr, pc, is_cond_br, br_dir_pred, br_target_pred} = ififo_dispatch_data;

    wire imm_t i_imm = `I_IMM(instr);
    wire imm_t s_imm = `S_IMM(instr);
    wire imm_t b_imm = `B_IMM(instr);
    wire imm_t u_imm = `U_IMM(instr);
    wire imm_t j_imm = `J_IMM(instr);

    assign src1_valid = is_r_type || is_i_type || is_s_type || is_b_type ;
    assign src2_valid = is_r_type || is_s_type || is_b_type              ;
    assign dst_valid  = is_r_type || is_i_type || is_u_type || is_j_type ;

    assign imm = is_r_type ? 0     :
                 is_i_type ? i_imm :
                 is_s_type ? s_imm :
                 is_b_type ? b_imm :
                 is_u_type ? u_imm :
                 is_j_type ? j_imm :
                             0     ;
    assign pc = instr.pc;
    assign funct3 = instr.funct3;

    assign is_r_type =  instr.opcode == `OP_OPCODE;
    assign is_i_type =  instr.opcode == `OP_IMM_OPCODE;
    assign is_s_type =  instr.opcode == `ST_OPCODE;
    assign is_b_type =  instr.opcode == `BR_OPCODE;
    assign is_u_type = (instr.opcode == `LUI_OPCODE) || (instr.opcode == `AUIPC_OPCODE);
    assign is_j_type =  instr.opcode == `JAL_OPCODE;

    assign is_sub = (instr.opcode == `OP_OPCODE) && (instr.funct3 == `SUB_FUNCT3) && (instr.funct7[5]);
    assign is_sra_srai = ((instr.opcode == `OP_OPCODE)     && (instr.funct3 == `SRA_FUNCT3)  && (instr.funct7[5])) ||
                         ((instr.opcode == `OP_IMM_OPCODE) && (instr.funct3 == `SRAI_FUNCT3) && (instr.funct7[5]));
    assign is_lui = instr.opcode == `LUI_OPCODE
    assign is_jalr = instr.opcode == `JALR_OPCODE

    assign is_ls_instr = (instr.opcode == `LD_OPCODE)  || (instr.opcode == `ST_OPCODE);
    assign is_int_instr = ~is_ls_instr;
endmodule