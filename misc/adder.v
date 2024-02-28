// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
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
                full_adder fa0(.a(a[0]), .b(b[0]), .cin(cin), .s(sum[0]), .cout(C[0]));
            end else if (i < WIDTH-1) begin
                // Middle full adders, carry-in is the previous carry-out
                full_adder fa(.a(a[i]), .b(b[i]), .cin(C[i-1]), .s(sum[i]), .cout(C[i]));
            end else begin
                // Last full adder, carry-in is the previous carry-out, carry-out is cout
                full_adder fa31(.a(a[WIDTH-1]), .b(b[WIDTH-1]), .cin(C[WIDTH-2]), .s(sum[WIDTH-1]), .cout(cout));
            end
        end
    endgenerate
endmodule