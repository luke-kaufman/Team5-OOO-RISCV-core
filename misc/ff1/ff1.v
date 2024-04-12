`ifndef FF1_V
`define FF1_V

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module ff1 #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    output reg [WIDTH-1:0] y
);
    // // find first 1
    // always @(*) begin
    //     case (a)
    //         8'b???????1: y = 8'00000001;
    //         8'b??????10: y = 8'00000010;
    //         8'b?????100: y = 8'00000100;
    //         8'b????1000: y = 8'00001000;
    //         8'b???10000: y = 8'00010000;
    //         8'b??100000: y = 8'00100000;
    //         8'b?1000000: y = 8'01000000;
    //         8'b10000000: y = 8'10000000;
    //         default: y = 8'00000000;
    //     endcase
    // end
    assign y[0] = a[0];
    for (genvar i = 1; i < WIDTH; i++) begin
        assign y[i] = ~|a[i-1:0] & a[i];
    end
endmodule

`endif
