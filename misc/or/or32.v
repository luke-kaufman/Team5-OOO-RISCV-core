`ifndef OR32_V
`define OR32_V

`include "misc/or/or16.v"

module or32 (
    input wire [31:0] a,
    output wire y
);
    wire or0;
    wire or1;

    or16 _or0(.a(a[15:0]), .y(or0));
    or16 _or1(.a(a[31:16]), .y(or1));

    OR2_X1 _or_y(.A1(or0), .A2(or1), .ZN(y));
endmodule
`endif
