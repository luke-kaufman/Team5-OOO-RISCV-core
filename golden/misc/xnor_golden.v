`ifndef XNOR_GOLDEN_V
`define XNOR_GOLDEN_V

module xnor_golden #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    assign y = ~(^a);
endmodule

`endif