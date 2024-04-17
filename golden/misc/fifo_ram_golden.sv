module fifo_ram_golden #(
    parameter  int unsigned ENTRY_WIDTH = 32,
    parameter  int unsigned N_ENTRIES = 8,
    localparam int unsigned PTR_WIDTH = $clog2(N_ENTRIES),
    localparam int unsigned CTR_WIDTH = PTR_WIDTH + 1,
    parameter N_READ_PORTS = 2,
    parameter N_WRITE_PORTS = 2 // NOTE: all writes are assumed to be to separate entries
) (
    input logic clk,
    input logic rst_aL,

    output logic enq_ready,
    input logic enq_valid,
    input logic [ENTRY_WIDTH-1:0] enq_data,
    output logic [PTR_WIDTH-1:0] enq_addr, // to get the ROB tail ID for dispatch


    input logic deq_ready,
    output logic deq_valid,
    output logic [ENTRY_WIDTH-1:0] deq_data,
    output logic [PTR_WIDTH-1:0] deq_addr, // to get the ROB head ID for retirement

    input logic [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr,
    output logic [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data,

    input logic [N_WRITE_PORTS-1:0] wr_en,
    input logic [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr,
    input logic [N_ENTRIES-1:0] [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data,
    output logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts, // for updating entries by partial writes

    input logic init,
    input logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_entry_reg_state,
    input logic [CTR_WIDTH-1:0] init_enq_up_counter_state,
    input logic [CTR_WIDTH-1:0] init_deq_up_counter_state,
    output logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] current_entry_reg_state,
    output logic [CTR_WIDTH-1:0] current_enq_up_counter_state,
    output logic [CTR_WIDTH-1:0] current_deq_up_counter_state
);
    // state elements
    logic [CTR_WIDTH-1:0] enq_ctr_r;
    logic [CTR_WIDTH-1:0] deq_ctr_r;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] fifo_r;

    // next state signals
    logic [CTR_WIDTH-1:0] next_enq_ctr;
    logic [CTR_WIDTH-1:0] next_deq_ctr;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] next_fifo;

    // internal signals
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr_r[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] deq_ptr = deq_ctr_r[PTR_WIDTH-1:0];
    wire fifo_empty = enq_ctr_r == deq_ctr_r;
    wire fifo_full = (enq_ctr_r[PTR_WIDTH] != deq_ctr_r[PTR_WIDTH]) && (enq_ctr_r[PTR_WIDTH-1:0] == deq_ctr_r[PTR_WIDTH-1:0]);

    // output drivers
    assign enq_addr = enq_ptr;
    assign deq_addr = deq_ptr;
    assign enq_ready = ~fifo_full;
    assign deq_valid = ~fifo_empty;
    assign deq_data = fifo_r[deq_ptr];
    for (genvar i = 0; i < N_READ_PORTS; i++) begin
        assign rd_data[i] = fifo_r[rd_addr[i]];
    end
    assign entry_douts = fifo_r;

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
                next_fifo[wr_addr[i]] = wr_data[wr_addr[i]][i];
            end
        end
    end

    // state update
    always_ff @(posedge clk or negedge rst_aL or posedge init) begin
        if(init) begin
            enq_ctr_r <= init_enq_up_counter_state;
            deq_ctr_r <= init_deq_up_counter_state;
            fifo_r <= init_entry_reg_state;
        end else
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

    // for testing
    assign current_entry_reg_state = fifo_r;
    assign current_enq_up_counter_state = enq_ctr_r;
    assign current_deq_up_counter_state = deq_ctr_r;
endmodule
