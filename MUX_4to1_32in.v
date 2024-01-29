`timescale 1ns / 1ps

module MUX_4to1_32in(
    input [1:0] sel,
    input [31:0] in0, in1, in2, in3,
    output reg [31:0] out
);
always @(in0, in1, in2, in3, sel) begin
    case(sel)
        2'b00 : out <= in0;
        2'b01 : out <= in1;
        2'b10 : out <= in2;
        2'b11 : out <= in3;
    endcase
end
endmodule