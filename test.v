`include "freepdk-45nm/stdcells.v"
`include "misc/dff_we.v"
`include "misc/reg_.v"

module test (
    input wire clk,
    input wire rst_aL,
    input wire we,
    input wire d,
    output wire q
);
    dff_we dff (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(we),
        .d(d),
        .q(q)
    );

    reg [2**32-1:0] [7:0] mem;

    initial begin
        mem[0] = 8'hFF;
        $display("mem[0] = %h", mem[0]);
        $display("mem[1] = %h", mem[1]);
    end
endmodule