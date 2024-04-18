`ifndef MAIN_MEM_V
`define MAIN_MEM_V
`include "misc/global_defs.svh"

module main_mem (
    input wire clk, // input wire 
    input wire rst_aL, // input wire 
    // FROM CORE TO MAIN MEM (RECEIVE)
    input wire recv_core_valid, // input wire 
    input wire [`ADDR_WIDTH-1:0] recv_core_addr, // input wire
    input wire [2:0] recv_size_core, // input {$block, Word, Halfword, Byte} 
    input wire [`WORD_WIDTH-1:0] recv_core_data, // input wire 
    // FROM MAIN MEM TO CORE (SEND)
    output wire send_en_core, // output wire 
    output wire send_core_lsu_aL_ifu_aH, // output wire 
    output wire [`ADDR_WIDTH-1:0] send_core_addr,  // if main mem data is meant for LSU or IFU
    output wire [2:0] send_size_core, // output wire 
    output wire [`ICACHE_DATA_BLOCK_SIZE-1:0] send_core_data // output wire 
);

    // reg file or some other magic memory thing?

endmodule
`endif 