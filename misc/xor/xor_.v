`ifndef XOR_V
`define XOR_V

module xor_ #(
    parameter N_INS
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    // FIXME: convert to structural
    assign y = ^a;
endmodule

`endif
