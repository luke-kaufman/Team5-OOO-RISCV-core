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

    and32 and_gate(.a(z), .y(y));
endmodule
