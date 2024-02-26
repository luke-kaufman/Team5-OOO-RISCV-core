module instruction_FIFO # (
    parameter FIFO_DEPTH = 8,
    localparam ENTRY_WIDTH = INSTR_WIDTH/*instruction*/ 
                          + ADDR_WIDTH/*PC*/
                          + 1 /*Prediction bit - 1 taken, 0 not taken*/
                          + ADDR_WIDTH/*TARGET PC*/
) (
    input wire icache_hit;
    input wire [INSTR_WIDTH-1:0] enq_instruction;
    output wire [INSTR_WIDTH-1:0] deq_instruction;
    output wire fifo_full_stall;
);

fifo instruction_FIFO # (
    .DATA_WIDTH(ENTRY_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) (
    .clk(clk),
    .rst_aL(rst_aL),
    .ready_enq(),  // output
    .valid_enq(icache_hit), 
    .data_enq(enq_instruction),
    .ready_deq(), 
    .valid_deq(),  // output
    .data_deq(deq_instruction)
);
endmodule