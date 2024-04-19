`ifndef MAIN_MEM_V
`define MAIN_MEM_V
`include "misc/global_defs.svh"

// NOTE: this version is pipelined
// TODO: also experiment with the non-pipelined version
module main_mem_old #(
    parameter int unsigned N_DELAY_CYCLES = 5,
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned ADDR_WIDTH = `ADDR_WIDTH
) (
    input wire clk,
    input wire rst_aL,
    // FROM CORE TO MAIN MEM (RECEIVE)
    input wire recv_core_valid,
    input wire recv_core_wr_en,
    input wire [`ADDR_WIDTH-1:0] recv_core_addr,
    input wire [`WORD_WIDTH-1:0] recv_core_data,
    // FROM MAIN MEM TO CORE (SEND)
    output wire send_core_valid,
    output wire send_core_lsu_aL_ifu_aH,
    output wire [`ICACHE_DATA_BLOCK_SIZE-1:0] send_core_data
);
    // Memory storage
    logic [DATA_WIDTH-1:0] memory [(1 << ADDR_WIDTH)-1:0];

    always_ff @(posedge clk or negedge rst_aL) begin
        if (!rst_aL) begin
            foreach (main_mem[i]) begin
                main_mem[i] <= 8'h00;
            end
        end else if (recv_core_valid) begin
            // #5 // delay for 5 ns
            repeat (N_DELAY_CYCLES) @(negedge clk);
            for (int i = 0; i < recv_core_size; i++) begin
                send_core_data[(i+1)*8 : i*8] <= main_mem[recv_core_addr + i];
            end
            send_en_core <= 1'b1;
            send_core_lsu_aL_ifu_aH <= recv_core_lsu_aL_ifu_aH;
        end
        else begin
            send_en_core <= 1'b0;
            send_core_lsu_aL_ifu_aH <= 0;
            send_core_data <= 0;
        end
    end
endmodule
`endif