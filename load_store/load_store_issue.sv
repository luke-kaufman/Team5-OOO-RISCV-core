`include "misc/global_defs.svh"

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

    // for testing
    input wire init // TODO
);
    // -------------------------------- LSQ wires begin --------------------------------
    wire lsq_entry_t [`LSQ_N_ENTRIES-1:0] lsq_entries;
    wire [`LSQ_N_ENTRIES-1:0] lsq_scheduled_entry_idx_onehot;
    wire lsq_entry_t lsq_scheduled_entry;
    wire [`LSQ_N_ENTRIES-1:0] lsq_entries_wr_en;
    wire lsq_entry_t [`LSQ_N_ENTRIES-1:0] lsq_entries_wr_data;
    wire lsq_deq_valid;
    wire ld_buf_enq_ready;

    // lsq issue scheduling
    wire [`LSQ_N_ENTRIES-1:0] lsq_entries_ready;
    for (genvar i = 0; i < `LSQ_N_ENTRIES; i++) begin
        assign lsq_entries_ready[i] = lsq_entries[i].base_addr_ready & (~lsq_entries[i].ld_st | lsq_entries[i].st_data_ready);
    end
    ff1 #(
        .WIDTH(`LSQ_N_ENTRIES)
    ) lsq_issue_scheduler (
        .a(lsq_entries_ready),
        .y(lsq_scheduled_entry_idx_onehot)
    );

    // lsq-ld_buf issue handshake:
    // 1. lsq deq should be valid
    // 2. either scheduled_entry should be a store (st_buf is always ready) or ld_buf enq should be ready
    wire lsq_issue = lsq_deq_valid & (lsq_scheduled_entry.ld_st | ld_buf_enq_ready);
    wire lsq_deq_ready = lsq_issue;



    // tag (rob_id) comparators for wakeup and capture
    wire [`IIQ_N_ENTRIES-1:0] entries_base_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_iiq_wakeup;
    wire [`IIQ_N_ENTRIES-1:0] entries_base_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_alu_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_base_ld_capture;
    wire [`IIQ_N_ENTRIES-1:0] entries_st_data_ld_capture;
    // -------------------------------- LSQ wires end --------------------------------

    wire addr_t eff_addr_unaligned = lsq_scheduled_entry.base_addr + lsq_scheduled_entry.imm;
    wire addr_t eff_addr;
    assign eff_addr[31:2] = eff_addr_unaligned[31:2];
    assign eff_addr[1] = (lsq_scheduled_entry.width[1]) ? 1'b0 : eff_addr_unaligned[1]; // if (lw | sw)
    assign eff_addr[0] = (|lsq_scheduled_entry.width) ? 1'b0 : eff_addr_unaligned[0]; // if (lw | lh | lhu | sw | sh)



    wire ld_buf_enq_ready;
    wire ld_buf_enq_valid = lsq_issue & ~lsq_scheduled_entry.ld_st;
    wire ld_buf_enq_data = '{
        eff_addr: eff_addr,
        ld_width: lsq_scheduled_entry.width,
        is_dcache_initiated: 1'b0,
        instr_rob_id: lsq_scheduled_entry.instr_rob_id,
        ld_data: {`REG_DATA_WIDTH{1'b0}}
    };
    wire ld_buf_deq_ready = ; // TODO: should include the ld-st arbiter
    wire [`LD_BUF_N_ENTRIES-1:0] ld_buf_deq_sel_onehot;
    wire ld_buf_deq_valid;
    wire [`LD_BUF_ENTRY_WIDTH-1:0] ld_buf_deq_data;
    wire ld_buf_wr_en = ; // TODO: should include the start and end of ld_execute
    wire ld_buf_wr_data = ; // TODO: should include the start and end of ld_execute
    wire ld_buf_entry_douts;

    // load scheduling
    wire [`LD_BUF_N_ENTRIES-1:0] ld_buf_entries_ready;
    wire [`LD_BUF_N_ENTRIES-1:0] [`ST_BUF_N_ENTRIES-1:0] mdm_ld_dep_vecs;
    for (genvar i = 0; i < `LSQ_N_ENTRIES; i++) begin
        assign ld_buf_entries_ready[i] = ~|(mdm_ld_dep_vecs[i]); // TODO: verify that this works correctly
    end
    ff1 #(
        .WIDTH(`LSQ_N_ENTRIES)
    ) load_scheduler (
        .a(ld_buf_entries_ready),
        .y(ld_buf_scheduled_entry_idx_onehot)
    );

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

    wire ld_buf_enq_ready;
    wire ld_buf_entry_t ld_buf_enq_data;

    shift_queue #(
        .N_ENTRIES(`LSQ_N_ENTRIES),
        .ENTRY_WIDTH(`LSQ_ENTRY_WIDTH)
    ) lsq (
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

        .flush(),

        .init(),
        .init_entry_reg_state(),
        .init_enq_up_down_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_down_counter_state()
    );

    shift_queue #(
        .N_ENTRIES(`LD_BUF_N_ENTRIES),
        .ENTRY_WIDTH(`LD_BUF_ENTRY_WIDTH)
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

        .flush(),

        .init(),
        .init_entry_reg_state(),
        .init_enq_up_down_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_down_counter_state()
    );

    // TODO: wrap this in a separate module to handle the special flush logic (use init port instead of the actual flush port)
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

        .flush(),

        .init(),
        .init_entry_reg_state(),
        .init_enq_up_counter_state(),
        .init_deq_up_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_counter_state(),
        .current_deq_up_counter_state()
    );

    // memory dependence matrix
    matrix_ram #(
        .N_ROWS(`LD_BUF_N_ENTRIES),
        .N_COLS(`ST_BUF_N_ENTRIES)
    ) mdm (
        .clk(clk),
        .rst_aL(rst_aL),

        .rd_data(mdm_rd_data),

        .row_wr_en(mdm_row_wr_en),
        .row_wr_addr(mdm_row_wr_addr),
        .row_wr_data(mdm_row_wr_data),

        .col_wr_en(mdm_col_wr_en),
        .col_wr_addr(mdm_col_wr_addr),
        .col_wr_data(mdm_col_wr_data),

        .flush(),

        .init(mdm_init),
        .init_matrix_state(mdm_init_matrix_state),
        .current_matrix_state(mdm_current_matrix_state)
    );
endmodule
