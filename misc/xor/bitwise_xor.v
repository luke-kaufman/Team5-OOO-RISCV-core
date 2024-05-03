`ifndef BITWISE_xor_V
`define BITWISE_xor_V

`include "misc/xor/xor_.v"

module bitwise_xor #(
    parameter WIDTH
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    for (genvar i = 0; i < WIDTH; i++) begin
        xor_ #(.N_INS(2)) xor_i (
            .a({a[i], b[i]}),
            .y(y[i])
        );
    end
endmodule

`endif
