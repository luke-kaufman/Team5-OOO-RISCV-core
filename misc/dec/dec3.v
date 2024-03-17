// IMPL STATUS: COMPLETE
// TEST STATUS: COMPLETE

`ifndef DEC3_V
`define DEC3_V
`include "freepdk-45nm/stdcells.v"

module dec3(in, out);
    // declare input and output ports
    input [2:0] in;
    output [7:0] out;

	wire [2:0] inv_in;
    for (genvar i = 0; i < 3; i = i + 1) begin
        INV_X1 inv(
            .A(in[i]),
            .ZN(inv_in[i])
        );
    end

	AND3_X1 a0(.A1(inv_in[2]), .A2(inv_in[1]), .A3(inv_in[0]), .ZN(out[0]));
	AND3_X1 a1(.A1(inv_in[2]), .A2(inv_in[1]), .A3(in[0]), .ZN(out[1]));
	AND3_X1 a2(.A1(inv_in[2]), .A2(in[1]), .A3(inv_in[0]), .ZN(out[2]));
	AND3_X1 a3(.A1(inv_in[2]), .A2(in[1]), .A3(in[0]), .ZN(out[3]));

	AND3_X1 a4(.A1(in[2]), .A2(inv_in[1]), .A3(inv_in[0]), .ZN(out[4]));
	AND3_X1 a5(.A1(in[2]), .A2(inv_in[1]), .A3(in[0]), .ZN(out[5]));
	AND3_X1 a6(.A1(in[2]), .A2(in[1]), .A3(inv_in[0]), .ZN(out[6]));
	AND3_X1 a7(.A1(in[2]), .A2(in[1]), .A3(in[0]), .ZN(out[7]));

endmodule

`endif
