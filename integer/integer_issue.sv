`include "misc/global_defs.svh"
`include  "misc/ff1.v"

module integer_issue (
    input wire clk,
    input wire rst_aL,

    // dispatch interface: ready & valid
    output wire dispatch_ready,
    input wire dispatch_valid,
    input wire iiq_entry_t dispatch_data,

    // issue interface: always ready (all integer instructions take 1 cycle to execute)
    output wire issue_valid,
    output wire iiq_issue_data_t issue_data,

    // alu broadcast:
    input wire alu_broadcast_valid,
    input wire rob_id_t alu_broadcast_rob_id,
    input wire reg_data_t alu_broadcast_reg_data,
    // load broadcast:
    input wire ld_broadcast_valid,
    input wire rob_id_t ld_broadcast_rob_id,
    input wire reg_data_t ld_broadcast_reg_data
);
    wire iiq_entry_t [`IIQ_N_ENTRIES-1:0] entries;
    wire [`IIQ_N_ENTRIES-1:0] scheduled_entry_idx_onehot;
    wire iiq_entry_t scheduled_entry;
    wire [`IIQ_N_ENTRIES-1:0] entries_wr_en;
    wire iiq_entry_t [`IIQ_N_ENTRIES-1:0] entries_wr_data;
    shift_queue #(
        .N_ENTRIES(`IIQ_N_ENTRIES),
        .ENTRY_WIDTH(`IIQ_ENTRY_WIDTH)
    ) iiq (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(dispatch_ready),
        .enq_valid(dispatch_valid),
        .enq_data(dispatch_data),

        .deq_ready(1'b1), // always ready (all integer instructions take 1 cycle to execute)
        .deq_sel_onehot(scheduled_entry_idx_onehot), // can be either one-hot or all 0s
        .deq_valid(issue_valid),
        .deq_data(scheduled_entry),

        .wr_en(entries_wr_en),
        .wr_data(entries_wr_data),

        .entry_douts(entries)
    );

    // issue scheduling
    wire [`IIQ_N_ENTRIES-1:0] entries_ready;
    for (genvar i = 0; i < `IIQ_N_ENTRIES; i++) begin
        wire src1_ok = ~entries[i].src1_valid || (entries[i].src1_valid && entries[i].src1_ready);
        wire src2_ok = ~entries[i].src2_valid || (entries[i].src2_valid && entries[i].src2_ready);
        assign entries_ready[i] = src1_ok && src2_ok;
    end
    ff1 #(
        .WIDTH(`IIQ_N_ENTRIES)
    ) issue_scheduler (
        .a(entries_ready),
        .y(scheduled_entry_idx_onehot)
    );

    // tag (rob_id) comparators for wakeup and capture
    wire [`IIQ_N_ENTRIES-1:0] entries_src1_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_src2_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_src1_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_src2_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_src1_ld_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_src2_ld_capture;
    for (genvar i = 0; i < `IIQ_N_ENTRIES; i++) begin
        unsigned_cmp_ #(
            .WIDTH(`ROB_ID_WIDTH)
        ) entries_src1_int_wakeup_cmp (
            .a(scheduled_entry.rob_id),
            .b(entries[i].src1_rob_id),
            .eq(entries_src1_iiq_wakeup[i])
        );
        unsigned_cmp_ #(
            .WIDTH(`ROB_ID_WIDTH)
        ) entries_src2_int_wakeup_cmp (
            .a(scheduled_entry.rob_id),
            .b(entries[i].src2_rob_id),
            .eq(entries_src2_iiq_wakeup[i])
        );
        unsigned_cmp_ #(
            .WIDTH(`ROB_ID_WIDTH)
        ) entries_src1_alu_capture_cmp (
            .a(alu_broadcast_rob_id),
            .b(entries[i].src1_rob_id),
            .eq(entries_src1_alu_capture[i])
        );
        unsigned_cmp_ #(
            .WIDTH(`ROB_ID_WIDTH)
        ) entries_src2_alu_capture_cmp (
            .a(alu_broadcast_rob_id),
            .b(entries[i].src2_rob_id),
            .eq(entries_src2_alu_capture[i])
        );
        unsigned_cmp_ #(
            .WIDTH(`ROB_ID_WIDTH)
        ) entries_src1_ld_capture_cmp (
            .a(ld_broadcast_rob_id),
            .b(entries[i].src1_rob_id),
            .eq(entries_src1_ld_capture[i])
        );
        unsigned_cmp_ #(
            .WIDTH(`ROB_ID_WIDTH)
        ) entries_src2_ld_capture_cmp (
            .a(ld_broadcast_rob_id),
            .b(entries[i].src2_rob_id),
            .eq(entries_src2_ld_capture[i])
        );
    end

    for (genvar i = 0; i < `IIQ_N_ENTRIES; i++) begin
        assign entries_wr_en[i] = entries_src1_iiq_wakeup[i]  || entries_src2_iiq_wakeup[i]  ||
                                  entries_src1_alu_capture[i] || entries_src2_alu_capture[i] ||
                                  entries_src1_ld_capture[i]  || entries_src2_ld_capture[i];
    end
    for (genvar i = 0; i < `IIQ_N_ENTRIES; i++) begin
        assign entries_wr_data[i] = '{
            src1_valid:     entries[i].src1_valid,
            src1_rob_id:    entries[i].src1_rob_id,
            src1_ready:     (entries_src1_iiq_wakeup[i] || entries_src1_ld_capture[i]) ?
                                1'b1 :
                                entries[i].src1_ready,
            src1_data:      entries_src1_alu_capture[i] ?
                                alu_broadcast_reg_data :
                                entries_src1_ld_capture[i] ?
                                    ld_broadcast_reg_data :
                                    entries[i].src1_data,
            src2_valid:     entries[i].src2_valid,
            src2_rob_id:    entries[i].src2_rob_id,
            src2_ready:     (entries_src2_iiq_wakeup[i] || entries_src2_ld_capture[i]) ?
                                1'b1 :
                                entries[i].src2_ready,
            src2_data:      entries_src2_alu_capture[i] ?
                                alu_broadcast_reg_data :
                                entries_src2_ld_capture[i] ?
                                    ld_broadcast_reg_data :
                                    entries[i].src2_data,
            dst_valid:      entries[i].dst_valid,
            instr_rob_id:   entries[i].instr_rob_id,
            alu_ctrl:       entries[i].alu_ctrl,
            br_dir_pred:    entries[i].br_dir_pred,
            br_target_pred: entries[i].br_target_pred
        };
    end

    // TODO: add integer issue buffer here
endmodule
