// TESTING STATUS: MISSING
module comparator #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire y
);
    wire [WIDTH-1:0] z;

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            XOR2_X1(.A(a[i]), .B(b[i]), .Z(z[i]))
        end
    endgenerate

    
endmodule