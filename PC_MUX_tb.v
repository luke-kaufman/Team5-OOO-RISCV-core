//Testbench for PC_MUX MODULE
`timescale  1ns/1ps
`include "PC_MUX.v"

module PC_MUX_tb;

reg [31:0] Next_PC, Rec_PC, PC;
reg [1:0] sel;

wire [31:0] out;
PC_MUX PC_MUX1(.stall (sel[1]), .recovery(sel[0]), .rec_PC(Rec_PC), .Next_PC(Next_PC), .PC (PC), .out(out));


initial begin
    $dumpfile("PC_MUX_tb.vcd");
    $dumpvars(0, PC_MUX_tb);
    
    Next_PC = 32'hABCD_1500;
    Rec_PC = 32'h3000_AAAA;
    PC = 32'h6000_0000;
    sel = 2'b00;
    #10
    sel = 2'b01;
    #10
    sel = 2'b10;
    #10
    sel = 2'b11;
    #10
$finish;
end
endmodule