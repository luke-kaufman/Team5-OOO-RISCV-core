// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module counter #(
    parameter WIDTH = 1
) (
    input wire clk,
    input wire rst_aL,
    input wire en,
    output wire [WIDTH-1:0] count
);
    wire [WIDTH-1:0] next_count;
    register #(.WIDTH(WIDTH)) ctr (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(en),
        .din(next_count),
        .dout(count)
    );
    wire [WIDTH-1:0] one = 'b1;
    adder #(.WIDTH(WIDTH)) add (
        .a(count),
        .b(one),
        .sum(next_count)
    );
endmodule