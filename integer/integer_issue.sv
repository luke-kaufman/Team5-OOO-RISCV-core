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
    // TODO: change the name of this interface to alu
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

    wire iiq_issue_data_t integer_issue_buffer_din;
    // select between the issue data from iiq and bypass data from alu and load
    assign integer_issue_buffer_din = '{
        src1_data: alu_broadcast_valid && (alu_broadcast_rob_id == scheduled_entry.src1_rob_id) ?
                        alu_broadcast_reg_data :
                        ld_broadcast_valid && (ld_broadcast_rob_id == scheduled_entry.src1_rob_id) ?
                            ld_broadcast_reg_data :
                            scheduled_entry.src1_data,
        src2_data: alu_broadcast_valid && (alu_broadcast_rob_id == scheduled_entry.src2_rob_id) ?
                        alu_broadcast_reg_data :
                        ld_broadcast_valid && (ld_broadcast_rob_id == scheduled_entry.src2_rob_id) ?
                            ld_broadcast_reg_data :
                            scheduled_entry.src2_data,
        imm: scheduled_entry.imm,
        pc: scheduled_entry.pc,
        rob_id_t: instr_rob_id_in, // received from issue
        funct3: scheduled_entry.funct3, // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
        is_r_type: scheduled_entry.is_r_type,
        is_i_type: scheduled_entry.is_i_type,
        is_u_type: scheduled_entry.is_u_type, // lui and auipc only
        is_b_type: scheduled_entry.is_b_type,
        is_j_type: scheduled_entry.is_j_type, // jal only
        is_sub: scheduled_entry.is_sub, // if is_r_type, 0 = add, 1 = sub
        is_sra_srai: scheduled_entry.is_sra_srai, // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
        is_lui: scheduled_entry.is_lui, // if is_u_type, 0 = auipc, 1 = lui
        is_jalr: scheduled_entry.is_jalr, // if is_i_type, 0 = else, 1 = jalr
        br_dir_pred: scheduled_entry.br_dir_pred // received from issue (0: not taken, 1: taken)
    }

    reg_ #(
        .WIDTH(`IIQ_ISSUE_DATA_WIDTH)
    ) integer_issue_buffer (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(issue_valid),
        .din(integer_issue_buffer_din),
        .dout(issue_data)
    );
endmodule
