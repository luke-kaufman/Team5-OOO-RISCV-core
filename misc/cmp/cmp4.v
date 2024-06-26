// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module cmp4 (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire y
);
    wire [3:0] xors;
    wire [3:0] xnors;

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            // TODO: use XNOR2_X1 instead
            XOR2_X1 xor_gate(.A(a[i]), .B(b[i]), .Z(xors[i]));
            INV_X1 inv_gate(.A(xors[i]), .ZN(xnors[i]));
        end
    endgenerate

    AND4_X1 and_gate(.A1(xnors[0]), .A2(xnors[1]), .A3(xnors[2]), .A4(xnors[3]), .ZN(y));
endmodule