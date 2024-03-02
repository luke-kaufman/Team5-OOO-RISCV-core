// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module decoder #(
    parameter IN_WIDTH = 1
) (
    input wire [IN_WIDTH-1:0] in,
    output wire [2**IN_WIDTH-1:0] out
);
    generate
        for (genvar i = 0; i < 2**IN_WIDTH; i = i + 1) begin
            assign out[i] = (in == i);
        end
    endgenerate
endmodule