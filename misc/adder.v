// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING

`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.vh"

module adder #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin = 1'b0,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // internal carry wires
    wire [WIDTH-2:0] C;

    // generate the full adders for each bit
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : fa_gen
            if (i == 0) begin
                // First full adder, carry-in is cin
                FA_X1 fa0(.A(a[0]), .B(b[0]), .CI(cin), .S(sum[0]), .CO(C[0]));
            end else if (i < WIDTH-1) begin
                // Middle full adders, carry-in is the previous carry-out
                FA_X1 fa(.A(a[i]), .B(b[i]), .CI(C[i-1]), .S(sum[i]), .CO(C[i]));
            end else begin
                // Last full adder, carry-in is the previous carry-out, carry-out is cout
                FA_X1 fa31(.A(a[WIDTH-1]), .B(b[WIDTH-1]), .CI(C[WIDTH-2]), .S(sum[WIDTH-1]), .CO(cout));
            end
        end
    endgenerate
endmodule