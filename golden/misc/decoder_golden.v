// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module decoder_golden #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] in,
    output wire [2**WIDTH-1:0] out
);
    generate
        for (genvar i = 0; i < 2**WIDTH; i = i + 1) begin
            assign out[i] = (in == i);
        end
    endgenerate
endmodule