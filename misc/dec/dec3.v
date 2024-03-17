// IMPL STATUS: COMPLETE
// TEST STATUS: INCOMPLETE

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

	AND3_X1(.A(inv_in[2]), .B(inv_in[1]), .C(inv_in[0]), .ZN(out[0]));
	AND3_X1(.A(inv_in[2]), .B(inv_in[1]), .C(in[0]), .ZN(out[1]));
	AND3_X1(.A(inv_in[2]), .B(in[1]), .C(inv_in[0]), .ZN(out[2]));
	AND3_X1(.A(inv_in[2]), .B(in[1]), .C(in[0]), .ZN(out[3]));

	AND3_X1(.A(in[2]), .B(inv_in[1]), .C(inv_in[0]), .ZN(out[4]));
	AND3_X1(.A(in[2]), .B(inv_in[1]), .C(in[0]), .ZN(out[5]));
	AND3_X1(.A(in[2]), .B(in[1]), .C(inv_in[0]), .ZN(out[6]));
	AND3_X1(.A(in[2]), .B(in[1]), .C(in[0]), .ZN(out[7]));

endmodule