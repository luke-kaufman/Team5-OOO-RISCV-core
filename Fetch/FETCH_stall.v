`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2024 05:49:51 PM
// Design Name: 
// Module Name: FETCH_stall
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


module FETCH_stall(
    input I_Cache_miss, JALR_Stall, I_FIFO_Full,
    output F_stall
    );
    assign F_stall = I_Cache_miss || JALR_Stall || I_FIFO_Full;
endmodule
