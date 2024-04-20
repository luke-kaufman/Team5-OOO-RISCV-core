module lfsr_8bit (
    input  wire        clk,      // Clock input
    input  wire        rst_aL,    // Asynchronost_aL input
    input  wire        init,
    output reg         out_bit   // Output bit
);

    reg [7:0] lfsr_reg;  // 8-bit register for LFSR

    // Feedback polynomial: x^8 + x^6 + x^5 + x^4 + 1
    // Taps at positions 8, 6, 5, and 4 (1-based indexing)
    wire feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];

    // Process to run on every positive edge of clock or negative edge of reset
    always @(posedge clk or posedge init or negedge rst_aL) begin
        if (init) begin
            lfsr_reg <= 8'b0100_0010;
        end if (!rst_aL) begin
            // Asynchronous reset: Initialize LFSR to a non-zero value
            lfsr_reg <= 8'b0100_0010;  // Example initial value
        end else begin
            // Shift register right by 1 bit, inject feedback into MSB
            lfsr_reg <= {feedback, lfsr_reg[7:1]};
        end
    end

    // Output the least significant bit of the LFSR
    always @(posedge clk) begin
        out_bit <= lfsr_reg[0];
    end

endmodule
