`ifndef CMP_V
`define CMP_V

module cmp_ #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire y
);
    // TODO: implement
    assign y = (a == b);
endmodule

`endif
