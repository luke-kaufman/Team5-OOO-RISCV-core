`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2024 05:36:02 PM
// Design Name: 
// Module Name: Register_32bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Register_32bit(
    input clock, enable,
    input [31:0] data_in,
    output reg [31:0] data_out
    );
    always @(posedge clock) begin
        if(enable) data_out <= data_in;
    end  
endmodule
