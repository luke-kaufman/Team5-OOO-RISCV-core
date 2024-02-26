// IMPL STATUS: DONE
// TEST STATUS: FAILING
module add32 (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] y,
    output wire cout
);

wire C[30:0]; // Only need 31 carry wires for internal carries

generate
    for (genvar i = 0; i < 32; i = i + 1) begin : fa_gen
        if (i == 0) begin
            // First full adder, carry-in is 0
            fulladder fa0(.a(a[0]), .b(b[0]), .cin(1'b0), .s(y[0]), .cout(C[0]));
        end else if (i < 31) begin
            // Middle full adders, carry-in is the previous carry-out
            fulladder fa(.a(a[i]), .b(b[i]), .cin(C[i-1]), .s(y[i]), .cout(C[i]));
        end else begin
            // Last full adder, carry-in is the previous carry-out, carry-out is cout
            fulladder fa31(.a(a[31]), .b(b[31]), .cin(C[30]), .s(y[31]), .cout(cout));
        end
    end
endgenerate

endmodule