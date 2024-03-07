`ifndef EXTEND_FIRST1_V
`define EXTEND_FIRST1_V

`include "misc/or/or_.v"

module extend_first1 #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    output wire [WIDTH-1:0] y
);
    // 0000 -> 0000
    // 0001 -> 1111
    // 0010 -> 1110
    // 0100 -> 1100
    // 1000 -> 1000
    assign y[0] = a[0];
    for (genvar i = 1; i < WIDTH; i++) begin
        or_ #(.N_INS(2)) or_gate (
            .a({a[i], y[i-1]}),
            .y(y[i])
        );
    end
endmodule

`endif
