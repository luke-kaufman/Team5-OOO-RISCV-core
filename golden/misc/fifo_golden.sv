module fifo_golden #(
    parameter ENTRY_WIDTH = 32,
    parameter N_ENTRIES = 8,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1
) (
    input logic clk,
    input logic rst_aL,

    output logic enq_ready,
    input logic enq_valid,
    input logic [ENTRY_WIDTH-1:0] enq_data,

    input logic deq_ready,
    output logic deq_valid,
    output logic [ENTRY_WIDTH-1:0] deq_data,

    // for testing
    input wire init,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_entry_reg_state,
    input wire [CTR_WIDTH-1:0] init_enq_up_counter_state,
    input wire [CTR_WIDTH-1:0] init_deq_up_counter_state,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] current_entry_reg_state,
    output wire [CTR_WIDTH-1:0] current_enq_up_counter_state,
    output wire [CTR_WIDTH-1:0] current_deq_up_counter_state
);
    // state elements
    logic [CTR_WIDTH-1:0] enq_ctr_r;
    logic [CTR_WIDTH-1:0] deq_ctr_r;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] fifo_r;

    // next state signals
    logic [CTR_WIDTH-1:0] enq_ctr_next;
    logic [CTR_WIDTH-1:0] deq_ctr_next;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] fifo_next;

    // internal signals
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr_r[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] deq_ptr = deq_ctr_r[PTR_WIDTH-1:0];
    wire fifo_empty = enq_ctr_r == deq_ctr_r;
    wire fifo_full = (enq_ctr_r[PTR_WIDTH] != deq_ctr_r[PTR_WIDTH]) && (enq_ctr_r[PTR_WIDTH-1:0] == deq_ctr_r[PTR_WIDTH-1:0]);

    // output drivers
    assign enq_ready = ~fifo_full;
    assign deq_valid = ~fifo_empty;
    assign deq_data = fifo_r[deq_ptr];

    // next state logic without dynamic slicing
    assign enq_ctr_next = enq_valid && enq_ready ? enq_ctr_r + 1 : enq_ctr_r;
    assign deq_ctr_next = deq_valid && deq_ready ? deq_ctr_r + 1 : deq_ctr_r;
    // next state logic with dynamic slicing
    always_comb begin
        fifo_next = fifo_r;
        if (enq_valid && enq_ready) begin
            fifo_next[enq_ptr] = enq_data;
        end
    end

    // state update
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init) begin
            enq_ctr_r <= init_enq_up_counter_state;
            deq_ctr_r <= init_deq_up_counter_state;
            fifo_r <= init_entry_reg_state;
        end else if (!rst_aL) begin
            enq_ctr_r <= 0;
            deq_ctr_r <= 0;
            fifo_r <= 0;
        end else begin
            enq_ctr_r <= enq_ctr_next;
            deq_ctr_r <= deq_ctr_next;
            fifo_r <= fifo_next;
        end
    end

    assign current_entry_reg_state = fifo_r;
    assign current_enq_up_counter_state = enq_ctr_r;
    assign current_deq_up_counter_state = deq_ctr_r;
endmodule
