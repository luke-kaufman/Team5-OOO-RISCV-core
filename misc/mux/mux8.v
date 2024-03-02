`ifndef MUX8_V
`define MUX8_V

`include "freepdk-45nm/stdcells.v"
`include "misc/or/or_.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux8 #(
    parameter WIDTH = 1,
    localparam N_INS = 8,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [N_INS-1:0] [WIDTH-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    // // invert the select lines
    // wire [SEL_WIDTH-1:0] not_sel;
    // INV_X1 not_gate0 (.A(sel[0]), .ZN(not_sel[0]));
    // INV_X1 not_gate1 (.A(sel[1]), .ZN(not_sel[1]));
    // INV_X1 not_gate2 (.A(sel[2]), .ZN(not_sel[2]));

    // // the gated inputs
    // wire [N_INS-1:0] [WIDTH-1:0] gated_ins;
    // for (genvar i = 0; i < WIDTH; i++) begin
    //     // AND gates for each input condition
    //     AND4_X1 and_gate0 (.A1(not_sel[2]), .A2(not_sel[1]), .A3(not_sel[0]), .A4(ins[0][i]), .ZN(gated_ins[0][i]));
    //     AND4_X1 and_gate1 (.A1(not_sel[2]), .A2(not_sel[1]), .A3(sel[0]), .A4(ins[1][i]), .ZN(gated_ins[1][i]));
    //     AND4_X1 and_gate2 (.A1(not_sel[2]), .A2(sel[1]), .A3(not_sel[0]), .A4(ins[2][i]), .ZN(gated_ins[2][i]));
    //     AND4_X1 and_gate3 (.A1(not_sel[2]), .A2(sel[1]), .A3(sel[0]), .A4(ins[3][i]), .ZN(gated_ins[3][i]));
    //     AND4_X1 and_gate4 (.A1(sel[2]), .A2(not_sel[1]), .A3(not_sel[0]), .A4(ins[4][i]), .ZN(gated_ins[4][i]));
    //     AND4_X1 and_gate5 (.A1(sel[2]), .A2(not_sel[1]), .A3(sel[0]), .A4(ins[5][i]), .ZN(gated_ins[5][i]));
    //     AND4_X1 and_gate6 (.A1(sel[2]), .A2(sel[1]), .A3(not_sel[0]), .A4(ins[6][i]), .ZN(gated_ins[6][i]));
    //     AND4_X1 and_gate7 (.A1(sel[2]), .A2(sel[1]), .A3(sel[0]), .A4(ins[7][i]), .ZN(gated_ins[7][i]));
    // end

    // // OR gate to combine the AND gates outputs
    // for (genvar i = 0; i < N_INS; i++) begin
    //     or_ #(.N_INS(N_INS)
    //     );
    // end
    assign out = ins[sel];
endmodule

`endif
