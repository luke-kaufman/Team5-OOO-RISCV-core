`include "misc/global_defs.svh"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module shift_queue_golden #(
    parameter N_ENTRIES = `IIQ_N_ENTRIES,
    parameter ENTRY_WIDTH = `IIQ_ENTRY_WIDTH,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1
) (
    input wire clk,
    input wire rst_aL,

    // enqueue interface: ready & valid
    output wire enq_ready,
    input wire enq_valid,
    input wire [ENTRY_WIDTH-1:0] enq_data,

    // dequeue interface: select then valid
    input wire deq_ready,
    input wire [N_ENTRIES-1:0] deq_sel_onehot, // can be either one-hot or all 0s
    output wire deq_valid,
    output wire [ENTRY_WIDTH-1:0] deq_data,

    input wire [N_ENTRIES-1:0] wr_en,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] wr_data,

    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts,

    // for testing
    input wire init,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_entry_reg_state,
    input wire [CTR_WIDTH-1:0] init_enq_up_down_counter_state,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] current_entry_reg_state,
    output wire [CTR_WIDTH-1:0] current_enq_up_down_counter_state
);
    // state elements
    logic [CTR_WIDTH-1:0] enq_ctr_r;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] queue_r;

    // next state signals
    logic [CTR_WIDTH-1:0] enq_ctr_next;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] queue_next;

    // internal signals
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr_r[PTR_WIDTH-1:0]; // lower bits of enq_ctr_r
    wire queue_full = enq_ctr_r[PTR_WIDTH]; // MSB of enq_ctr_r
    wire enq = enq_ready && enq_valid;
    wire deq = deq_ready && deq_valid;
    logic [N_ENTRIES-1:0] shift_we_pre;
    always_comb begin
        shift_we_pre[0] = deq_sel_onehot[0];
        for (int i = 1; i < N_ENTRIES; i++) begin
            shift_we_pre[i] = shift_we_pre[i-1] | deq_sel_onehot[i];
        end
    end
    wire [N_ENTRIES-1:0] shift_we = shift_we_pre & {N_ENTRIES{deq}};
    wire [N_ENTRIES-1:0] enq_we_pre = 1 << enq_ptr;
    wire [N_ENTRIES-1:0] enq_we = enq_we_pre & {N_ENTRIES{enq}};
    wire [N_ENTRIES:0] enq_we_ext = {queue_full & enq, enq_we}; // extended enq_we
    wire [N_ENTRIES:0] wr_en_ext = {1'b0, wr_en}; // extended wr_en

    // so, the (one-hot) din_mux of register i chooses between:
    // - 0: entry_douts[i+1] (if shift_we[i] is true AND enq_we_ext[i+1] is false AND wr_en_ext[i+1] is false) (is all 0s if i = N_ENTRIES-1)
    // - 1: enq_data (if shift_we[i] is false and enq_we_ext[i] is true OR shift_we[i] is true and enq_we_ext[i+1] is true)
    // - 2: wr_data[i] (if shift_we[i] is false and wr_en_ext[i] is true)
    // - 3: wr_data[i+1] (if shift_we[i] is true and wr_en_ext[i+1] is true)
    // sel[0] = shift_we[i] & ~enq_we_ext[i+1] & ~wr_en_ext[i+1] (sel_data_behind)
    // sel[1] = ~shift_we[i] & enq_we[i] | shift_we[i] & enq_we_ext[i+1] (sel_enq_data)
    // sel[2] = ~shift_we[i] & wr_en[i] (sel_wr_data)
    // sel[3] = shift_we[i] & wr_en_ext[i+1] (sel_wr_data_behind)
    logic [N_ENTRIES-1:0] sel_data_behind;
    always_comb begin
        for (int i = 0; i < N_ENTRIES; i++) begin
            sel_data_behind[i] = shift_we[i] & ~enq_we_ext[i+1] & ~wr_en_ext[i+1];
        end
    end
    logic [N_ENTRIES-1:0] sel_enq_data;
    always_comb begin
        for (int i = 0; i < N_ENTRIES; i++) begin
            sel_enq_data[i] = ~shift_we[i] & enq_we[i] | shift_we[i] & enq_we_ext[i+1];
        end
    end
    wire [N_ENTRIES-1:0] sel_wr_data = ~shift_we & wr_en;
    logic [N_ENTRIES-1:0] sel_wr_data_behind;
    always_comb begin
        for (int i = 0; i < N_ENTRIES; i++) begin
            sel_wr_data_behind[i] = shift_we[i] & wr_en_ext[i+1];
        end
    end

    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_din;
    always_comb begin
        for (int i = 0; i < N_ENTRIES; i++) begin
            if (sel_data_behind[i]) begin
                entry_din[i] = i < N_ENTRIES-1 ? entry_douts[i+1] : {ENTRY_WIDTH{1'b0}};
            end else if (sel_enq_data[i]) begin
                entry_din[i] = enq_data;
            end else if (sel_wr_data[i]) begin
                entry_din[i] = wr_data[i];
            end else if (sel_wr_data_behind[i]) begin
                entry_din[i] = i < N_ENTRIES-1 ? wr_data[i+1] : {ENTRY_WIDTH{1'b0}};
            end else begin
                entry_din[i] = {ENTRY_WIDTH{1'b0}};
            end
        end
    end

    // combine the select signals to generate the write enable signals for each entry
    wire [N_ENTRIES-1:0] entry_we = sel_data_behind | sel_enq_data | sel_wr_data | sel_wr_data_behind;

    // output drivers
    // if the queue is not full OR there will be a dequeue, then enq_ready is true
    // WARNING: with this implementation, now the enqueue interface depends on the dequeue interface
    // TODO: check this for feasibility
    assign enq_ready = ~queue_full | deq;
    assign deq_valid = |deq_sel_onehot;

    // select the entry to be dequeued from queue_r using the one-hot deq_sel_onehot
    always_comb begin
       for (int i = 0; i < N_ENTRIES; i++) begin
            deq_data = {ENTRY_WIDTH{1'b0}};
            if (deq_sel_onehot[i]) begin
                deq_data = queue_r[i];
                // break; // NOTE: icarus does not support break
            end
       end
    end

    assign entry_douts = queue_r;

    // next state logic
    assign enq_ctr_next = enq_ctr_r + enq - deq;
    always_comb begin
        for (int i = 0; i < N_ENTRIES; i++) begin
            queue_next[i] = entry_we[i] ? entry_din[i] : queue_r[i];
        end
    end

    // state update
    always_ff @(posedge clk or negedge rst_aL or posedge init) begin
        if (!rst_aL) begin
            enq_ctr_r <= 0;
            queue_r <= 0;
        end else if (init) begin
            enq_ctr_r <= init_enq_up_down_counter_state;
            queue_r <= init_entry_reg_state;
        end else begin
            enq_ctr_r <= enq_ctr_next;
            queue_r <= queue_next;
        end
    end

    assign current_entry_reg_state = queue_r;
    assign current_enq_up_down_counter_state = enq_ctr_r;
endmodule
