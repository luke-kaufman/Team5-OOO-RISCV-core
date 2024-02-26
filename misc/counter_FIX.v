// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module counter #(
    parameter WIDTH = 1
) (
    input wire clk,
    input wire rst_aL,
    input wire en,
    output wire [WIDTH-1:0] count
);
    always @(posedge clk or posedge rst_aL) begin
        if (rst_aL) begin
            count <= 0;
        end else if (en) begin
            count <= count + 1;
        end
    end
endmodule