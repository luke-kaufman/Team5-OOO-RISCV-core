`ifndef DEC_V
`define DEC_V

module dec_ #(
    parameter IN_WIDTH = 1,
    localparam OUT_WIDTH = 2**IN_WIDTH
) (
    input wire [IN_WIDTH-1:0] in,
    output wire [OUT_WIDTH-1:0] out
);
    assign out = 1 << in;
endmodule

`endif
