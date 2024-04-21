`include "misc/global_defs.svh"

module load_store_simple #(
    parameter int unsigned LSQ_SIMPLE_N_ENTRIES = 8,
    parameter int unsigned LSQ_SIMPLE_ENTRY_WIDTH = `LSQ_SIMPLE_ENTRY_WIDTH,
) (
    input logic clk,
    input logic rst_aL,
    input logic init,
    input logic flush,

    // MEM_CTRL REQUEST
    output logic mem_ctrl_req_valid,
    output req_type_t mem_ctrl_req_type, // 0: read, 1: write
    output main_mem_block_addr_t mem_ctrl_req_block_addr,
    output block_data_t mem_ctrl_req_block_data, // for writes
    input logic mem_ctrl_req_ready,
    // MEM_CTRL RESPONSE
    input logic mem_ctrl_resp_valid,
    input block_data_t mem_ctrl_resp_block_data,

    // dispatch interface: ready & valid
    output wire dispatch_ready,
    input wire dispatch_valid,
    input wire lsq_simple_entry_t dispatch_data,

    // iiq wakeup:
    input wire iiq_wakeup_valid,
    input wire rob_id_t iiq_wakeup_rob_id,

    // alu broadcast:
    input wire alu_broadcast_valid,
    input wire rob_id_t alu_broadcast_rob_id,
    input wire reg_data_t alu_broadcast_reg_data
);

    fifo_ram #(
        .ENTRY_WIDTH(LSQ_SIMPLE_ENTRY_WIDTH),
        .N_ENTRIES(LSQ_SIMPLE_N_ENTRIES),
        .N_READ_PORTS(1), // NOTE: not used
        .N_WRITE_PORTS(3)
    ) lsq_simple (
        .clk(clk),
        .rst_aL(rst_aL),
        .flush(flush),

        .enq_ready(dispatch_ready),
        .enq_valid(dispatch_valid),
        .enq_data(dispatch_data),
        .enq_addr(), // not used

        .deq_ready(),
        .deq_valid(),
        .deq_data(),
        .deq_addr(), // not used

        .rd_addr(), // not used
        .rd_data(), // not used

        // NOTE: all writes are assumed to be to separate entries
        // writes are generalized to be optional and partial across all entries
        .wr_en(),
        .wr_addr(),
        .wr_data(),

        .entry_douts(),

        // for testing
        .init(init),
        .init_entry_reg_state(),
        .init_enq_up_counter_state(),
        .init_deq_up_counter_state(),
        .current_entry_reg_state(),
        .current_enq_up_counter_state(),
        .current_deq_up_counter_state()
    );

    // alu broadcast bypass

    cache #(
        .CACHE_TYPE(DCACHE),
        .N_SETS(64)
    ) dcache (
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .flush(flush), // TODO: do we have to flush anything in cache? (we don't need to flush the lfsr)
        // FROM PIPELINE TO CACHE (REQUEST) (LATENCY-SENSITIVE)
        .pipeline_req_valid(),
        .pipeline_req_type(), // 0: read, 1: write
        .pipeline_req_wr_width(), // 0: byte, 1: halfword, 2: word (only for dcache and stores)
        .pipeline_req_addr(),
        .pipeline_req_wr_data(), // (only for writes)
        // FROM CACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
        .mem_ctrl_req_valid(),
        .mem_ctrl_req_type(), // 0: read, 1: write
        .mem_ctrl_req_block_addr(),
        .mem_ctrl_req_block_data(), // (only for dcache and stores)
        .mem_ctrl_req_ready(), // (icache has priority. for icache, if valid is true, then ready is also true.)
        // FROM MEM_CTRL TO CACHE (RESPONSE) (LATENCY-SENSITIVE)
        .mem_ctrl_resp_valid(),
        .mem_ctrl_resp_block_data(),
        // FROM CACHE TO PIPELINE (RESPONSE)
        .pipeline_resp_valid(), // cache hit
        .pipeline_resp_rd_data()
    );

endmodule
