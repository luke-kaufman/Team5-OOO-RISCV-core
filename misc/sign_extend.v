// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module sign_extend #(
    parameter IN_WIDTH = 1,
    parameter OUT_WIDTH = 32
) (
    input wire [IN_WIDTH-1:0] in,
    output wire [OUT_WIDTH-1:0] out
);
    assign out = {{OUT_WIDTH-IN_WIDTH{in[IN_WIDTH-1]}}, in};
endmodule