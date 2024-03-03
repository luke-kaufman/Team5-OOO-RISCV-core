`ifndef SHIFT_QUEUE_V
`define SHIFT_QUEUE_V

`include "misc/register.v"
`include "misc/counter.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module shift_queue #(
    parameter N_ENTRIES = 8,
    parameter ENTRY_WIDTH = 81, /* LSQ Entry width */
    localparam PTR_WIDTH = $clog2(N_ENTRIES)
) (
    input wire clk,
    input wire rst_aL,

    output wire enqueue_ready,
    input wire enqueue_valid,
    input wire [ENTRY_WIDTH-1:0] enqueue_data,

    input wire dequeue_ready,
    output wire dequeue_valid,
    output wire [ENTRY_WIDTH-1:0] dequeue_data,
    input wire [N_ENTRIES-1:0] dequeue_select_onehot,

    input wire [N_ENTRIES-1:0] entry_wes,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_dins,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts
);
    // state elements
    counter #(.WIDTH(PTR_WIDTH)) enq_ptr_r (
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(),
        .count(enq_ptr)
    );
    for (genvar i = 0; i < N_ENTRIES; i++) begin : queue
        register #(.WIDTH(ENTRY_WIDTH)) entry_r (
            .clk(clk),
            .rst_aL(rst_aL),
            .we(),
            .din(),
            .dout(entry_douts[i])
        );
    end

    // internal signals
    wire [PTR_WIDTH-1:0] enq_ptr;
    

    // output drivers
    assign enqueue_ready = (enq_ptr == 0);
endmodule

`endif
