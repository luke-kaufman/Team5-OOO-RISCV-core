`ifndef DFF_WE_V
`define DFF_WE_V

// `include "freepdk-45nm/stdcells.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: FAILING (doesn't reset properly)
module dff_we (
    input wire clk,
    input wire rst_aL,
    input wire we,
    input wire d,
    output wire q
);
    // wire sel_d;
    // wire qn;
    // MUX2_X1 mux(.A(q), .B(d), .S(we), .Z(sel_d));
    // DFFR_X1 dff(.D(sel_d), .RN(rst_aL), .CK(clk), .Q(q), .QN(qn));
    // // FIXME: this doesn't reset properly
    logic q_r;
    always_ff @(posedge clk or negedge rst_aL) begin
        if (!rst_aL) begin
            q_r <= 0;
        end else if (we) begin
            q_r <= d;
        end
    end
    assign q = q_r;
endmodule

`endif
