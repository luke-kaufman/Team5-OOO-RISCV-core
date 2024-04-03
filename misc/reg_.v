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
    output wire [WIDTH-1:0] dout,

    // for testing
    input wire init,
    input wire [WIDTH-1:0] init_state
);
    for (genvar i = 0; i < WIDTH; i++) begin
        dff_we dff (.clk(clk), .rst_aL(rst_aL), .we(we), .d(din[i]), .q(dout[i]));
    end

    always @(posedge init) begin
        force we = 1'b1;
        force din = init_state;
    end
endmodule

`endif
