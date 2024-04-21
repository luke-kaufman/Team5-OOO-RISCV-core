`ifndef BITWISE_or_V
`define BITWISE_or_V

`include "misc/or/or_.v"

module bitwise_or #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    for (genvar i = 0; i < WIDTH; i++) begin
        or_ #(.N_INS(2)) or_i (
            .a({a[i], b[i]}),
            .y(y[i])
        );
    end
endmodule

`endif