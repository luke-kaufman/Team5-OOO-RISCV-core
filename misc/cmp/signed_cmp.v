`ifndef SIGNED_CMP_V
`define SIGNED_CMP_V

module signed_cmp #(
    parameter WIDTH
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire eq,
    output wire lt,
    output wire ge
);
    assign eq = ($signed(a) == $signed(b));
    assign lt = ($signed(a) < $signed(b));
    assign ge = ($signed(a) >= $signed(b));
endmodule

`endif
