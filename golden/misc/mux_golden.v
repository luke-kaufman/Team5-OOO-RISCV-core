`ifndef MUX_GOLDEN_V
`define MUX_GOLDEN_V

module mux_golden #(parameter N_INS = 2, parameter WIDTH = 8, localparam SEL_WIDTH = $clog2(N_INS))
    (
     input wire [N_INS-1:0][WIDTH-1:0] ins,
     input wire [SEL_WIDTH-1:0] sel,
     output wire [WIDTH-1:0] out
    );

    assign out = ins[sel];

endmodule

`endif
