`ifndef MAIN_MEM_V
`define MAIN_MEM_V

`include "misc/global_defs.svh"

// NOTE: this version is pipelined
// TODO: also experiment with the non-pipelined version
module main_mem #(
    parameter int unsigned N_DELAY_CYCLES = 5
) (
    input logic clk,
    input logic init,
    input logic rst_aL,
    input block_data_t init_main_mem_state[`MAIN_MEM_N_BLOCKS],

    // FROM MEM_CTRL TO MAIN_MEM (REQUEST) (LATENCY-SENSITIVE)
    input logic req_valid,
    input cache_type_t req_cache_type, // 0: icache, 1: dcache
    input req_type_t req_type, // 0: read, 1: write
    input main_mem_block_addr_t req_block_addr,
    input block_data_t req_block_data, // for writes

    // FROM MAIN_MEM TO MEM_CTRL (RESPONSE) (LATENCY-SENSITIVE)
    output logic resp_valid,
    output cache_type_t resp_cache_type,
    output block_data_t resp_block_data // for reads
);
    block_data_t mem[`MAIN_MEM_N_BLOCKS];

    // Delay mechanism using a shift register
    typedef struct packed {
        logic valid;
        req_type_t req_type;
        cache_type_t cache_type;
        main_mem_block_addr_t addr;
        block_data_t data;
    } main_mem_req_t;

    main_mem_req_t req_pipeline[N_DELAY_CYCLES];

    // Pipeline processing
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin // TODO: figure out the testbench strategy for init/rst_aL
        if (init) begin
            for (int i = 0; i < N_DELAY_CYCLES; i++) begin
                req_pipeline[i] <= 0;
            end
            resp_valid <= 0;
            resp_cache_type <= cache_type_t'(0);
            resp_block_data <= 0;
            mem <= init_main_mem_state;
        end else if (!rst_aL) begin
            // Resetting the pipeline
            for (int i = 0; i < N_DELAY_CYCLES; i++) begin
                req_pipeline[i] <= 0;
            end
            resp_valid <= 0;
            resp_cache_type <= cache_type_t'(0);
            resp_block_data <= 0;
            // for (int i = 0; i < `MAIN_MEM_N_BLOCKS; i++) begin // TODO: double-check if this is correct
            //     mem[i] <= 0;
            // end
        end else begin
            // Shift the pipeline
            for (int i = N_DELAY_CYCLES-1; i > 0; i--) begin
                req_pipeline[i] <= req_pipeline[i-1];
            end

            // Capture new request
            req_pipeline[0] <= '{
                valid: req_valid,
                req_type: req_type,
                cache_type: req_cache_type,
                addr: req_block_addr,
                data: req_block_data
            };

            // Handle the oldest request in the pipeline
            resp_valid <= req_pipeline[N_DELAY_CYCLES-1].valid;
            resp_cache_type <= req_pipeline[N_DELAY_CYCLES-1].cache_type;
            if (req_pipeline[N_DELAY_CYCLES-1].valid) begin
                if (req_pipeline[N_DELAY_CYCLES-1].req_type == WRITE) begin
                    mem[req_pipeline[N_DELAY_CYCLES-1].addr] <= req_pipeline[N_DELAY_CYCLES-1].data;
                end
                resp_block_data <= mem[req_pipeline[N_DELAY_CYCLES-1].addr];
            end else begin
                resp_block_data <= 0;
            end
        end
    end
endmodule

`endif
