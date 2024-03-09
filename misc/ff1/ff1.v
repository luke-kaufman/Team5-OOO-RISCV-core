// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module ff1 #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] d,   // Data input
    output reg [WIDTH-1:0] q    // Data output
);
    // // find first 1
    // always @(*) begin
    //     case (d)
    //         8'b???????1: q = 8'00000001;
    //         8'b??????10: q = 8'00000010;
    //         8'b?????100: q = 8'00000100;
    //         8'b????1000: q = 8'00001000;
    //         8'b???10000: q = 8'00010000;
    //         8'b??100000: q = 8'00100000;
    //         8'b?1000000: q = 8'01000000;
    //         8'b10000000: q = 8'10000000;
    //         default: q = 8'00000000;
    //     endcase
    // end
    assign q[0] = d[0];
    for (genvar i = 1; i < WIDTH; i++) begin
        assign q[i] = ~|d[i-1:0] & d[i];
    end
endmodule
