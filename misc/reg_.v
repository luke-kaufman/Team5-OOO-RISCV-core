`ifndef REGISTER_V
`define REGISTER_V

`include "misc/dff_we.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module reg_ #(
    parameter WIDTH = 1
) (
    input wire clk,
    input wire rst_aL,
    input wire we,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);
    for (genvar i = 0; i < WIDTH; i++) begin
        dff_we dff (.clk(clk), .rst_aL(rst_aL), .we(we), .d(din[i]), .q(dout[i]));
    end
endmodule

`endif
