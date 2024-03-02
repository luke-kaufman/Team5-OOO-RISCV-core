`ifndef MUX16_V
`define MUX16_V

`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux16 #(
    parameter WIDTH = 1,
    localparam N_INS = 16,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [N_INS-1:0] [WIDTH-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    // TODO: implement the mux16
    assign out = ins[sel];
endmodule

`endif
