module predicted_NPC # (

) (
    input wire [INSTR_WIDTH-1:0] instr,
    input wire [ADDR_WIDTH-1:0] PC,

    output wire is_cond_branch,
    output wire br_prediction,
    output wire [ADDR_WIDTH-1:0] next_PC
);

// ::: JAL adder ::::::::::::::::::::::::::::::::::::::::::
wire [ADDR_WIDTH-1:0] sext_jal_off;
sign_extend sext32_1 # (
    .IN_WIDTH(1+8+11+1),
    .OUT_WIDTH(ADDR_WIDTH)
)(
    .in({instr[31],instr[19:12],instr[30:20],instr[0]}),
    .out(sext_jal_off)
);

wire [ADDR_WIDTH-1:0] jal_add_out;
add32 jal_adder (
    .a(PC),
    .b({instr[31],instr[19:12],instr[30:20],instr[0]}),
    .y(jal_add_out)
);
// END JAL adder ::::::::::::::::::::::::::::::::::::::::::

// ::: B-TYPE adder ::::::::::::::::::::::::::::::::::::::::::
wire [ADDR_WIDTH-1:0] sext32_btype_off;
sign_extend sext32_1 # (
    .IN_WIDTH(1+6+4+1),
    .OUT_WIDTH(ADDR_WIDTH)
)(
    .in({instr[31],instr[30:25],instr[11:8],instr[0]}),
    .out(sext32_btype_off)
);

wire [ADDR_WIDTH-1:0] btype_add_out;
add32 jal_adder (
    .a(PC),
    .b(sext32_btype_off),
    .y(btype_add_out)
);
// END B-TYPE adder ::::::::::::::::::::::::::::::::::::::::::

// ::: PCplus4 adder ::::::::::::::::::::::::::::::::::::::::::
wire [ADDR_WIDTH-1:0] PCplus4_add_out;
add32 jal_adder (
    .a(PC),
    .b(32'h00000004),
    .y(PCplus4_add_out)
);
// END PCplus4 adder ::::::::::::::::::::::::::::::::::::::::::

// Static BR predictor mux, backwards taken forwards not taken ::
wire [ADDR_WIDTH-1:0] br_predictor_out;
mux2 #(
    .WIDTH(ADDR_WIDTH)
) (
    .sel(instr[31]),
    .in0(PCplus4_add_out),
    .in1(btype_add_out),
    .out(br_predictor_out)
);
// END Static BR predictor mux ::::::::::::::::::::::::::::::::::

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
AND3_X1 is_br_and_backwards (
    .A1(instr[5]),
    .A2(instr[6]),   // 5 & 6 = 1 if its a br/jal/jalr
    .A3(instr[31]),  // 0 if forwards
    .ZN(is_br_and_backwards)
);

// Outputs assigned below
mux4 toNPCmux #(
    .WIDTH(ADDR_WIDTH)
)(
    .d0(PCplus4_add_out),  
    .d1(PCplus4_add_out),
    .d2(btype_add_out),
    .d3(jal_add_out),
    .s({is_br_and_backwards,is_unconditional}),
    .y(next_PC)
);
assign is_cond_branch = is_unconditional;
assign br_prediction = is_br_and_backwards;  

endmodule