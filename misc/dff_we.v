// TESTING STATUS: MISSING
module dff_we(
    input wire clk,
    input wire rst,
    input wire we,
    input wire d,
    output wire q
);
    wire _d;
    MUX2_X1 mux(.A(q), .B(d), .S(we), .Z(_d));
    // WARNING: ACTIVE LOW RESET
    DFFR_X1 dff(.D(_d), .RN(rst), .CK(clk), .Q(q));
endmodule