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
endmodule