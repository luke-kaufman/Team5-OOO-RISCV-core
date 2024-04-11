// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef XOR8_V
`define XOR8_V
// `include "freepdk-45nm/stdcells.v"

module xor8 (
    input wire [7:0] a,
    output wire y
);
    wire xor0;
    wire xor1;
	wire xor2;
    wire xor3;

    XOR2_X1 x0(.A1(a[0]), .A2(a[1]), .ZN(xor0));
    XOR2_X1 x1(.A1(a[2]), .A2(a[3]), .ZN(xor1));
    XOR2_X1 x2(.A1(a[4]), .A2(a[5]), .ZN(xor2));
    XOR2_X1 x3(.A1(a[6]), .A2(a[7]), .ZN(xor3));

	wire xor4;
	wire xor5;

	XOR2_X1 x4(.A1(xor0), .A2(xor1), .ZN(xor4));
    XOR2_X1 x5(.A1(xor2), .A2(xor3), .ZN(xor5));

    XOR2_X1 x6(.A1(xor4), .A2(xor5), .ZN(y));

endmodule

`endif
