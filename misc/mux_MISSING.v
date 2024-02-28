// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module mux #(
    parameter WIDTH = 1,
    parameter N_INS = 2,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [WIDTH-1:0] [N_INS-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    // // Internal wires
    // wire [SEL_WIDTH-1:0] inv_sel;
    // wire [WIDTH-1:0] [N_INS-1:0] gated_ins;

    // // Invert the select signal
    // generate
    //     for (genvar i = 0; i < SEL_WIDTH; i = i + 1) begin
    //         INV_X1 inv_sel_inst(
    //             .a(sel[i]),
    //             .y(inv_sel[i])
    //         );
    //     end
    // endgenerate

    // // Generate the gated inputs
    // generate
    //     for (genvar i = 0; i < N_INS; i = i + 1) begin
    //         for (genvar j = 0; j < WIDTH; j = j + 1) begin
    //             And #(.N_INS(N_INS + 1)) and_gate (
    //                 .ins({inv_sel, ins[i]}),
    //             )
    //         end
    //     end
    assign out = ins[sel];
endmodule