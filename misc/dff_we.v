// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module dff_we(
    input wire clk,
    input wire rst_aL,
    input wire we,
    input wire d,
    output wire q
);
    wire _d;
    MUX2_X1 mux(.A(q), .B(d), .S(we), .Z(_d));
    DFFR_X1 dff(.D(_d), .RN(rst_aL), .CK(clk), .Q(q));
endmodule