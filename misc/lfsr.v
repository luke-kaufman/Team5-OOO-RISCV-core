module lfsr_1bit(
    input wire clk,       // Clock input
    input wire reset,     // Reset input
    input wire flush,     // Flush input
    output reg q          // Output bit
);

// On every rising edge of the clock, the output is XOR'ed with a predefined feedback bit.
// Since it's a 1-bit LFSR, it essentially just toggles based on the XOR operation.
always @(posedge clk or posedge reset) begin
    if (reset | flush) begin
        q <= 1'b0; // Initialize the LFSR to 0 on reset
    end else begin
        q <= q ^ 1'b1; // XOR operation for feedback, toggling the bit
    end
end

endmodule