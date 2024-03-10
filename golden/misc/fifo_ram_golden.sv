module fifo_ram_golden #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8,
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH),
    localparam CTR_WIDTH = PTR_WIDTH + 1,

    // RAM parameters
    parameter N_READ_PORTS = 2,
    parameter N_WRITE_PORTS = 2
) (
    input logic clk,
    input logic rst_aL,

    output logic enq_ready,
    input logic enq_valid,
    input logic [DATA_WIDTH-1:0] enq_data,
    
    input logic deq_ready,
    output logic deq_valid,
    output logic [DATA_WIDTH-1:0] deq_data,

    input logic [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr,
    output logic [N_READ_PORTS-1:0] [DATA_WIDTH-1:0] rd_data,
    input logic [N_WRITE_PORTS-1:0] wr_en,
    input logic [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr,
    input logic [N_WRITE_PORTS-1:0] [DATA_WIDTH-1:0] wr_data,

    output logic [FIFO_DEPTH-1:0] [DATA_WIDTH-1:0] fifo_state, // for updating entries by partial writes

    output logic [PTR_WIDTH-1:0] count // for debugging
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
    assign enq_ready = ~fifo_full;
    assign deq_valid = ~fifo_empty;
    assign deq_data = fifo_r[deq_ptr];
    for (genvar i = 0; i < N_READ_PORTS; i++) begin
        assign rd_data[i] = fifo_r[rd_addr[i]];
    end
    assign fifo_state = fifo_r;
    assign count = enq_ctr_r - deq_ctr_r; // for debugging

    // next state logic without dynamic slicing
    assign next_enq_ctr = enq_valid && enq_ready ? enq_ctr_r + 1 : enq_ctr_r;
    assign next_deq_ctr = deq_valid && deq_ready ? deq_ctr_r + 1 : deq_ctr_r;
    // next state logic with dynamic slicing
    always_comb begin
        next_fifo = fifo_r;
        if (enq_valid && enq_ready) begin
            next_fifo[enq_ptr] = enq_data;
        end
        for (int i = 0; i < N_WRITE_PORTS; i++) begin
            if (wr_en[i]) begin
                next_fifo[wr_addr[i]] = wr_data[i];
            end
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
