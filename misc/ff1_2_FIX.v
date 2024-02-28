module ff1_2 (
    input wire [1:0] d,   // Data input
    output reg [1:0] q    // Data output
);
    // find first 1
    always @(*) begin
        case (d)
            2'b?1: q = 2'01;
            2'b10: q = 2'10;
            default: q = 2'00;
        endcase
    end
endmodule