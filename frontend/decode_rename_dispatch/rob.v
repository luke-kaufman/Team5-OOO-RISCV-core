module rob #(
    parameter ENTRY_WIDTH = 32,
    localparam ROB_DEPTH = 16,
    localparam N_WRITE_PORTS = 2
) (
    // READY-THEN-VALID INTERFACE TO FETCH
    input wire dispatch_valid, // demanding valid
    output wire dispatch_ready, // helping ready
    input wire [ENTRY_WIDTH-1:0] dispatch_data,
    
    input wire [ROB_DEPTH-1:0] wr_addr0,
    input wire [ROB_DEPTH-1:0] wr_data0,
    input wire [ROB_DEPTH-1:0] wr_addr1
);
    fifo #(13) rob_fifo (
        // .clk(clk),
        // .rst_aL(rst_aL),
        // .ready_enq(),
        // .valid_enq(),
        // .data_enq(),
        // .ready_deq(),
        // .valid_deq(),
        // .data_deq()
    );

endmodule