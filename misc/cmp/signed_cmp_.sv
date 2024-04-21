`ifndef SIGNED_CMP_V
`define SIGNED_CMP_V

module signed_cmp_ #(
    parameter WIDTH = 1
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output eq,
    output lt,
    output ge
);
    assign eq = {31'b0, ($signed(a) == $signed(b))};
    assign lt = {31'b0, ($signed(a) < $signed(b))};
    assign ge = {31'b0, ($signed(a) >= $signed(b))};
endmodule

`endif