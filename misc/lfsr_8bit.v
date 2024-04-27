`ifndef LFSR_V
`define LFSR_V

`include "misc/reg_.v"

module lfsr_8bit (
    input  wire        clk,      // Clock input
    input  wire        init,
    input  wire        rst_aL,    // Asynchronost_aL input
    output reg         out_bit   // Output bit
);
    // reg [7:0] lfsr_reg;  // 8-bit register for LFSR
    // // Feedback polynomial: x^8 + x^6 + x^5 + x^4 + 1
    // // Taps at positions 8, 6, 5, and 4 (1-based indexing)
    // wire feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];
    // // Process to run on every positive edge of clock or negative edge of reset
    // always @(posedge clk or posedge init or negedge rst_aL) begin
    //     if (init) begin
    //         lfsr_reg <= 8'b01000010;
    //     end if (!rst_aL) begin
    //         // Asynchronous reset: Initialize LFSR to a non-zero value
    //         lfsr_reg <= 8'b01000010;  // Example initial value
    //     end else begin
    //         // Shift register right by 1 bit, inject feedback into MSB
    //         lfsr_reg <= {feedback, lfsr_reg[7:1]};
    //     end
    // end
    // // Output the least significant bit of the LFSR
    // always @(posedge clk) begin
    //     out_bit <= lfsr_reg[0];
    // end

    wire [7:0] lfsr_reg_dout;
    wire feedback = lfsr_reg_dout[7] ^ lfsr_reg_dout[5] ^ lfsr_reg_dout[4] ^ lfsr_reg_dout[3];
    reg_ #(
        .WIDTH(8)
    ) lfsr_reg (
        .clk(clk),
        .init(init),
        .rst_aL(rst_aL),
        .flush(),
        .we(1'b1),
        .din({feedback, lfsr_reg_dout[7:1]}),
        .dout(lfsr_reg_dout),
        .init_state(8'b01000010)
    );
    assign out_bit = lfsr_reg_dout[0];

endmodule

`endif
