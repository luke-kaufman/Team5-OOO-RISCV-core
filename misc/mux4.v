// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux4 #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] d0,   // Input 0
    input wire [WIDTH-1:0] d1,   // Input 1
    input wire [WIDTH-1:0] d2,   // Input 2
    input wire [WIDTH-1:0] d3,   // Input 3
    input wire [1:0] s,          // Select lines
    output wire [WIDTH-1:0] y    // Output
);
    // invert the select lines
    wire [1:0] inv_s;
    INV_X1 inv0(s[0], inv_s[0]);
    INV_X1 inv1(s[1], inv_s[1]);

    // the gated inputs
    wire [WIDTH-1:0] gated_d0;
    wire [WIDTH-1:0] gated_d1;
    wire [WIDTH-1:0] gated_d2;
    wire [WIDTH-1:0] gated_d3;
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            // AND gates for each input condition
            AND3_X1 and_gate0(inv_s[1], inv_s[0], d0[i], gated_d0[i]);
            AND3_X1 and_gate1(inv_s[1], s[0], d1[i], gated_d1[i]);
            AND3_X1 and_gate2(s[1], inv_s[0], d2[i], gated_d2[i]);
            AND3_X1 and_gate3(s[1], s[0], d3[i], gated_d3[i]);
            
            // OR gate to combine the AND gates outputs
            OR4_X1 or_gate(gated_d0[i], gated_d1[i], gated_d2[i], gated_d3[i], y[i]);
        end
    endgenerate

endmodule
