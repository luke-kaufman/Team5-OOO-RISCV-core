// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module mux #(
    parameter WIDTH = 1,
    parameter N_INS = 2,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [WIDTH-1:0] ins [0:N_INS-1],
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    assign out = ins[sel];
endmodule