`ifndef BITWISE_AND_V
`define BITWISE_AND_V

`include "misc/and/and_.v"

module bitwise_and #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    for (genvar i = 0; i < WIDTH; i++) begin
        and_ #(.N_INS(2)) and_i (
            .a({a[i], b[i]}),
            .y(y[i])
        );
    end
endmodule

`endif
