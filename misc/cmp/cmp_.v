`ifndef CMP_V
`define CMP_V

module cmp_ #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire eq,
    output wire lt,
    output wire gte
);
    // TODO: implement
    assign eq = (a == b);
    assign lt = (a < b);
    assign gte = (a >= b);
endmodule

`endif
