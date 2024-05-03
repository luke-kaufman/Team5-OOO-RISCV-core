`ifndef OR8_V
`define OR8_V

module or8 (
    input wire [7:0] a,
    output wire y
);
    wire or0;
    wire or1;

    OR4_X1 _or0(.A1(a[0]), .A2(a[1]), .A3(a[2]), .A4(a[3]), .ZN(or0));
    OR4_X1 _or1(.A1(a[4]), .A2(a[5]), .A3(a[6]), .A4(a[7]), .ZN(or1));

    OR2_X1 _or_y(.A1(or0), .A2(or1), .ZN(y));
endmodule

`endif
