// TESTING STATUS: MISSING
// TODO: complete
module shift_queue #(
  parameter N_ENTRIES = 8,
  parameter ENTRY_WIDTH = 81 /* LSQ Entry width */
) (
    input wire clk,
    input wire rst,
    output wire ready_o,
    input wire valid_i,
    input wire [ENTRY_WIDTH-1:0] data_i,
    input wire ready_i,
    output wire valid_o,
    output wire [ENTRY_WIDTH-1:0] data_o
);

wire [N_ENTRIES1:0][ENTRY_WIDTH-1:0] entry_douts;
generate
    // 8 regs chained together
    for(genvar i = 0; i < N_ENTRIES; i = i + 1) begin : queue
        wire [ENTRY_WIDTH-1:0] din_mux_out;
        mux3 #(ENTRY_WIDTH) din_mux(.d0(ENTRY_WIDTH'0), 
                                    .d1(data_i), 
                                    .d2(i>0 ? queue[i-1].entry.dout : data_i), 
                                    .s1(/*TODO*/), 
                                    .s2(/*TODO*/), 
                                    .y(din_mux_out))
        register #(ENTRY_WIDTH) entry(.clk(clk), .rst(rst), .we(/*TODO*/), .data_i(din_mux_out), .data_o(entry_douts[i]))
    end
endgenerate

mux8 /*TODO*/ output_mux(.d0(ENTRY_WIDTH'0), 
                         .d1(entry_douts[]), 
                         .d2(),
                         .d3(), 
                         .d4(),
                         .d5(), 
                         .d6(), 
                         .d7(), 
                         .s1(/*TODO*/), 
                         .s2(/*TODO*/), 
                         .s3(/*TODO*/), 
                         .y(data_o))

endmodule