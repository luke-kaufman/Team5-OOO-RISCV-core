module Or #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] ins,
    output wire out
);
    assign out = |ins;
endmodule