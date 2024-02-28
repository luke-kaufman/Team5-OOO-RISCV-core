// IMPL STATUS: MISSING
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
    // Internal signals
    wire [1:0] not_s;
    wire [WIDTH-1:0] _d0, _d1, _d2, _d3;

    // Generate NOT gates for the select lines
    INV_X1 not_gate0(s[0], not_s[0]);
    INV_X1 not_gate1(s[1], not_s[1]);

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            // AND gates for each input condition
            AND3_X1 and_gate0(not_s[1], not_s[0], d0[i], _d0[i]); // d0 is selected when s1=0, s0=0
            AND3_X1 and_gate1(not_s[1], s[0], d1[i], _d1[i]);    // d1 is selected when s1=0, s0=1
            AND3_X1 and_gate2(s[1], not_s[0], d2[i], _d2[i]);    // d2 is selected when s1=1, s0=0
            AND3_X1 and_gate3(s[1], s[0], d3[i], _d3[i]);       // d3 is selected when s1=1, s0=1
            
            // OR gate to combine the AND gates outputs
            OR4_X1 or_gate(_d0[i], _d1[i], _d2[i], _d3[i], y[i]);
        end
    endgenerate

endmodule
