`ifndef UNSIGNED_CMP_V
`define UNSIGNED_CMP_V

module unsigned_cmp_ #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire eq,
    output wire lt,
    output wire ge
);
    // TODO: implement
    assign eq = (a == b);
    assign lt = (a < b);
    assign ge = (a >= b);
endmodule

`endif
