`ifndef MAIN_MEM_V
`define MAIN_MEM_V
`include "misc/global_defs.svh"

module main_mem #(
    parameter ADDR_SPACE_BITS = `ADDR_WIDTH
)(
    input wire clk,  
    input wire rst_aL,  
    // FROM CORE TO MAIN MEM (RECEIVE)
    input wire recv_core_valid,  
    input wire recv_core_lsu_aL_ifu_aH,  
    input wire [`ADDR_WIDTH-1:0] recv_core_addr, 
    input wire [2:0] recv_size_core, // {$block, Word, Halfword, Byte} 
    input wire [`WORD_WIDTH-1:0] recv_core_data,  
    // FROM MAIN MEM TO CORE (SEND)
    output wire send_en_core,  
    output wire send_core_lsu_aL_ifu_aH,  
    output wire [`ADDR_WIDTH-1:0] send_core_addr, 
    output wire [2:0] send_size_core,  
    output wire [`ICACHE_DATA_BLOCK_SIZE-1:0] send_core_data  
);

    // actual main mem
    reg [7:0] main_mem [0:ADDR_SPACE_BITS-1];

    always_ff @(posedge clk || negedge rst_aL) begin :
        if (!rst_aL) begin
            foreach (main_mem[i]) begin
                main_mem[i] <= 8'h00;
            end
        end else if (recv_core_valid) begin
            for (int i = 0; i < recv_size_core; i++) begin
                send_core_data[(i+1)*8 : i*8] <= main_mem[recv_core_addr + i];
            end
            send_en_core <= 1'b1;
            send_core_lsu_aL_ifu_aH <= recv_core_lsu_aL_ifu_aH;
            send_core_addr <= recv_core_addr;
            send_size_core <= recv_size_core;
        end
        else begin
            send_en_core <= 1'b0;
            send_core_lsu_aL_ifu_aH <= 0;
            send_core_addr <= 0;
            send_size_core <= 3'b000;
            send_core_data <= 0;
        end
    end
endmodule
`endif 