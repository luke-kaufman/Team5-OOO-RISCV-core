`ifndef SIGNED_CMP_V
`define SIGNED_CMP_V

module signed_cmp_ #(
    parameter WIDTH = 1
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] eq,
    output [WIDTH-1:0] lt,
    output [WIDTH-1:0] ge
);
    assign eq = ($signed(a) == $signed(b));
    assign lt = ($signed(a) < $signed(b));
    assign ge = ($signed(a) >= $signed(b));
endmodule

`endif