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

    // lsu broadcast:
    output wire lsu_broadcast_valid,
    output wire rob_id_t lsu_broadcast_rob_id,
    output wire reg_data_t lsu_broadcast_reg_data
);
    wire lsq_simple_entry_t lsq_deq_entry;

    wire dcache_resp_valid;
    wire word_t dcache_resp_rd_data;

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

        .deq_ready(dcache_resp_valid),
        .deq_valid(), // not used
        .deq_data(lsq_deq_entry),
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

    // TODO: verify that loads and stores in test programs are always aligned
    wire addr_t eff_addr_unaligned = lsq_deq_entry.base_addr + lsq_deq_entry.imm;
    wire addr_t eff_addr;
    assign eff_addr[31:2] = eff_addr_unaligned[31:2];
    assign eff_addr[1] = (lsq_deq_entry.width == WORD) ? 1'b0 : eff_addr_unaligned[1]; // if (lw | sw)
    assign eff_addr[0] = (lsq_deq_entry.width != BYTE) ? 1'b0 : eff_addr_unaligned[0]; // if (lw | lh | lhu | sw | sh)


    cache #(
        .CACHE_TYPE(DCACHE),
        .N_SETS(64)
    ) dcache (
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .flush(flush), // TODO: do we have to flush anything in cache? (we don't need to flush the lfsr)
        // FROM PIPELINE TO CACHE (REQUEST) (LATENCY-SENSITIVE)
        .pipeline_req_valid(~lsq_deq_entry.ld_st ? lsq_deq_entry.base_addr_ready : // load
                                                   lsq_deq_entry.base_addr_ready & lsq_deq_entry.st_data_ready), // store
        .pipeline_req_type(lsq_deq_entry.ld_st), // 0: read, 1: write
        .pipeline_req_wr_width(lsq_deq_entry.width), // 0: byte, 1: halfword, 2: word (only for dcache and stores)
        .pipeline_req_addr(eff_addr),
        .pipeline_req_wr_data(lsq_deq_entry.st_data), // (only for writes)
        // FROM CACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
        .mem_ctrl_req_valid(mem_ctrl_req_valid),
        .mem_ctrl_req_type(mem_ctrl_req_type), // 0: read, 1: write
        .mem_ctrl_req_block_addr(mem_ctrl_req_block_addr),
        .mem_ctrl_req_block_data(mem_ctrl_req_block_data), // (only for dcache and stores)
        .mem_ctrl_req_ready(mem_ctrl_req_ready), // (icache has priority. for icache, if valid is true, then ready is also true.)
        // FROM MEM_CTRL TO CACHE (RESPONSE) (LATENCY-SENSITIVE)
        .mem_ctrl_resp_valid(mem_ctrl_resp_valid),
        .mem_ctrl_resp_block_data(mem_ctrl_resp_block_data),
        // FROM CACHE TO PIPELINE (RESPONSE)
        .pipeline_resp_valid(dcache_resp_valid), // cache hit
        .pipeline_resp_rd_data(dcache_resp_rd_data)
    );

    assign lsu_broadcast_valid = dcache_resp_valid & ~lsq_deq_entry.ld_st; // is load
    assign lsu_broadcast_rob_id = lsq_deq_entry.instr_rob_id;
    assign lsu_broadcast_reg_data = lsq_deq_entry.ld_sign == 1'b0 ? ( // signed
                                        lsq_deq_entry.width == BYTE ?
                                            {{24{dcache_resp_rd_data[7]}}, dcache_resp_rd_data[0+:8]} :
                                        lsq_deq_entry.width == HALFWORD ?
                                            {{16{dcache_resp_rd_data[15]}}, dcache_resp_rd_data[0+:15]} :
                                        lsq_deq_entry.width == WORD ?
                                            dcache_resp_rd_data
                                    ) : lsq_deq_entry.ld_sign == 1'b1 ? ( // unsigned
                                        lsq_deq_entry.width == BYTE ?
                                            {{24{1'b0}}, dcache_resp_rd_data[0+:8]} :
                                        lsq_deq_entry.width == HALFWORD ?
                                            {{16{1'b0}}, dcache_resp_rd_data[0+:15]} :
                                        lsq_deq_entry.width == WORD ?
                                            dcache_resp_rd_data
                                    ) : 32'b0; // not used
endmodule
