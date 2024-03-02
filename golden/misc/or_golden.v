`ifndef OR$_GOLDEN_V
`define OR$_GOLDEN_V

module or$_golden #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    assign y = |a;
endmodule

`endif
