`ifndef SHIFT_QUEUE_V
`define SHIFT_QUEUE_V

`include "misc/register.v"
`include "misc/up_down_counter.v"
`include "misc/cmp/cmp_.v"
`include "misc/onehot_mux/onehot_mux_.v"
`include "misc/dec/dec_.v"
`include "misc/and/and_.v"
`include "misc/or/or_.v"
`include "misc/extend_first1.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module shift_queue #(
    parameter N_ENTRIES = 8,
    parameter ENTRY_WIDTH = 81, /* LSQ Entry width */
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1
) (
    input wire clk,
    // input wire rst_aL, (NOTE: edited to suppress "coerced to inout" warning)
    inout wire rst_aL,

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

    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts
);
    // internal signal
    wire [CTR_WIDTH-1:0] enq_ctr; // one bit wider than the pointer width to allow for the full condition (we can still enqueue to the queue when it is full if there will be a dequeue in the same cycle)
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr[PTR_WIDTH-1:0]; // the enqueue pointer is the lower bits of the enqueue counter
    wire queue_full = enq_ctr[PTR_WIDTH]; // the queue is full if the MSB of the enqueue counter is true
    wire enq;
    and_ #(.N_INS(2)) enq_and (
        .a({enq_ready, enq_valid}),
        .y(enq)
    );
    wire deq;
    and_ #(.N_INS(2)) deq_and (
        .a({deq_ready, deq_valid}),
        .y(deq)
    );
    // extend the dequeue select signal to generate the precursor write enable signals generated by the dequeue interface
    wire [N_ENTRIES-1:0] shift_we_pre;
    extend_first1 #(.WIDTH(N_ENTRIES)) shift_we_pre_extf1 (
        .a(deq_sel_onehot),
        .y(shift_we_pre)
    );
    // gate the shift_we_pre signal with the dequeue signal so that the shift_we signal is only true when the dequeue signal is true
    wire [N_ENTRIES-1:0] shift_we;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        and_ #(.N_INS(2)) shift_we_and (
            .a({shift_we_pre[i], deq}),
            .y(shift_we[i])
        );
    end
    wire [N_ENTRIES-1:0] enq_we_pre; // one bit wider than the number of entries to allow enqueue to the queue when it is full if there will be a dequeue in the same cycle
    // decode the enqueue pointer (lower bits of the enqueue counter) to generate the precursor write enable signals generated by the enqueue interface
    dec_ #(.IN_WIDTH(PTR_WIDTH)) enq_ptr_dec (
        .in(enq_ptr),
        .out(enq_we_pre)
    );

    // gate the enq_we_pre signal with the enqueue signal so that the enq_we signal is only true when the enqueue signal is true
    wire [N_ENTRIES-1:0] enq_we;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        and_ #(.N_INS(2)) enq_we_and (
            .a({enq_we_pre[i], enq}),
            .y(enq_we[i])
        );
    end

    wire enq_we_ext_pre = queue_full;
    wire enq_we_ext; // enqueue write enable external (to the queue) (is true if the queue is full and there is an enqueue)
    and_ #(.N_INS(2)) enq_we_ext_and (
        .a({enq_we_ext_pre, enq}),
        .y(enq_we_ext)
    );
    wire wr_en_ext = 1'b0; // write enable external (to the queue) (is false because the outside of the queue can't be written to)

    // the events dequeue and shift are if and only if conditions (i.e. dequeue is true iff shift is true)
    // the concrete examples of enqueue, dequeue, and write signals in this formulation, for the case of integer issue queue:
    // - enqueue = dispatch
    // - dequeue (= shift) = issue
    // - write = wakeup
    // write and shift case:
    // - the write data is shifted as well (register i-1 gets the write data, register i doesn't) (NOTE: writes to register 0 don't shift)
    // enqueue and shift case:
    // - the enqueued entry is shifted as well (register i-1 gets the enqueued entry, register i doesn't) (NOTE: enqueues to register 0 don't shift)
    // so, the (one-hot) din_mux of register i chooses between:
    // - enq_data (if enq is true AND (shift is true AND enq_we[i+1] is true OR shift is false AND enq_ptr[i] is true)) (NOTE: enq_we[i+1] exists even for i = N_ENTRIES-1)
    // - wr_data (if wr_en[i] is true AND shift is false OR wr_en[i+1] is true AND shift is true) (NOTE: wr_en[i+1] is 1'b0 instead for i = N_ENTRIES-1 (there won't be a write to outside of the queue))
    // - entry_douts[i+1] (if shift is true) (NOTE: entry_douts[i+1] is {ENTRY_WIDTH{1'b0}} instead if i = N_ENTRIES-1)
    // shift_we[i] | enq_we[i+1] | wr_en[i+1] | enq_we[i] | wr_en[i] | din[i]
    // 0           | x           | x          | 0         | 0        | entry_douts[i]
    // 0           | x           | x          | 0         | 1        | wr_data[i]
    // 0           | x           | x          | 1         | 0        | enq_data
    // 0           | x           | x          | 1         | 1        | error (we cannot write to empty entries)
    // 1           | 0           | 0          | x         | x        | entry_douts[i+1] (or {ENTRY_WIDTH{1'b0}} if i = N_ENTRIES-1)
    // 1           | 0           | 1          | x         | x        | wr_data[i+1] (or 1'b0 for i = N_ENTRIES-1)
    // 1           | 1           | 0          | x         | x        | enq_data
    // 1           | 1           | 1          | x         | x        | error (we cannot write to empty entries)
    // the select signals are generated by the following inputs:
    // - shift_we[i]
    // - wr_en[i]
    // - enq_we[i]
    // - wr_en[i+1] (is 0 for i = N_ENTRIES-1)
    // - enq_we[i+1] (exists even for i = N_ENTRIES-1)
    // so, the (one-hot) din_mux of register i chooses between:
    // - 0: entry_douts[i+1] (if shift_we[i] is true AND enq_we[i+1] is false AND wr_en[i+1] is false) (is all 0s if i = N_ENTRIES-1)
    // - 1: enq_data (if shift_we[i] is false and enq_we[i] is true OR shift_we[i] is true and enq_we[i+1] is true)
    // - 2: wr_data[i] (if shift_we[i] is false and wr_en[i] is true)
    // - 3: wr_data[i+1] (if shift_we[i] is true and wr_en[i+1] is true)
    // - default: if all the above conditions are false, register i should hold the same value as before
    // since we of register i is false anyway, the output of the mux is don't care (physically all 0s because of the one-hot mux implementation)
    // sel[0] = shift_we[i] & ~enq_we[i+1] & ~wr_en[i+1]
    // sel[1] = ~shift_we[i] & enq_we[i] | shift_we[i] & enq_we[i+1]
    // sel[2] = ~shift_we[i] & wr_en[i]
    // sel[3] = shift_we[i] & wr_en[i+1]
    wire [N_ENTRIES-1:0] shift_we_not;
    wire [N_ENTRIES-1:0] enq_we_not;
    wire [N_ENTRIES-1:0] wr_en_not;
    wire enq_we_ext_not;
    wire wr_en_ext_not;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        INV_X1 shift_we_inv (
            .A(shift_we[i]),
            .ZN(shift_we_not[i])
        );
        INV_X1 enq_we_inv (
            .A(enq_we[i]),
            .ZN(enq_we_not[i])
        );
        INV_X1 wr_en_inv (
            .A(wr_en[i]),
            .ZN(wr_en_not[i])
        );
    end
    INV_X1 enq_we_ext_inv (
        .A(enq_we_ext),
        .ZN(enq_we_ext_not)
    );
    INV_X1 wr_en_ext_inv (
        .A(wr_en_ext),
        .ZN(wr_en_ext_not)
    );
    
    // 
    wire [N_ENTRIES-1:0] sel_data_behind; // sel[0]: entry_douts[i+1]
    for (genvar i = 0; i < N_ENTRIES - 1; i++) begin
        and_ #(.N_INS(3)) sel_data_behind_and (
            .a({shift_we[i], enq_we_not[i+1], wr_en_not[i+1]}),
            .y(sel_data_behind[i])
        );
    end
    and_ #(.N_INS(3)) sel_data_behind_last_and ( // sel[0]: {ENTRY_WIDTH{1'b0}}
        .a({shift_we[N_ENTRIES-1], enq_we_ext_not, wr_en_ext_not}),
        .y(sel_data_behind[N_ENTRIES-1])
    );
    // 
    
    // 
    wire [N_ENTRIES-1:0] sel_enq_data_pre_from_this; // sel[1] -- ~shift_we[i] & enq_we[i]
    wire [N_ENTRIES-1:0] sel_enq_data_pre_from_behind; // sel[1] -- shift_we[i] & enq_we[i+1]
    wire [N_ENTRIES-1:0] sel_enq_data; // sel[1]: enq_data
    for (genvar i = 0; i < N_ENTRIES - 1; i++) begin
        and_ #(.N_INS(2)) sel_enq_data_pre_from_this_and (
            .a({enq_we[i], shift_we_not[i]}),
            .y(sel_enq_data_pre_from_this[i])
        );
        and_ #(.N_INS(2)) sel_enq_data_pre_from_behind_and (
            .a({enq_we_not[i+1], shift_we[i]}),
            .y(sel_enq_data_pre_from_behind[i])
        );
        or_ #(.N_INS(2)) sel_enq_data_or (
            .a({sel_enq_data_pre_from_this[i], sel_enq_data_pre_from_behind[i]}),
            .y(sel_enq_data[i])
        );
    end
    and_ #(.N_INS(2)) sel_enq_data_pre_from_this_last_and (
            .a({enq_we[N_ENTRIES - 1], shift_we_not[N_ENTRIES - 1]}),
            .y(sel_enq_data_pre_from_this[N_ENTRIES - 1])
        );
    and_ #(.N_INS(2)) sel_enq_data_pre_from_behind_last_and (
        .a({enq_we_ext_not, shift_we[N_ENTRIES - 1]}),
        .y(sel_enq_data_pre_from_behind[N_ENTRIES - 1])
    );
    or_ #(.N_INS(2)) sel_enq_data_last_or ( // sel[1]: enq_data
        .a({sel_enq_data_pre_from_this[N_ENTRIES - 1], sel_enq_data_pre_from_behind[N_ENTRIES - 1]}),
        .y(sel_enq_data[N_ENTRIES - 1])
    );
    // 

    // 
    wire [N_ENTRIES-1:0] sel_wr_data; // sel[2]: wr_data[i]
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        and_ #(.N_INS(2)) sel_wr_data_and (
            .a({wr_en[i], shift_we_not[i]}),
            .y(sel_wr_data[i])
        );
    end
    // 

    // 
    wire [N_ENTRIES-1:0] sel_wr_data_behind; // sel[3]: wr_data[i+1]
    for (genvar i = 0; i < N_ENTRIES - 1; i++) begin
        and_ #(.N_INS(2)) sel_wr_data_behind_and (
            .a({wr_en[i+1], shift_we[i]}),
            .y(sel_wr_data_behind[i])
        );
    end
    and_ #(.N_INS(2)) sel_wr_data_behind_last_and ( // sel[3]: wr_data[i+1] (always false for i = N_ENTRIES - 1)
        .a({wr_en_ext, shift_we[N_ENTRIES - 1]}),
        .y(sel_wr_data_behind[N_ENTRIES - 1])
    );
    // 

    // if wr_en is true for empty entries (entries i where i >= enq_ptr), then throw an error
    // assert(!|wr_en[N_ENTRIES-1:enq_ptr]|) else $fatal(0, "shift_queue: wr_en is true for empty entries");

    // if all select signals are zero, the output is don't care (physically 0); the entry_we for the register is false anyway
    wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_din;
    for (genvar i = 0; i < N_ENTRIES-1; i++) begin
        onehot_mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(4)) entry_din_mux (
            .ins({entry_douts[i+1], enq_data, wr_data[i], wr_data[i+1]}),
            .sel({sel_data_behind[i], sel_enq_data[i], sel_wr_data[i], sel_wr_data_behind[i]}),
            .out(entry_din[i])
        );
    end
    onehot_mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(4)) entry_din_last_mux (
        // if sel_data_behind[N_ENTRIES-1] is true, then shift in fresh all 0s
        // sel_wr_data_behind[N_ENTRIES-1] is always false anyway
        .ins({{ENTRY_WIDTH{1'b0}}, enq_data, wr_data[N_ENTRIES-1], {ENTRY_WIDTH{1'b0}}}),
        .sel({sel_data_behind[N_ENTRIES-1], sel_enq_data[N_ENTRIES-1], sel_wr_data[N_ENTRIES-1], sel_wr_data_behind[N_ENTRIES-1]}),
        .out(entry_din[N_ENTRIES-1])
    );

    // combine the select signals to generate the write enable signals for each entry
    wire [N_ENTRIES-1:0] entry_we;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        or_ #(.N_INS(4)) entry_we_or (
            .a({sel_data_behind[i], sel_enq_data[i], sel_wr_data[i], sel_wr_data_behind[i]}),
            .y(entry_we[i])
        );
    end

    wire enq_ctr_inc;
    wire enq_ctr_dec;
    wire enq_not;
    wire deq_not;
    INV_X1 enq_inv (
        .A(enq),
        .ZN(enq_not)
    );
    INV_X1 deq_inv (
        .A(deq),
        .ZN(deq_not)
    );
    and_ #(.N_INS(2)) enq_ctr_inc_and (
        .a({enq, deq_not}),
        .y(enq_ctr_inc)
    );
    and_ #(.N_INS(2)) enq_ctr_dec_and (
        .a({enq_not, deq}),
        .y(enq_ctr_dec)
    );

    // output drivers
    // if the queue is not full OR there will be a dequeue, then enq_ready is true
    // WARNING: with this implementation, now the enqueue interface depends on the dequeue interface
    // TODO: check this for feasibility
    INV_X1 inv (
        .A(queue_full),
        .ZN(queue_not_full)
    );
    or_ #(.N_INS(2)) enq_ready_or (
        .a({queue_not_full, deq}),
        .y(enq_ready)
    );

    // if any entry is selected for dequeue, then deq_valid is true
    or_ #(.N_INS(N_ENTRIES)) deq_valid_or (
        .a(deq_sel_onehot),
        .y(deq_valid)
    );
    // select the entry to be dequeued (outputs ? when no entry is selected)
    onehot_mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_ENTRIES)) deq_data_mux (
        .sel(deq_sel_onehot),
        .ins(entry_douts),
        .out(deq_data)
    );
    // entry_douts is already driven in each entry_r instantiation

    // state elements
    up_down_counter #(.WIDTH(CTR_WIDTH)) enq_ctr_r (
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(enq_ctr_inc),
        .dec(enq_ctr_dec),
        .count(enq_ctr)
    );
    for (genvar i = 0; i < N_ENTRIES; i++) begin : queue
        register #(.WIDTH(ENTRY_WIDTH)) entry_r (
            .clk(clk),
            .rst_aL(rst_aL),
            .we(entry_we[i]),
            .din(entry_din[i]),
            .dout(entry_douts[i])
        );
    end
endmodule

`endif
