// IMPL STATUS: COMPLETE
// TEST STATUS: COMPLETE

`ifndef DEC4_V
`define DEC4_V
`include "freepdk-45nm/stdcells.v"

module dec4(in, out);
    // declare input and output ports
    input [3:0] in;
    output [15:0] out;

	wire [3:0] inv_in;
    for (genvar i = 0; i < 4; i = i + 1) begin
        INV_X1 inv(
            .A(in[i]),
            .ZN(inv_in[i])
        );
    end

	AND4_X1 a0(.A1(inv_in[3]), .A2(inv_in[2]), .A3(inv_in[1]), .A4(inv_in[0]), .ZN(out[0]));
	AND4_X1 a1(.A1(inv_in[3]), .A2(inv_in[2]), .A3(inv_in[1]), .A4(in[0]), .ZN(out[1]));
	AND4_X1 a2(.A1(inv_in[3]), .A2(inv_in[2]), .A3(in[1]), .A4(inv_in[0]), .ZN(out[2]));
	AND4_X1 a3(.A1(inv_in[3]), .A2(inv_in[2]), .A3(in[1]), .A4(in[0]), .ZN(out[3]));

	AND4_X1 a4(.A1(inv_in[3]), .A2(in[2]), .A3(inv_in[1]), .A4(inv_in[0]), .ZN(out[4]));
	AND4_X1 a5(.A1(inv_in[3]), .A2(in[2]), .A3(inv_in[1]), .A4(in[0]), .ZN(out[5]));
	AND4_X1 a6(.A1(inv_in[3]), .A2(in[2]), .A3(in[1]), .A4(inv_in[0]), .ZN(out[6]));
	AND4_X1 a7(.A1(inv_in[3]), .A2(in[2]), .A3(in[1]), .A4(in[0]), .ZN(out[7]));

	AND4_X1 a8(.A1(in[3]), .A2(inv_in[2]), .A3(inv_in[1]), .A4(inv_in[0]), .ZN(out[8]));
	AND4_X1 a9(.A1(in[3]), .A2(inv_in[2]), .A3(inv_in[1]), .A4(in[0]), .ZN(out[9]));
	AND4_X1 a10(.A1(in[3]), .A2(inv_in[2]), .A3(in[1]), .A4(inv_in[0]), .ZN(out[10]));
	AND4_X1 a11(.A1(in[3]), .A2(inv_in[2]), .A3(in[1]), .A4(in[0]), .ZN(out[11]));

	AND4_X1 a12(.A1(in[3]), .A2(in[2]), .A3(inv_in[1]), .A4(inv_in[0]), .ZN(out[12]));
	AND4_X1 a13(.A1(in[3]), .A2(in[2]), .A3(inv_in[1]), .A4(in[0]), .ZN(out[13]));
	AND4_X1 a14(.A1(in[3]), .A2(in[2]), .A3(in[1]), .A4(inv_in[0]), .ZN(out[14]));
	AND4_X1 a15(.A1(in[3]), .A2(in[2]), .A3(in[1]), .A4(in[0]), .ZN(out[15]));

endmodule

`endif
