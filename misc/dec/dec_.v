module dec_ #(
    parameter IN_WIDTH = 1
) (
    input wire [IN_WIDTH-1:0] in,
    output wire [2**IN_WIDTH-1:0] out
);
    assign out = 1 << in;
endmodule