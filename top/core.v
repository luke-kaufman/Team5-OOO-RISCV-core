`ifndef CORE_V
`define CORE_V

`include "frontend/fetch/ifu.v"
`include "frontend/dispatch/dispatch.sv"
`include "misc/global_defs.svh"

module core #() (
    input wire clk,
    input wire rst_aL,
    
    // Main memory interaction for both LOADS and ICACHE (rd only)
    input wire                               recv_main_mem_valid;
    input wire                               recv_main_mem_addr;
    input wire                               recv_main_mem_lsu_aL_ifu_aH;  // if main mem data is meant for LSU or IFU
    input wire [2:0]                         recv_size_main_mem; // {Word, Halfword, Byte}
    input wire [`ICACHE_DATA_BLOCK_SIZE-1:0] recv_main_mem_data;
    
    input wire csb0_in=1;  // testing icache on

    // Main memory interaction only for STORES (wr only)
    output wire                   send_en_main_mem;
    output wire [`ADDR_WIDTH-1:0] send_main_mem_addr;
    output wire [2:0]             send_size_main_mem; // {Word, Halfword, Byte}
    output wire [`WORD_WIDTH-1:0] send_main_mem_data; // write up to a word
);  
    // Inter-Stage connects
    wire [`ADDR_WIDTH-1:0] recovery_PC=0;/*ALU->IFU*/
    wire                   recovery_PC_valid=0;/*ALU->IFU*/ // a.k.a. branch prediction valid
    wire                   backend_stall=0; //? ambiguous - could be from any stage (IIQ full, LSQ full, etc.)
    wire                   dispatch_ready=0;/*IFU->DIS*/

    ifu ifu_dut (
        .clk(clk),
        .rst_aL(rst_aL),
        .recovery_PC(recovery_PC),
        .recovery_PC_valid(recovery_PC_valid),
        .backend_stall(backend_stall),
        .recv_main_mem_data(recv_main_mem_data),
        .recv_main_mem_valid(recv_main_mem_valid),
        .recv_main_mem_addr(recv_main_mem_addr)
        .dispatch_ready(dispatch_ready),
        .csb0_in(csb0_in)
    );

endmodule
`endif CORE_V