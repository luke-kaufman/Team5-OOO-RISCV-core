// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`ifndef XNOR8_V
`define XNOR8_V
// `include "freepdk-45nm/stdcells.v"

module xnor8 (
    input wire [7:0] a,
    output wire y
);
    wire xnor0;
    wire xnor1;
	wire xnor2;
    wire xnor3;

    XNOR2_X1 xn0(.A1(a[0]), .A2(a[1]), .ZN(xnor0));
    XNOR2_X1 xn1(.A1(a[2]), .A2(a[3]), .ZN(xnor1));
    XNOR2_X1 xn2(.A1(a[4]), .A2(a[5]), .ZN(xnor2));
    XNOR2_X1 xn3(.A1(a[6]), .A2(a[7]), .ZN(xnor3));

	wire xnor4;
	wire xnor5;

	XNOR2_X1 xn4(.A1(xnor0), .A2(xnor1), .ZN(xnor4));
    XNOR2_X1 xn5(.A1(xnor2), .A2(xnor3), .ZN(xnor5));

    XNOR2_X1 xn6(.A1(xnor4), .A2(xnor5), .ZN(y));

endmodule

`endif
