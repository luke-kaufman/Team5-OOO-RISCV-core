`ifndef MUX2_V
`define MUX2_V

`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux2 #(
    parameter WIDTH = 1,
    localparam N_INS = 2,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [WIDTH-1:0] [N_INS-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    // // invert the select line
    // wire [SEL_WIDTH-1:0] not_sel;
    // INV_X1 not_gate (sel, not_sel);

    // // the gated inputs
    // wire [WIDTH-1:0] [N_INS-1:0] gated_ins;
    // for (genvar i = 0; i < WIDTH; i++) begin
    //     // AND gates for each input condition
    //     AND2_X1 and_gate0 (not_sel, ins[0][i], gated_ins[0][i]);
    //     AND2_X1 and_gate1 (sel, ins[1][i], gated_ins[1][i]);

    //     // OR gate to combine the AND gates outputs
    //     OR2_X1 or_gate (gated_ins[0][i], gated_ins[1][i], out[i]);
    // end
    assign out = ins[sel];
endmodule

`endif
