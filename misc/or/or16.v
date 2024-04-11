// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef OR16_V
`define OR16_V
// `include "freepdk-45nm/stdcells.v"
`include "misc/or/or8.v"

module or16 (
    input wire [15:0] a,
    output wire y
);
    wire or0;
    wire or1;

    or8 o0(.a(a[0:7]), .ZN(or0));
    or8 o1(.a(a[8:15]), .ZN(or1));

    OR2_X1 o3(.A1(or0), .A2(or1), .ZN(y));

endmodule

`endif
