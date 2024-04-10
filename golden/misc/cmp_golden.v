module unsigned_cmp_golden #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire y
);
    assign y = (a == b);
endmodule
