// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
`ifndef OR32_V
`define OR32_V
module or32 (
    input wire [31:0] a,
    output wire y
);
    // Generate a first level of 8 4-input OR gates
    wire [7:0] y1;
    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            OR4_X1 or_gate(
                .A1(a[i*4+0]),
                .A2(a[i*4+1]),
                .A3(a[i*4+2]),
                .A4(a[i*4+3]),
                .ZN(y1[i])
            );
        end
    endgenerate

    // Generate a second level of 2 4-input OR gates
    wire [1:0] y2;
    generate
        for (genvar i = 0; i < 2; i = i + 1) begin
            OR4_X1 or_gate(
                .A1(y1[i*4+0]),
                .A2(y1[i*4+1]),
                .A3(y1[i*4+2]),
                .A4(y1[i*4+3]),
                .ZN(y2[i])
            );
        end
    endgenerate

    // Generate a third level of 1 2-input OR gate
    OR2_X1 or_gate(
        .A1(y2[0]),
        .A2(y2[1]),
        .ZN(y)
    );
endmodule
`endif