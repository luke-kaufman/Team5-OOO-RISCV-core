`include "misc/global_defs.svh"
`include "top/core.sv"
`include "memory/mem_ctrl.sv"
`include "memory/main_mem.sv"

module top #(
    parameter addr_t HIGHEST_PC,
    localparam main_mem_block_addr_t HIGHEST_INSTR_BLOCK_ADDR = HIGHEST_PC >> `MAIN_MEM_BLOCK_OFFSET_WIDTH
)(
    input wire clk,
    input wire init,
    input addr_t init_pc,
    input addr_t init_sp,
    // input block_data_t init_main_mem_state[`MAIN_MEM_N_BLOCKS],
    input block_data_t init_main_mem_state[HIGHEST_INSTR_BLOCK_ADDR:0],
    input wire rst_aL,

    output logic [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] ARF_OUT
);
    wire icache_mem_ctrl_req_valid;
    wire main_mem_block_addr_t icache_mem_ctrl_req_block_addr;
    wire icache_mem_ctrl_req_ready;
    wire icache_mem_ctrl_resp_valid;
    wire block_data_t icache_mem_ctrl_resp_block_data;

    wire dcache_mem_ctrl_req_valid;
    req_type_t dcache_mem_ctrl_req_type; // TODO: figure out the enum 4-state bug
    wire main_mem_block_addr_t dcache_mem_ctrl_req_block_addr;
    wire block_data_t dcache_mem_ctrl_req_block_data;
    wire dcache_mem_ctrl_req_ready;
    wire dcache_mem_ctrl_resp_valid;
    wire block_data_t dcache_mem_ctrl_resp_block_data;

    wire mem_req_valid;
    cache_type_t mem_req_cache_type; // TODO: figure out the enum 4-state bug
    req_type_t mem_req_type; // TODO: figure out the enum 4-state bug
    wire main_mem_block_addr_t mem_req_block_addr;
    wire block_data_t mem_req_block_data;
    wire mem_resp_valid;
    cache_type_t mem_resp_cache_type; // TODO: figure out the enum 4-state bug
    wire block_data_t mem_resp_block_data;

    core _core (
        .clk(clk),
        .init(init),
        .init_pc(init_pc),
        .init_sp(init_sp),
        .rst_aL(rst_aL),

        // ICACHE MEM CTRL REQUEST
        .icache_mem_ctrl_req_valid(icache_mem_ctrl_req_valid),
        .icache_mem_ctrl_req_block_addr(icache_mem_ctrl_req_block_addr),
        .icache_mem_ctrl_req_ready(icache_mem_ctrl_req_ready),

        // ICACHE MEM CTRL RESPONSE
        .icache_mem_ctrl_resp_valid(icache_mem_ctrl_resp_valid),
        .icache_mem_ctrl_resp_block_data(icache_mem_ctrl_resp_block_data),

        // DCACHE MEM CTRL REQUEST
        .dcache_mem_ctrl_req_valid(dcache_mem_ctrl_req_valid),
        .dcache_mem_ctrl_req_type(dcache_mem_ctrl_req_type),
        .dcache_mem_ctrl_req_block_addr(dcache_mem_ctrl_req_block_addr),
        .dcache_mem_ctrl_req_block_data(dcache_mem_ctrl_req_block_data),  // for writes
        .dcache_mem_ctrl_req_ready(dcache_mem_ctrl_req_ready),

        // DCACHE MEM CTRL RESPONSE
        .dcache_mem_ctrl_resp_valid(dcache_mem_ctrl_resp_valid),
        .dcache_mem_ctrl_resp_block_data(dcache_mem_ctrl_resp_block_data),

        // ARF out - for checking archiectural state
        .ARF_OUT(ARF_OUT)
    );

    mem_ctrl _mem_ctrl (
        // FROM ICACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE) (always read)
        .icache_req_valid(icache_mem_ctrl_req_valid),
        .icache_req_block_addr(icache_mem_ctrl_req_block_addr),
        .icache_req_ready(icache_mem_ctrl_req_ready),

        // FROM MEM_CTRL TO ICACHE (RESPONSE) (LATENCY-SENSITIVE)
        .icache_resp_valid(icache_mem_ctrl_resp_valid),
        .icache_resp_block_data(icache_mem_ctrl_resp_block_data),

        // FROM DCACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
        .dcache_req_valid(dcache_mem_ctrl_req_valid),
        .dcache_req_type(dcache_mem_ctrl_req_type),
        .dcache_req_block_addr(dcache_mem_ctrl_req_block_addr),
        .dcache_req_block_data(dcache_mem_ctrl_req_block_data), // for writes
        .dcache_req_ready(dcache_mem_ctrl_req_ready),

        // FROM MEM_CTRL TO DCACHE (RESPONSE) (LATENCY-SENSITIVE)
        .dcache_resp_valid(dcache_mem_ctrl_resp_valid),
        .dcache_resp_block_data(dcache_mem_ctrl_resp_block_data),

        // FROM MEM_CTRL TO MAIN_MEM (REQUEST) (LATENCY-SENSITIVE)
        .mem_req_valid(mem_req_valid),
        .mem_req_cache_type(mem_req_cache_type),
        .mem_req_type(mem_req_type),
        .mem_req_block_addr(mem_req_block_addr),
        .mem_req_block_data(mem_req_block_data), // for writes

        // FROM MAIN_MEM TO MEM_CTRL (RESPONSE) (LATENCY-SENSITIVE)
        .mem_resp_valid(mem_resp_valid),
        .mem_resp_cache_type(mem_resp_cache_type),
        .mem_resp_block_data(mem_resp_block_data) // for reads
    );

    main_mem #(
        .HIGHEST_INSTR_BLOCK_ADDR(HIGHEST_INSTR_BLOCK_ADDR)
    ) _main_mem (
        .clk(clk),
        .init(init),
        .init_main_mem_state(init_main_mem_state),
        .rst_aL(rst_aL),

        // FROM MEM_CTRL TO MAIN_MEM (REQUEST) (LATENCY-SENSITIVE)
        .req_valid(mem_req_valid),
        .req_cache_type(mem_req_cache_type), // 0: icache, 1: dcache
        .req_type(mem_req_type), // 0: read, 1: write
        .req_block_addr(mem_req_block_addr),
        .req_block_data(mem_req_block_data), // for writes

        // FROM MAIN_MEM TO MEM_CTRL (RESPONSE) (LATENCY-SENSITIVE)
        .resp_valid(mem_resp_valid),
        .resp_cache_type(mem_resp_cache_type),
        .resp_block_data(mem_resp_block_data) // for reads
    );
endmodule