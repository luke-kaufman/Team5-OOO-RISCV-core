`ifndef MUX_V
`define MUX_V

`include "freepdk-45nm/stdcells.v"
`include "misc/mux/mux2.v"
`include "misc/mux/mux4.v"
`include "misc/mux/mux8.v"
`include "misc/mux/mux16.v"
`include "misc/mux/mux32.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux_ #(
    parameter WIDTH = 2,
    parameter enum { _2=2, _4=4, _8=8, _16=16, _32=32 } N_INS = 2,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [WIDTH-1:0] [N_INS-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    case (N_INS)
        2: mux2 #(.WIDTH(WIDTH)) mux (
            .ins(ins),
            .sel(sel),
            .out(out)
        );
        4: mux4 #(.WIDTH(WIDTH)) mux (
            .ins(ins),
            .sel(sel),
            .out(out)
        );
        8: mux8 #(.WIDTH(WIDTH)) mux (
            .ins(ins),
            .sel(sel),
            .out(out)
        );
        16: mux16 #(.WIDTH(WIDTH)) mux (
            .ins(ins),
            .sel(sel),
            .out(out)
        );
        32: mux32 #(.WIDTH(WIDTH)) mux (
            .ins(ins),
            .sel(sel),
            .out(out)
        );
    endcase
endmodule

`endif
