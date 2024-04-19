`include "misc/global_defs.svh"

module load_store_simple #(

) (
    input logic clk,
    input logic rst_aL,

    input wire csb0_in,
    // FROM MAIN MEM TO LSU (RECEIVE)
    input wire recv_main_mem_valid,
    input wire recv_main_mem_lsu_aL_ifu_aH,
    input wire [`WORD_WIDTH-1:0] recv_main_mem_data,
    // FROM LSU TO MAIN MEM (SEND)
    output wire send_en_main_mem,
    output wire send_main_mem_lsu_aL_ifu_aH,
    output wire [`ADDR_WIDTH-1:0] send_main_mem_addr,
    output wire [2:0] send_size_main_mem, // {$block, Word, Halfword, Byte}
    output wire [`DCACHE_DATA_BLOCK_SIZE-1:0] send_main_mem_data

    // dispatch interface: ready & valid
    output wire dispatch_ready,
    input wire dispatch_valid,
    input wire iiq_entry_t dispatch_data,

    // alu broadcast:
    input wire alu_broadcast_valid,
    input wire rob_id_t alu_broadcast_rob_id,
    input wire reg_data_t alu_broadcast_reg_data
);
    cache #(

    ) dcache (
        .clk(clk),
        .rst_aL(rst_aL),
        .addr(addr),
        .PC_addr(PC_addr),
        .we_aL(we_aL),
        .dcache_is_ST(dcache_is_ST),  // if reason for d-cache access is to store something (used for dirty bit)
        .write_data(write_data),  // 64 for icache (DRAMresponse) 8 bits for dcache
        .csb0_in(csb0_in),
        .selected_data_way(selected_data_way),
        .cache_hit(cache_hit)
    );
endmodule