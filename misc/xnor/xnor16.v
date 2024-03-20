// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef XNOR16_V
`define XNOR16_V
`include "freepdk-45nm/stdcells.v"
`include "misc/xnor/xnor8.v"

module xnor16 (
    input wire [15:0] a,
    output wire y
);
    wire xnor0;
    wire xnor1;

    xnor8 xn0(.a(a[0:7]), .ZN(xnor0));
    xnor8 xn1(.a(a[8:15]), .ZN(xnor1));

    XNOR2_X1 xn3(.A1(xnor0), .A2(xnor1), .ZN(y));

endmodule

`endif
