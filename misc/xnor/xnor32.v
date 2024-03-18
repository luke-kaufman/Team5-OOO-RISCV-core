// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef XNOR32_V
`define XNOR32_V
`include "freepdk-45nm/stdcells.v"
`include "misc/xnor/xnor16.v"

module xnor32 (
    input wire [31:0] a,
    output wire y
);
    wire xnor0;
    wire xnor1;

    xnor16 xn0(.a(a[0:15]), .ZN(xnor0));
    xnor16 xn1(.a(a[16:31]), .ZN(xnor1));

    XNOR2_X1 xn3(.A1(xnor0), .A2(xnor1), .ZN(y));

endmodule

`endif
