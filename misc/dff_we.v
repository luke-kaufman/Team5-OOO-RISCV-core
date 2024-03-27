`ifndef DFF_WE_V
`define DFF_WE_V

`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: FAILING (doesn't reset properly)
module dff_we (
    input wire clk,
    input wire rst_aL,
    input wire we,
    input wire d,
    output wire q
);
    wire sel_d;
    wire qn;
    MUX2_X1 mux(.A(q), .B(d), .S(we), .Z(sel_d));
    DFFR_X1 dff(.D(sel_d), .RN(rst_aL), .CK(clk), .Q(q), .QN(qn));
    // FIXME: this doesn't reset properly
endmodule

`endif
