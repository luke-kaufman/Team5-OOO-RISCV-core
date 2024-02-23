// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module cmp32 (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire y
);
    wire [31:0] z;

    generate
        for (genvar i = 0; i < 32; i = i + 1) begin
            XOR2_X1 xor_gate(.A(a[i]), .B(b[i]), .Z(z[i]));
        end
    endgenerate

    AND4_X1 and_gate(.A1(z[0]), .A2(z[1]), .A3(z[2]), .A4(z[3]), .ZN(y));
endmodule