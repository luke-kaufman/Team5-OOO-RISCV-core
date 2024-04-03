`ifndef COUNTER_V
`define COUNTER_V

`include "freepdk-45nm/stdcells.v"
`include "misc/reg_.v"
`include "misc/adder.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module up_counter #(
    parameter WIDTH = 1
) (
    input wire clk,
    // input wire rst_aL, (NOTE: edited to suppress "coerced to input" warning)
    input wire rst_aL,
    input wire inc,
    output wire [WIDTH-1:0] count
);
    wire [WIDTH-1:0] next_count;
    reg_ #(.WIDTH(WIDTH)) counter_reg ( // NOTE: STATEFUL
        .clk(clk),
        .rst_aL(rst_aL),
        .we(inc),
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

`endif
