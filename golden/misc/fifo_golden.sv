module fifo_golden #(
    parameter DATA_WIDTH = 32,
    parameter enum {_8=8, _16=16} FIFO_DEPTH = 8,
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH), // = 3 or 4
    localparam CTR_WIDTH = PTR_WIDTH + 1 // = 4 or 5
) (
    input logic clk,
    input logic rst_aL,

    input logic ready_deq,
    input logic valid_enq,
    input logic [DATA_WIDTH-1:0] data_enq,
    
    output logic ready_enq,
    output logic valid_deq,
    output logic [DATA_WIDTH-1:0] data_deq,

    // for debugging
    output logic [PTR_WIDTH-1:0] count
);
    // state elements
    logic [CTR_WIDTH-1:0] enq_ctr_r;
    logic [CTR_WIDTH-1:0] deq_ctr_r;
    logic [FIFO_DEPTH-1:0] [DATA_WIDTH-1:0] fifo_r;
    
    // next state signals
    logic [CTR_WIDTH-1:0] next_enq_ctr;
    logic [CTR_WIDTH-1:0] next_deq_ctr;
    logic [FIFO_DEPTH-1:0] [DATA_WIDTH-1:0] next_fifo;

    // internal signals
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr_r[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] deq_ptr = deq_ctr_r[PTR_WIDTH-1:0];
    wire fifo_empty = enq_ctr_r == deq_ctr_r;
    wire fifo_full = (enq_ctr_r - deq_ctr_r) == FIFO_DEPTH;

    // output drivers
    assign ready_enq = ~fifo_full;
    assign valid_deq = ~fifo_empty;
    assign data_deq = fifo_r[deq_ptr];
    assign count = enq_ctr_r - deq_ctr_r; // for debugging

    // next state logic without dynamic slicing
    assign next_enq_ctr = valid_enq && ready_enq ? enq_ctr_r + 1 : enq_ctr_r;
    assign next_deq_ctr = valid_deq && ready_deq ? deq_ctr_r + 1 : deq_ctr_r;
    // next state logic with dynamic slicing
    always_comb begin
        next_fifo = fifo_r;
        if (valid_enq && ready_enq) begin
            next_fifo[enq_ptr] = data_enq;
        end
    end
    
    // state update
    always_ff @(posedge clk or negedge rst_aL) begin
        if (!rst_aL) begin
            enq_ctr_r <= 0;
            deq_ctr_r <= 0;
            fifo_r <= 0;
        end else begin
            enq_ctr_r <= next_enq_ctr;
            deq_ctr_r <= next_deq_ctr;
            fifo_r <= next_fifo;
        end
    end
endmodule
