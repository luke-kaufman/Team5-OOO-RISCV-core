`ifndef PREDICTED_NPC_V
`define PREDICTED_NPC_V

`include "misc/global_defs.svh"
// `include "misc/adder.v"
`include "misc/sign_extend.v"

module predicted_NPC (
    input wire [`INSTR_WIDTH-1:0] instr,
    input wire [`ADDR_WIDTH-1:0] PC,

    output wire is_cond_branch,
    output wire br_prediction,
    output wire [`ADDR_WIDTH-1:0] next_PC
);

// ::: JAL adder ::::::::::::::::::::::::::::::::::::::::::
wire [`ADDR_WIDTH-1:0] jal_add_out;
adder #(.WIDTH(32)) jal_adder (
    .a(PC),
    .b(`J_IMM(instr)),
    .sum(jal_add_out)
);
// END JAL adder ::::::::::::::::::::::::::::::::::::::::::

// ::: B-TYPE adder ::::::::::::::::::::::::::::::::::::::::::
wire [`ADDR_WIDTH-1:0] btype_add_out;
adder #(.WIDTH(32)) btype_adder (
    .a(PC),
    .b(`B_IMM(instr)),
    .sum(btype_add_out)
);
// END B-TYPE adder ::::::::::::::::::::::::::::::::::::::::::

// ::: PCplus4 adder ::::::::::::::::::::::::::::::::::::::::::
wire [`ADDR_WIDTH-1:0] PCplus4_add_out;
adder #(.WIDTH(32)) PCplus4_adder (
    .a(PC),
    .b(32'h00000004),
    .sum(PCplus4_add_out)
);
// END PCplus4 adder ::::::::::::::::::::::::::::::::::::::::::

// "To next PC mux" mux :::::::::::::::::::::::::::::::::::::::::
wire is_unconditional_jal;
// 00 - b-type (cond)
// 01 - jalr (uncond)
// 11 - jal  (uncond)
// if its a branch, instr[2] will be 1 if unconditional
AND2_X1 is_uncond_jal_AND (
    .A1(instr[2]),
    .A2(instr[3]),
    .ZN(is_unconditional_jal)
);

wire is_br;
AND2_X1 is_br_AND (
    .A1(instr[5]),
    .A2(instr[6]),   // 5 & 6 = 1 if its a br/jal/jalr
    .ZN(is_br)
);

wire is_uncond_br;
AND2_X1 is_uncond_br_AND (
    .A1(is_br),
    .A2(instr[2]),   // 3 = 1 if its a jal/jalr
    .ZN(is_uncond_br)
);

wire is_conditional; // both ir[2] and ir[3] must be 0 for conditional
OR2_X1 is_conditional_OR (
    .A1(instr[2]),
    .A2(instr[3]),
    .ZN()
);
INV_X1 is_conditional_INV (
    .A(is_conditional_OR.ZN),
    .ZN(is_conditional)
);
AND2_X1 is_cond_branch_AND (
    .A1(is_conditional),
    .A2(is_br),
    .ZN()
);

// Outputs assigned below
// is branch but unconditional: jal_add_out
// is branch and conditional and backwards: btype_add_out
// is branch and conditional and forwards: PC+4
// is not a branch: PC+4
mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(2)
) uncond_br_type (
    .ins({
        (jal_add_out),    // jal add if jal
        (PCplus4_add_out) // just mispredict target with PC+4 if jalr
    }),
    .sel(is_unconditional_jal),
    .out()
);

mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(4)
) br_type_mux (
    .ins({
        (uncond_br_type.out),
        (uncond_br_type.out),
        (btype_add_out),
        (PCplus4_add_out)
    }),
    .sel({instr[2] /*is_unconditional*/, instr[31] /*is_backwards*/}),
    .out()
);

mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(2)
) to_NPC_mux (
    .ins({
        (br_type_mux.out),
        (PCplus4_add_out)
    }),
    .sel(is_br),
    .out(next_PC)
);

assign is_cond_branch = is_cond_branch_AND.ZN;

AND2_X1 is_backwards_branch_AND (
    .A1(is_br),
    .A2(is_br && instr[31]),
    .ZN()
);

OR2_X1 br_prediction_AND (
    .A1(is_backwards_branch_AND.ZN),
    .A2(is_uncond_br),
    .ZN(br_prediction)
);

endmodule

`endif
