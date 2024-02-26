// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module and32 (
    input wire [31:0] a,
    output wire y
);
    // Generate a 1st level of 8 4-input AND gates
    wire [7:0] _y1;
    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            AND4_X1 and_gate(
                .A1(a[i*4+0]),
                .A2(a[i*4+1]),
                .A3(a[i*4+2]),
                .A4(a[i*4+3]),
                .ZN(_y1[i])
            );
        end
    endgenerate

    // Generate a 2nd level of 2 4-input AND gates
    wire [1:0] _y2;
    generate
        for (genvar i = 0; i < 2; i = i + 1) begin
            AND4_X1 and_gate(
                .A1(_y1[i*4+0]),
                .A2(_y1[i*4+1]),
                .A3(_y1[i*4+2]),
                .A4(_y1[i*4+3]),
                .ZN(_y2[i])
            );
        end
    endgenerate

    // Generate a 3rd level of 1 2-input AND gate
    AND2_X1 and_gate(
        .A1(_y2[0]),
        .A2(_y2[1]),
        .ZN(y)
    );
endmodule