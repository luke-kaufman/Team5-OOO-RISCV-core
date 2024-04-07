`ifndef PREDICTED_NPC_V
`define PREDICTED_NPC_V

`include "misc/global_defs.svh"
// `include "misc/adder.v"
`include "misc/mux/mux4.v"
`include "misc/sign_extend.v"

module predicted_NPC (
    input wire [`INSTR_WIDTH-1:0] instr,
    input wire [`ADDR_WIDTH-1:0] PC,

    output wire is_cond_branch,
    output wire br_prediction,
    output wire [`ADDR_WIDTH-1:0] next_PC
);

// ::: JAL adder ::::::::::::::::::::::::::::::::::::::::::
wire [`ADDR_WIDTH-1:0] sext_jal_off;
sign_extend # (
    .IN_WIDTH(1+8+11+1),
    .OUT_WIDTH(`ADDR_WIDTH)
) sext32_1 (
    .in({instr[31],instr[19:12],instr[30:20],instr[0]}),
    .out(sext_jal_off)
);

wire [`ADDR_WIDTH-1:0] jal_add_out;
adder #(.WIDTH(32)) jal_adder (
    .a(PC),
    .b(sext_jal_off),
    .sum(jal_add_out)
);
// END JAL adder ::::::::::::::::::::::::::::::::::::::::::

// ::: B-TYPE adder ::::::::::::::::::::::::::::::::::::::::::
wire [`ADDR_WIDTH-1:0] sext32_btype_off;
sign_extend # (
    .IN_WIDTH(1+6+4+1),
    .OUT_WIDTH(`ADDR_WIDTH)
) sext32_2 (
    .in({instr[31],instr[30:25],instr[11:8],instr[0]}),
    .out(sext32_btype_off)
);

wire [`ADDR_WIDTH-1:0] btype_add_out;
adder #(.WIDTH(32)) btype_adder (
    .a(PC),
    .b(sext32_btype_off),
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
wire is_unconditional;
// 00 - b-type (cond)
// 01 - jalr (cond) 
// 11 - jal  (uncond)
AND2_X1 is_uncond (
    .A1(instr[2]),
    .A2(instr[3]),
    .ZN(is_unconditional)
);

wire is_br_and_backwards;
AND3_X1 is_br_and_backwards_AND (
    .A1(instr[5]),
    .A2(instr[6]),   // 5 & 6 = 1 if its a br/jal/jalr
    .A3(instr[31]),  // 0 if forwards
    .ZN(is_br_and_backwards)
);

// Outputs assigned below
mux4 #(
    .WIDTH(`ADDR_WIDTH)
) to_NPC_mux (
    .ins({
        (jal_add_out),
        (btype_add_out),
        (PCplus4_add_out),
        (PCplus4_add_out)  
    }),
    .sel({is_br_and_backwards,is_unconditional}),
    .out(next_PC)
);
assign is_cond_branch = is_unconditional;
assign br_prediction = is_br_and_backwards;  

endmodule

`endif
