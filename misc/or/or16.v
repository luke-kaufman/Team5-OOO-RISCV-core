`ifndef OR16_V
`define OR16_V

`include "misc/or/or8.v"

module or16 (
    input wire [15:0] a,
    output wire y
);
    wire or0;
    wire or1;

    or8 _or0(.a(a[7:0]), .y(or0));
    or8 _or1(.a(a[15:8]), .y(or1));

    OR2_X1 _or_y(.A1(or0), .A2(or1), .ZN(y));
endmodule

`endif
