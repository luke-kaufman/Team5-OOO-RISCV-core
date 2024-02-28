// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module mux8 #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] d0;
    input wire [WIDTH-1:0] d1;
    input wire [WIDTH-1:0] d2;
    input wire [WIDTH-1:0] d3;
    input wire [WIDTH-1:0] d4;
    input wire [WIDTH-1:0] d5;
    input wire [WIDTH-1:0] d6;
    input wire [WIDTH-1:0] d7;
    input wire [3:0] s;
    output wire [WIDTH-1:0] y
);
endmodule