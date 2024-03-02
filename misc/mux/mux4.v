`ifndef MUX4_V
`define MUX4_V

`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux4 #(
    parameter WIDTH = 1,
    localparam N_INS = 4,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [WIDTH-1:0] [N_INS-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    // // invert the select lines
    // wire [SEL_WIDTH-1:0] not_sel;

    // // the gated inputs
    // wire [WIDTH-1:0] [N_INS-1:0] gated_ins;
    // for (genvar i = 0; i < WIDTH; i = i + 1) begin
    //     // AND gates for each input condition
    //     AND3_X1 and_gate0 (not_sel[1], not_sel[0], ins[0][i], gated_ins[0][i]);
    //     AND3_X1 and_gate1 (not_sel[1], sel[0], ins[1][i], gated_ins[1][i]);
    //     AND3_X1 and_gate2 (sel[1], not_sel[0], ins[2][i], gated_ins[2][i]);
    //     AND3_X1 and_gate3 (sel[1], sel[0], ins[3][i], gated_ins[3][i]);

    //     // OR gate to combine the AND gates outputs
    //     OR4_X1 or_gate (gated_ins[0][i], gated_ins[1][i], gated_ins[2][i], gated_ins[3][i], out[i]);
    // end
    assign out = ins[sel];
endmodule

`endif
