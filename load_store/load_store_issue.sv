module load_store_issue #(

) (
    input wire clk,
    input wire rst_aL,

    // dispatch interface: ready & valid
    output wire dispatch_ready,
    input wire dispatch_valid,
    input wire iiq_entry_t dispatch_data,

    // alu broadcast:
    input wire alu_broadcast_valid,
    input wire rob_id_t alu_broadcast_rob_id,
    input wire reg_data_t alu_broadcast_reg_data,
    // load broadcast:
    input wire ld_broadcast_valid,
    input wire rob_id_t ld_broadcast_rob_id,
    input wire reg_data_t ld_broadcast_reg_data,

    input wire fetch_redirect_valid,
    // for testing
    input wire init // TODO
);
    wire lsq_entry_t [`LSQ_N_ENTRIES-1:0] lsq_entries;
    wire [`LSQ_N_ENTRIES-1:0] lsq_scheduled_entry_idx_onehot;
    wire lsq_entry_t lsq_scheduled_entry;
    wire [`LSQ_N_ENTRIES-1:0] lsq_entries_wr_en;
    wire lsq_entry_t [`LSQ_N_ENTRIES-1:0] lsq_entries_wr_data;
    wire lsq_deq_valid;
    wire ld_buf_enq_ready;

    // lsq-ld_buf issue handshake:
    // 1. lsq deq should be valid
    // 2. either scheduled_entry should be a store (st_buf is always ready) or ld_buf enq should be ready
    wire lsq_issue = lsq_deq_valid & (lsq_scheduled_entry.ld_st | ld_buf_enq_ready);
    wire lsq_deq_ready = lsq_issue;

    wire addr_t eff_addr_unaligned = lsq_scheduled_entry.base_addr + lsq_scheduled_entry.imm;
    wire addr_t eff_addr = {eff_addr_unaligned[31:2], lsq_scheduled_entry.width

    wire ld_buf_enq_ready;
    wire ld_buf_enq_valid = lsq_issue & ~lsq_scheduled_entry.ld_st;
    wire ld_buf_enq_data = '{
        eff_addr: lsq_scheduled_entry.base_addr + lsq_scheduled_entry.imm,
        ld_width: ,
        is_dcache_initiated: ,
        instr_rob_id: ,
        ld_data: ,
    };
    wire ld_buf_deq_ready = ;
    wire ld_buf_deq_sel_onehot = ;
    wire ld_buf_deq_valid = ;
    wire ld_buf_deq_data = ;
    wire ld_buf_wr_en = ;
    wire ld_buf_wr_data = ;
    wire ld_buf_entry_douts = ;

    wire st_buf_enq_ready;
    wire st_buf_enq_valid = lsq_issue & lsq_scheduled_entry.ld_st;
    wire st_buf_enq_data
    wire st_buf_enq_addr
    wire st_buf_deq_ready
    wire st_buf_deq_valid
    wire st_buf_deq_data
    wire st_buf_deq_addr
    wire st_buf_rd_addr
    wire st_buf_rd_data
    wire st_buf_wr_en
    wire st_buf_wr_addr
    wire st_buf_wr_data
    wire st_buf_entry_douts

    shift_queue lsq (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(dispatch_ready),
        .enq_valid(dispatch_valid),
        .enq_data(dispatch_data),

        .deq_ready(lsq_deq_ready),
        .deq_sel_onehot(lsq_scheduled_entry_idx_onehot),
        .deq_valid(lsq_deq_valid),
        .deq_data(lsq_scheduled_entry),

        .wr_en(lsq_entries_wr_en),
        .wr_data(lsq_entries_wr_data),

        .entry_douts(lsq_entries),
        
        .flush(fetch_redirect_valid),
        
        .init(),
        .init_entry_reg_state(),
        .init_enq_up_down_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_down_counter_state()
    );

    // issue scheduling
    wire [`LSQ_N_ENTRIES-1:0] entries_ready;
    for (genvar i = 0; i < `LSQ_N_ENTRIES; i++) begin
        assign entries_ready[i] = lsq_entries[i].base_addr_ready & (~lsq_entries[i].ld_st | lsq_entries[i].st_data_ready);
    end
    ff1 #(
        .WIDTH(`LSQ_N_ENTRIES)
    ) issue_scheduler (
        .a(entries_ready),
        .y(lsq_scheduled_entry_idx_onehot)
    );

    // tag (rob_id) comparators for wakeup and capture
    wire [`IIQ_N_ENTRIES-1:0] entries_base_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_base_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_base_ld_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_ld_capture;

    wire ld_buf_enq_ready;
    wire ld_buf_entry_t ld_buf_enq_data;
    shift_queue #(
        .N_ENTRIES(`LDB_N_ENTRIES),
        .ENTRY_WIDTH(`LDB_ENTRY_WIDTH)
    ) ld_buf (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(ld_buf_enq_ready),
        .enq_valid(ld_buf_enq_valid),
        .enq_data(ld_buf_enq_data),

        .deq_ready(ld_buf_deq_ready),
        .deq_sel_onehot(ld_buf_deq_sel_onehot),
        .deq_valid(ld_buf_deq_valid),
        .deq_data(ld_buf_deq_data),

        .wr_en(ld_buf_wr_en),
        .wr_data(ld_buf_wr_data),

        .entry_douts(ld_buf_entry_douts),

        .flush(fetch_redirect_valid),

        .init(),
        .init_entry_reg_state(),
        .init_enq_up_down_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_down_counter_state()
    );

    fifo_ram #(
        .N_ENTRIES(`ST_BUF_N_ENTRIES),
        .ENTRY_WIDTH(`ST_BUF_ENTRY_WIDTH)
    ) st_buf (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(st_buf_enq_ready),
        .enq_valid(st_buf_enq_valid),
        .enq_data(st_buf_enq_data),
        .enq_addr(st_buf_enq_addr),

        .deq_ready(st_buf_deq_ready),
        .deq_valid(st_buf_deq_valid),
        .deq_data(st_buf_deq_data),
        .deq_addr(st_buf_deq_addr),

        .rd_addr(st_buf_rd_addr),
        .rd_data(st_buf_rd_data),

        .wr_en(st_buf_wr_en),
        .wr_addr(st_buf_wr_addr),
        .wr_data(st_buf_wr_data),

        .entry_douts(st_buf_entry_douts),

        .flush(fetch_redirect_valid),

        .init(),
        .init_entry_reg_state(),
        .init_enq_up_counter_state(),
        .init_deq_up_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_counter_state(),
        .current_deq_up_counter_state()
    );

    assign

    // memory dependence matrix
    matrix_ram #(

    ) mdm (

    );
endmodule
