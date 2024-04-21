`include "misc/global_defs.svh"

module load_store_simple #(
    parameter int unsigned LSQ_SIMPLE_N_ENTRIES = 8
) (
    input logic clk,
    input logic rst_aL,
    input logic flush,
    // for testing
    input logic init,
    input lsq_simple_entry_t [LSQ_SIMPLE_N_ENTRIES-1:0] init_entries,

    // MEM CTRL REQUEST
    output logic mem_ctrl_req_valid,
    output req_type_t mem_ctrl_req_type, // 0: read, 1: write
    output main_mem_block_addr_t mem_ctrl_req_block_addr,
    output block_data_t mem_ctrl_req_block_data, // for writes
    input logic mem_ctrl_req_ready,
    // MEM CTRL RESPONSE
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
    wire dcache_resp_valid;
    wire word_t dcache_resp_rd_data;

    wire lsq_simple_entry_t lsq_deq_entry;
    wire lsq_simple_entry_t [LSQ_SIMPLE_N_ENTRIES-1:0] lsq_entries;
    wire lsq_simple_entry_t [LSQ_SIMPLE_N_ENTRIES-1:0] lsq_wr_data;

    wire [LSQ_SIMPLE_N_ENTRIES-1:0] base_addr_iiq_wakeup_capture;
    wire [LSQ_SIMPLE_N_ENTRIES-1:0] base_addr_alu_broadcast_capture;
    wire [LSQ_SIMPLE_N_ENTRIES-1:0] base_addr_lsu_broadcast_capture;
    wire [LSQ_SIMPLE_N_ENTRIES-1:0] store_data_iiq_wakeup_capture;
    wire [LSQ_SIMPLE_N_ENTRIES-1:0] store_data_alu_broadcast_capture;
    wire [LSQ_SIMPLE_N_ENTRIES-1:0] store_data_lsu_broadcast_capture;
    for (genvar i = 0; i < LSQ_SIMPLE_N_ENTRIES; i++) begin
        assign base_addr_iiq_wakeup_capture[i]     = iiq_wakeup_valid &
                                                     (lsq_entries[i].base_addr_rob_id == iiq_wakeup_rob_id);
        assign base_addr_alu_broadcast_capture[i]  = alu_broadcast_valid &
                                                     (lsq_entries[i].base_addr_rob_id == alu_broadcast_rob_id);
        assign base_addr_lsu_broadcast_capture[i]  = lsu_broadcast_valid &
                                                     (lsq_entries[i].base_addr_rob_id == lsu_broadcast_rob_id);
        assign store_data_iiq_wakeup_capture[i]    = iiq_wakeup_valid &
                                                     (lsq_entries[i].st_data_rob_id == iiq_wakeup_rob_id);
        assign store_data_alu_broadcast_capture[i] = alu_broadcast_valid &
                                                     (lsq_entries[i].st_data_rob_id == alu_broadcast_rob_id);
        assign store_data_lsu_broadcast_capture[i] = lsu_broadcast_valid &
                                                     (lsq_entries[i].st_data_rob_id == lsu_broadcast_rob_id);
        assign lsq_wr_en[i] = base_addr_iiq_wakeup_capture[i]     |
                              base_addr_alu_broadcast_capture[i]  |
                              base_addr_lsu_broadcast_capture[i]  |
                              store_data_iiq_wakeup_capture[i]    |
                              store_data_alu_broadcast_capture[i] |
                              store_data_lsu_broadcast_capture[i] ;
        assign lsq_wr_data[i] = '{
            ld_st: lsq_entries[i].ld_st, // 0: ld, 1: st
            base_addr_rob_id: lsq_entries[i].base_addr_rob_id,
            base_addr_ready: base_addr_iiq_wakeup_capture[i]    |
                            //  base_addr_alu_broadcast_capture[i] | (NOTE: should already be ready!)
                             base_addr_lsu_broadcast_capture[i] |
                             lsq_entries[i].base_addr_ready,
            base_addr: base_addr_alu_broadcast_capture ? alu_broadcast_reg_data :
                       base_addr_lsu_broadcast_capture ? lsu_broadcast_reg_data :
                       lsq_entries[i].base_addr,
            imm: lsq_entries[i].imm,
            st_data_rob_id: lsq_entries[i].st_data_rob_id,
            st_data_ready: store_data_iiq_wakeup_capture[i]    |
                          //  store_data_alu_broadcast_capture[i] | (NOTE: should already be ready!)
                           store_data_lsu_broadcast_capture[i] |
                           lsq_entries[i].st_data_ready,
            st_data: store_data_alu_broadcast_capture ? alu_broadcast_reg_data :
                     store_data_lsu_broadcast_capture ? lsu_broadcast_reg_data :
                     lsq_entries[i].st_data,
            instr_rob_id: lsq_entries[i].instr_rob_id,
            width: lsq_entries[i].width, // 0: byte, 1: halfword, 2: word
            ld_sign: lsq_entries[i].ld_sign // 0: signed, 1: unsigned
        };
    end
    lsq_simple #(
        .N_ENTRIES(LSQ_SIMPLE_N_ENTRIES)
        .ENTRY_T(lsq_simple_entry_t)
    ) _lsq_simple (
        .clk(clk),
        .rst_aL(rst_aL),
        .flush(flush),

        .enq_ready(dispatch_ready),
        .enq_valid(dispatch_valid),
        .enq_data(dispatch_data),

        .deq_valid(dcache_resp_valid),
        .deq_data(lsq_deq_entry),

        .wr_en(lsq_wr_en),
        .wr_data(lsq_wr_data),

        .entries(lsq_entries),

        // for testing
        .init(init),
        .init_entries(init_entries)
    );

    // iiq wakeup write


    // alu broadcast write

    // alu broadcast bypass into dcache request (base addr and store data)
    wire addr_t actual_base_addr   = alu_broadcast_rob_id == lsq_deq_entry.base_addr_rob_id ? alu_broadcast_reg_data  :
                                                                                              lsq_deq_entry.base_addr ;
    wire reg_data_t actual_st_data = alu_broadcast_rob_id == lsq_deq_entry.st_data_rob_id   ? alu_broadcast_reg_data  :
                                                                                              lsq_deq_entry.st_data   ;

    // TODO: verify that loads and stores in test programs are always aligned
    wire addr_t eff_addr_unaligned = actual_base_addr + lsq_deq_entry.imm;
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
        .pipeline_req_wr_data(actual_st_data), // (only for writes)
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
