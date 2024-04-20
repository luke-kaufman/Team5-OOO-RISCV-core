`ifndef MEM_CTRL_V
`define MEM_CTRL_V

`include "misc/global_defs.svh"

module mem_ctrl (
    // FROM ICACHE TO MEM_CTRL (REQUEST) (always read)
    input logic icache_req_valid,
    input main_mem_block_addr_t icache_req_block_addr,
    output logic icache_req_ready,

    // FROM DCACHE TO MEM_CTRL (REQUEST)
    input logic dcache_req_valid,
    input req_type_t dcache_req_type, // 0: read, 1: write
    input main_mem_block_addr_t dcache_req_block_addr,
    input block_data_t dcache_req_block_data, // for writes
    output logic dcache_req_ready,

    // FROM MEM_CTRL TO MAIN_MEM (REQUEST)
    output logic mem_req_valid,
    output cache_type_t mem_req_cache_type, // 0: icache, 1: dcache
    output req_type_t mem_req_type, // 0: read, 1: write
    output main_mem_block_addr_t mem_req_block_addr,
    output block_data_t mem_req_block_data, // for writes

    // FROM MAIN_MEM TO MEM_CTRL (RESPONSE)
    input logic mem_resp_valid,
    input cache_type_t mem_resp_cache_type,
    input block_data_t mem_resp_block_data, // for reads

    // FROM MEM_CTRL TO ICACHE (RESPONSE)
    output logic icache_resp_valid,
    output block_data_t icache_resp_block_data,

    // FROM MEM_CTRL TO DCACHE (RESPONSE)
    output logic dcache_resp_valid,
    output block_data_t dcache_resp_block_data
);
    // Give priority to icache requests
    always_comb begin
        if (icache_req_valid) begin
            icache_req_ready = 1;
            dcache_req_ready = 0;
        end else if (dcache_req_valid) begin
            icache_req_ready = 0;
            dcache_req_ready = 1;
        end else begin
            icache_req_ready = 0;
            dcache_req_ready = 0;
        end
    end

    // Forwarding requests to main_mem
    always_comb begin
        if (icache_req_valid) begin
            mem_req_valid = 1;
            mem_req_cache_type = ICACHE;
            mem_req_type = READ;
            mem_req_block_addr = icache_req_block_addr;
            mem_req_block_data = 0;
        end else if (dcache_req_valid) begin
            mem_req_valid = 1;
            mem_req_cache_type = DCACHE;
            mem_req_type = dcache_req_type;
            mem_req_block_addr = dcache_req_block_addr;
            mem_req_block_data = dcache_req_block_data;
        end else begin
            mem_req_valid = 0;
            mem_req_cache_type = cache_type_t'(0);
            mem_req_type = req_type_t'(0);
            mem_req_block_addr = 0;
            mem_req_block_data = 0;
        end
    end

    // Forwarding responses to icache and dcache
    always_comb begin
        if (mem_resp_valid && mem_resp_cache_type == ICACHE) begin
            icache_resp_valid = 1;
            icache_resp_block_data = mem_resp_block_data;
            dcache_resp_valid = 0;
            dcache_resp_block_data = 0;
        end else if (mem_resp_valid && mem_resp_cache_type == DCACHE) begin
            icache_resp_valid = 0;
            icache_resp_block_data = 0;
            dcache_resp_valid = 1;
            dcache_resp_block_data = mem_resp_block_data;
        end else begin
            icache_resp_valid = 0;
            icache_resp_block_data = 0;
            dcache_resp_valid = 0;
            dcache_resp_block_data = 0;
        end
    end
endmodule

`endif
