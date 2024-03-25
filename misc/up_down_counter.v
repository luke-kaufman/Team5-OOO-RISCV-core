`ifndef UP_DOWN_COUNTER_V
`define UP_DOWN_COUNTER_V

`include "freepdk-45nm/stdcells.v"
`include "misc/reg_.v"
`include "misc/adder.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module up_down_counter #(
    parameter WIDTH = 1
) (
    input wire clk,
    // input wire rst_aL, (NOTE: edited to suppress "coerced to input" warning)
    input wire rst_aL,
    input wire inc,
    input wire dec,
    // inc = 0, dec = 0: no change (0)
    // inc = 0, dec = 1: decrement (-1)
    // inc = 1, dec = 0: increment (+1)
    // inc = 1, dec = 1: no change (0)
    // use mux4 to select the correct input to the adder
    output wire [WIDTH-1:0] count
);
    wire [WIDTH-1:0] next_count;
    reg_ #(.WIDTH(WIDTH)) ctr (
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
    // TODO: implement the decrement
endmodule

`endif
