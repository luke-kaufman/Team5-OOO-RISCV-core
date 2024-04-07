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
    // for (genvar i = 0; i < WIDTH; i++) begin
    //     dff_we dff (.clk(clk), .rst_aL(rst_aL), .we(we), .d(din[i]), .q(dout[i]));
    // end
    logic [WIDTH-1:0] reg_r;
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init) begin
            reg_r <= init_state;
        end else if (!rst_aL) begin
            reg_r <= 0;
        end else if (we) begin
            reg_r <= din;
        end
    end
    assign dout = reg_r;
endmodule

`endif
