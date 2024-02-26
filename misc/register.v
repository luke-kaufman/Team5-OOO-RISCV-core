// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module register #(
    parameter WIDTH = 1
) (
    input wire clk,
    input wire rst_aL,
    input wire we,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            dff_we dff(.clk(clk), .rst_aL(rst_aL), .we(we), .d(din[i]), .q(dout[i]));
        end
    endgenerate
endmodule