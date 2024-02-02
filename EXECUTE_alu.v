`timescale 1ns / 1ps

module EXECUTE_alu(
		input		 clk, enable, rst,
		input [31:0] src_1,
		input [31:0] src_2,
		input		 dst_valid,
		input [3:0]  dst_tag,
		input [2:0]  alu_ctrl,
		input		 funct7,
		input		 pred,
		input [31:0] target,

		output reg [31:0] alu_out
	);

	assign data_out = enable ? alu_out : 32'hZ

	if (enable) begin
		always @ (posedge clk) begin
			if (rst) alu_out = 32'h0; // Reset Signal
			else begin // Process alu_out
				case (alu_ctrl)
					3'h0 : alu_out = funct7 ? src_1 - src_2 : src_1 + src_2; // ADD/SUB
					3'h4 : alu_out = src_1 ^ src_2; // XOR
					3'h6 : alu_out = src_1 | src_2; // OR
					3'h7 : alu_out = src_1 & src_2; // AND
					3'h1 : alu_out = src_1 << src_2; // SLL
					3'h5 : alu_out = funct7 ? src_1 >> src_2 | src_1 >> src_2; // SRL/SRA (TODO)
					3'h2 : alu_out = (src_1 < src_2) ? 1 : 0; // SLT
					3'h3 : alu_out = src_1 + src_2; // SLTU (TODO)
					default: 
				endcase
			end
		end
	end

endmodule