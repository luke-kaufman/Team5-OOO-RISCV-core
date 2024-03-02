// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module or8 (
    input wire [7:0] a,
    output wire y
);
    wire or0;
    wire or1;
    OR4_X1 or_gate0(.A1(a[0]), .A2(a[1]), .A3(a[2]), .A4(a[3]), .ZN(or0[0]));
    OR4_X1 or_gate1(.A1(a[4]), .A2(a[5]), .A3(a[6]), .A4(a[7]), .ZN(or1[0]));
    OR2_X1 or_gate2(.A1(or0[0]), .A2(or0[1]), .ZN(or0[2]));
endmodule
