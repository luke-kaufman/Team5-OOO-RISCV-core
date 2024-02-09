`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2024 05:31:07 PM
// Design Name: 
// Module Name: PC_MUX
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


module FETCH_PC_MUX(
    input recovery, stall,
    input [31:0] rec_PC, Next_PC, PC,
    output [31:0] out
    );
    
    MUX_4to1_32in PC_MUX(
    .sel ({stall, recovery}), 
    .in0 (Next_PC), .in1 (rec_PC), .in2 (PC), .in3 (rec_PC),
    .out (out));
      
endmodule
