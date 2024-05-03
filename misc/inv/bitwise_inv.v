`ifndef BITWISE_INV_V
`define BITWISE_INV_V

`include "misc/inv/inv.v"

module bitwise_inv #(
    parameter WIDTH
) (
    input wire [WIDTH-1:0] a,
    output wire [WIDTH-1:0] y
);
    for (genvar i = 0; i < WIDTH; i = i + 1) begin
        inv _inv (
            .a(a[i]),
            .y(y[i])
        );
    end
endmodule

`endif
