`include "MUX_4to1_32in.v"

module PC_MUX (
    input recovery, stall,
    input [31:0] rec_PC, Next_PC, PC,
    output [31:0] out
);

MUX_4to1_32in PC_MUX(.sel ({stall, recovery}), 
    .in0 (Next_PC), .in1 (rec_PC), .in2 (PC), .in3 (rec_PC),
    .out (out));
endmodule