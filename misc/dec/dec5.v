// IMPL STATUS: COMPLETE
// TEST STATUS: INCOMPLETE

`ifndef DEC5_V
`define DEC5_V
`include "freepdk-45nm/stdcells.v"

module dec5(in, out);
    // declare input and output ports
    input [4:0] in;
    output [31:0] out;

	wire [4:0] inv_in;
    for (genvar i = 0; i < 5; i = i + 1) begin
        INV_X1 inv(
            .A(in[i]),
            .ZN(inv_in[i])
        );
    end

	wire [15:0] doub;

	AND4_X1(.A(inv_in[3]), .B(inv_in[2]), .C(inv_in[1]), .D(inv_in[0]), .ZN(doub[0]));
	AND4_X1(.A(inv_in[3]), .B(inv_in[2]), .C(inv_in[1]), .D(in[0]), .ZN(doub[1]));
	AND4_X1(.A(inv_in[3]), .B(inv_in[2]), .C(in[1]), .D(inv_in[0]), .ZN(doub[2]));
	AND4_X1(.A(inv_in[3]), .B(inv_in[2]), .C(in[1]), .D(in[0]), .ZN(doub[3]));

	AND4_X1(.A(inv_in[3]), .B(in[2]), .C(inv_in[1]), .D(inv_in[0]), .ZN(doub[4]));
	AND4_X1(.A(inv_in[3]), .B(in[2]), .C(inv_in[1]), .D(in[0]), .ZN(doub[5]));
	AND4_X1(.A(inv_in[3]), .B(in[2]), .C(in[1]), .D(inv_in[0]), .ZN(doub[6]));
	AND4_X1(.A(inv_in[3]), .B(in[2]), .C(in[1]), .D(in[0]), .ZN(doub[7]));

	AND4_X1(.A(in[3]), .B(inv_in[2]), .C(inv_in[1]), .D(inv_in[0]), .ZN(doub[8]));
	AND4_X1(.A(in[3]), .B(inv_in[2]), .C(inv_in[1]), .D(in[0]), .ZN(doub[9]));
	AND4_X1(.A(in[3]), .B(inv_in[2]), .C(in[1]), .D(inv_in[0]), .ZN(doub[10]));
	AND4_X1(.A(in[3]), .B(inv_in[2]), .C(in[1]), .D(in[0]), .ZN(doub[11]));

	AND4_X1(.A(in[3]), .B(in[2]), .C(inv_in[1]), .D(inv_in[0]), .ZN(doub[12]));
	AND4_X1(.A(in[3]), .B(in[2]), .C(inv_in[1]), .D(in[0]), .ZN(doub[13]));
	AND4_X1(.A(in[3]), .B(in[2]), .C(in[1]), .D(inv_in[0]), .ZN(doub[14]));
	AND4_X1(.A(in[3]), .B(in[2]), .C(in[1]), .D(in[0]), .ZN(doub[15]));

	for (genvar i = 0; i < 16; i++) begin
		AND2_X1(.A(doub[i]), .B(inv_in[4]), .ZN(out[i]))
	end

	for (genvar i = 16; i < 32; i++) begin
		AND2_X1(.A(doub[i - 16]), .B(in[4]), .ZN(out[i]))
	end

endmodule