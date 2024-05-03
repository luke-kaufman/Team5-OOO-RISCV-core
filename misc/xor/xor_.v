`ifndef XOR_V
`define XOR_V

module xor_ #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    // TODO: implement
    assign y = ^a;
endmodule

`endif