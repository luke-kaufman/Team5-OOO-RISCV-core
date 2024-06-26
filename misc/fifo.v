`ifndef FIFO_V
`define FIFO_V

`include "misc/inv/inv.v"
`include "misc/and/and_.v"
`include "misc/cmp/unsigned_cmp.v"
`include "misc/dec/dec_.v"
`include "misc/mux/mux_.v"
`include "misc/reg_.v"
`include "misc/up_counter.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module fifo #(
    parameter N_ENTRIES = 8,
    parameter ENTRY_WIDTH = 32,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1 // CTR_WIDTH is PTR_WIDTH + 1 to disambiguate between full and empty conditions
) (
    input wire clk,
    input wire init,
    input wire rst_aL,

    output wire enq_ready,
    input wire enq_valid,
    input wire [ENTRY_WIDTH-1:0] enq_data,

    input wire deq_ready,
    output wire deq_valid,
    output wire [ENTRY_WIDTH-1:0] deq_data,

    input wire flush,

    // for testing
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_entry_reg_state,
    input wire [CTR_WIDTH-1:0] init_enq_up_counter_state,
    input wire [CTR_WIDTH-1:0] init_deq_up_counter_state,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] current_entry_reg_state,
    output wire [CTR_WIDTH-1:0] current_enq_up_counter_state,
    output wire [CTR_WIDTH-1:0] current_deq_up_counter_state
);
    // counter that holds the enqueue pointer
    wire enq;
    wire [CTR_WIDTH-1:0] enq_ctr;
    up_counter #(.WIDTH(CTR_WIDTH)) enq_up_counter ( // NOTE: STATEFUL
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(enq),
        .count(enq_ctr),
        .flush(flush),
        .init(init),
        .init_state(init_enq_up_counter_state)
    );
    // counter that holds the dequeue pointer
    wire deq;
    wire [CTR_WIDTH-1:0] deq_ctr;
    up_counter #(.WIDTH(CTR_WIDTH)) deq_up_counter ( // NOTE: STATEFUL
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(deq),
        .count(deq_ctr),
        .flush(flush),
        .init(init),
        .init_state(init_deq_up_counter_state)
    );

    // comparator that disambiguates between full and empty conditions using the MSB
    wire eq_msb;
    unsigned_cmp #(.WIDTH(1)) eq_msb_cmp (
        .a(enq_ctr[CTR_WIDTH-1]),
        .b(deq_ctr[CTR_WIDTH-1]),
        .eq(eq_msb),
        .lt(),
        .ge()
    );

    // pointers are the lower bits of the counters
    wire [PTR_WIDTH-1:0] enq_ptr;
    wire [PTR_WIDTH-1:0] deq_ptr;
    assign enq_ptr = enq_ctr[PTR_WIDTH-1:0];
    assign deq_ptr = deq_ctr[PTR_WIDTH-1:0];

    // comparator that checks if the enqueue and dequeue pointers are equal (i.e. the fifo is empty or full)
    wire eq_ptr;
    unsigned_cmp #(.WIDTH(PTR_WIDTH)) eq_ptr_cmp (
        .a(enq_ptr),
        .b(deq_ptr),
        .eq(eq_ptr),
        .lt(),
        .ge()
    );

    // logic that checks if the fifo is empty
    wire fifo_empty;
    and_ #(.N_INS(2)) fifo_empty_and (
        .a({eq_msb, eq_ptr}),
        .y(fifo_empty)
    );
    // logic that checks if the fifo is full
    wire not_eq_msb;
    wire fifo_full;
    inv eq_msb_inv (
        .a(eq_msb),
        .y(not_eq_msb)
    );
    and_ #(.N_INS(2)) fifo_full_and (
        .a({not_eq_msb, eq_ptr}),
        .y(fifo_full)
    );

    // logic that checks if the fifo is ready to enqueue
    inv fifo_full_inv (
        .a(fifo_full),
        .y(enq_ready)
    );
    // logic that checks if the fifo is valid to dequeue
    inv fifo_empty_inv (
        .a(fifo_empty),
        .y(deq_valid)
    );

    // logic that drives the enqueue signal using the ready-valid interface
    and_ #(.N_INS(2)) enq_and (
        .a({enq_ready, enq_valid}),
        .y(enq)
    );
    // logic that drives the dequeue signal using the ready-valid interface
    and_ #(.N_INS(2)) deq_and (
        .a({deq_ready, deq_valid}),
        .y(deq)
    );

    // decoder that feeds into the write enable logic for each fifo entry
    wire [N_ENTRIES-1:0] onehot_enq_ptr;
    dec_ #(.IN_WIDTH(PTR_WIDTH)) enq_ptr_dec (
        .in(enq_ptr),
        .out(onehot_enq_ptr)
    );

    // memory that holds fifo entries
    wire [N_ENTRIES-1:0] entry_we;
    wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_dout;
    for (genvar i = 0; i < N_ENTRIES; i = i + 1) begin : entry
        // logic that drives the write enable signal for each fifo entry
        and_ #(.N_INS(2)) entry_we_and (
            .a({onehot_enq_ptr[i], enq}),
            .y(entry_we[i])
        );
        // register that holds each fifo entry
        reg_ #(.WIDTH(ENTRY_WIDTH)) entry_reg ( // NOTE: STATEFUL
            .flush(flush),
            .clk(clk),
            .rst_aL(rst_aL),
            .we(entry_we[i]),
            .din(enq_data),
            .dout(entry_dout[i]),

            .init(init),
            .init_state(init_entry_reg_state[i])
        );
    end

    // mux that drives the dequeue data using the dequeue pointer
    mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_ENTRIES)) deq_data_mux (
        .ins(entry_dout),
        .sel(deq_ptr),
        .out(deq_data)
    );

    assign current_entry_reg_state = entry_dout;
    assign current_enq_up_counter_state = enq_ctr;
    assign current_deq_up_counter_state = deq_ctr;
endmodule

`endif
