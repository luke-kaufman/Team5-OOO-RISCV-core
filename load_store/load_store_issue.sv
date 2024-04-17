module load_store_issue #(

) (
    input wire clk,
    input wire rst_aL,

    // for testing
    input wire init,

);
    wire lsq_entry_t [`LSQ_N_ENTRIES-1:0] entries;
    wire [`LSQ_N_ENTRIES-1:0] scheduled_entry_idx_onehot;
    wire lsq_entry_t scheduled_entry;
    wire [`LSQ_N_ENTRIES-1:0] entries_wr_en;
    wire lsq_entry_t [`LSQ_N_ENTRIES-1:0] entries_wr_data;
    shift_queue lsq (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(),
        .enq_valid(),
        .enq_data(),

        .deq_ready(),
        .deq_sel_onehot(scheduled_entry_idx_onehot),
        .deq_valid(),
        .deq_data(scheduled_entry),

        .wr_en(entries_wr_en),
        .wr_data(entries_wr_data),

        .entry_douts(entries),

        .init(init),
        .init_entry_reg_state(),
        .init_enq_up_down_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_down_counter_state()
    );

    // issue scheduling
    wire [`LSQ_N_ENTRIES-1:0] entries_ready;
    for (genvar i = 0; i < `LSQ_N_ENTRIES; i++) begin
        assign entries_ready[i] = entries[i].base_addr_ready & (~entries[i].ld_st | entries[i].st_data_ready);
    end
    ff1 #(
        .WIDTH(`LSQ_N_ENTRIES)
    ) issue_scheduler (
        .a(entries_ready),
        .y(scheduled_entry_idx_onehot)
    );

    // tag (rob_id) comparators for wakeup and capture
    wire [`IIQ_N_ENTRIES-1:0] entries_base_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_base_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_base_ld_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_ld_capture;

    shift_queue #(
        .N_ENTRIES(`LDB_N_ENTRIES),
        .ENTRY_WIDTH(`LDB_ENTRY_WIDTH)
    ) ld_buf (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(),
        .enq_valid(),
        .enq_data(),

        .deq_ready(),
        .deq_sel_onehot(),
        .deq_valid(),
        .deq_data(),

        .wr_en(),
        .wr_data(),

        .entry_douts(),

        .init(init),
        .init_entry_reg_state(),
        .init_enq_up_down_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_down_counter_state()
    );

    fifo_ram #(
        .N_ENTRIES(`ST_BUF_N_ENTRIES),
        .ENTRY_WIDTH(`ST_BUF_ENTRY_WIDTH)
    ) st_buf (
        
    );

    matrix_ram #(

    ) mdt (

    );
endmodule
