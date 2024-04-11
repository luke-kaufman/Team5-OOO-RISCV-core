// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef XOR32_V
`define XOR32_V
// `include "freepdk-45nm/stdcells.v"
`include "misc/xor/xor16.v"

module xor32 (
    input wire [31:0] a,
    output wire y
);
    wire xor0;
    wire xor1;

    xor16 x0(.a(a[0:15]), .ZN(xor0));
    xor16 x1(.a(a[16:31]), .ZN(xor1));

    XOR2_X1 x3(.A1(xor0), .A2(xor1), .ZN(y));

endmodule

`endif
