`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2024 06:00:39 PM
// Design Name: 
// Module Name: FETCH_pred_nextPC
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


module FETCH_pred_nextPC(
    input[31:0] PC, Instruction,
    output[31:0] nextPC,
    output JALR_stall
    );
    wire enable;
    wire[31:0] Jal_out, BType_out, MUX1_out, MUX2_out;
    ADDER_EN_32in Jal_Add(PC, Instruction, Jal_out);
    ADDER_EN_32in BType_Add(PC, Instruction, BType_out);
    assign MUX1_out = Instruction[31] ? BType_out : PC + 4;
    assign MUX2_out = (Instruction[2] && Instruction [3]) ? Jal_out : MUX1_out;
    assign nextPC = (Instruction[5] && Instruction[6]) ? MUX2_out : PC + 4;
    assign JALR_stall = Instruction[2] && ~Instruction[3];
endmodule
