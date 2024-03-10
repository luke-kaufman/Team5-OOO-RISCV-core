`ifndef MUX64_V
`define MUX64_V
`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"
`include "misc/and/and8.v"
`include "misc/or/or32.v"

module mux64 #(
    parameter WIDTH = 1
) (
    input wire [63:0][WIDTH-1:0] ins,
    input wire [5:0] sel,
    output wire [WIDTH-1:0] out
 );

    mux32 #(.WIDTH(WIDTH)) mux32_0 (
        .ins(ins[31:0]),
        .sel({1'b0, sel[4:0]})
    );

    mux32 #(.WIDTH(WIDTH)) mux32_1 (
        .ins(ins[63:32]),
        .sel({1'b1, sel[4:0]})
    );

    mux2 #(.WIDTH(WIDTH)) mux2_1 (
        .ins({mux32_0.out, mux32_1.out}),
        .sel(sel[5]),
        .out(out)
    );

endmodule
`endif

