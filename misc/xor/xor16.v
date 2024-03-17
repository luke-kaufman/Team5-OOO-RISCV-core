// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef XOR16_V
`define XOR16_V
`include "freepdk-45nm/stdcells.v"
`include "misc/xor/xor8.v"

module xor16 (
    input wire [15:0] a,
    output wire y
);
    wire xor0;
    wire xor1;

    xor8 x0(.a(a[0:7]), .ZN(xor0));
    xor8 x1(.a(a[8:15]), .ZN(xor1));

    XOR2_X1 x3(.A1(xor0), .A2(xor1), .ZN(y));

endmodule

`endif
