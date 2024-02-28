// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux2 #(
    parameter WIDTH = 1
) (
    input wire sel,
    input wire [WIDTH-1:0] in0,
    input wire [WIDTH-1:0] in1,
    output wire [WIDTH-1:0] out
);
    // invert the select line
    wire not_sel;
    INV_X1 not_gate(sel, not_sel);

    // the gated inputs
    wire [WIDTH-1:0] gated_in0;
    wire [WIDTH-1:0] gated_in1;
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            // AND gates for each input condition
            AND2_X1 and_gate0(not_sel, in0[i], gated_in0[i]);
            AND2_X1 and_gate1(sel, in1[i], gated_in1[i]);

            // OR gate to combine the AND gates outputs
            OR2_X1 or_gate(gated_in0[i], gated_in1[i], out[i]);
        end
    endgenerate
endmodule