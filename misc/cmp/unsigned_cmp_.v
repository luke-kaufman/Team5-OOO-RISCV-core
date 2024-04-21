`ifndef UNSIGNED_CMP_V
`define UNSIGNED_CMP_V

module unsigned_cmp_ #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] eq,
    output wire [WIDTH-1:0] lt,
    output wire [WIDTH-1:0] ge
);
    // TODO: implement
    assign eq = {31'b0, (a == b)};
    assign lt = {31'b0, (a < b)};
    assign ge = {31'b0, (a >= b)};
endmodule

`endif
