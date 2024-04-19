`include "misc/global_defs.svh"

module load_store_simple #(

) (
    input logic clk,
    input logic rst_aL,

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
        .d_cache_is_ST(d_cache_is_ST),  // if reason for d-cache access is to store something (used for dirty bit)
        .write_data(write_data),  // 64 for icache (DRAMresponse) 8 bits for dcache
        .csb0_in(csb0_in),
        .selected_data_way(selected_data_way),
        .cache_hit(cache_hit)
    );
endmodule