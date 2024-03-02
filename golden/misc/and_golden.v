`ifndef AND_GOLDEN_V
`define AND_GOLDEN_V

module and_golden #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    assign y = &a;
endmodule

`endif
