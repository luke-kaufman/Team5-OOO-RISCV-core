`ifnd

'incl

module cache #(
    parameter cache_type_t CACHE_TYPE
) (
    input logic clk,
    input logic rst_aL,

    // FROM PIPELINE TO CACHE (REQUEST) (LATENCY-SENSITIVE)
    input logic pipeline_req_valid,
    input req_type_t pipeline_req_type, // 0: read, 1: write
    input req_width_t pipeline_req_wr_width, // 0: byte, 1: halfword, 2: word (only for writes)
    input addr_t pipeline_req_addr,
    input word_t pipeline_req_wr_data, // (only for writes)

    // FROM CACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
    output logic mem_ctrl_req_valid,
    output req_type_t mem_ctrl_req_type, // 0: read, 1: write (only for dcache)
    output main_mem_block_addr_t mem_ctrl_req_block_addr,
    output block_data_t mem_ctrl_req_block_data, // (only for dcache)
    input logic mem_ctrl_req_ready, // (icache has priority. for icache, if valid is true, then ready is also true.)

    // FROM MEM_CTRL TO CACHE (RESPONSE) (LATENCY-SENSITIVE)
    input logic mem_ctrl_resp_valid,
    input block_data_t mem_ctrl_resp_block_data,

    // FROM CACHE TO PIPELINE (RESPONSE)
    output logic pipeline_resp_valid,
    output word_t pipeline_resp_rd_data
);
    wire tag_array_csb = pipeline_req_valid | mem_ctrl_resp_valid;
    wire tag_array_web = mem_ctrl_resp_valid;
    wire tag_array_wmask =
    wire tag_array_dout;
    
    // Tag array
    sram_64x48_1rw_wsize24 tag_array (
        .clk0(clk),
        .csb0(~tag_array_csb), // active low
        .web0(~tag_array_web), // active low
        .rst_aL(rst_aL),
        .wmask0(),
        .addr0(),
        .din0(),
        .dout0(tag_array_dout)
    );

    // Data array
    if (CACHE_TYPE == ICACHE) begin
        sram_64x128_1rw_wsize64 icache_data_array (
            .clk0(clk),
            .csb0(),
            .web0(),
            .rst_aL(rst_aL),
            .wmask0(),
            .addr0(),
            .din0(),
            .dout0()
        );
    end else if (CACHE_TYPE == DCACHE) begin
        sram_64x128_1rw_wsize8 dcache_data_array (
            .clk0(clk),
            .csb0(),
            .web0(),
            .rst_aL(rst_aL),
            .wmask0(),
            .addr0(),
            .din0(),
            .dout0()
        );
    end


endmodule

// writethrough

// dcache, store, hit
// pipeline_resp_valid is true
// NOTE: this seems to be correct for now, but is a potential source of bugs in the future (because of latency-sensitivity).
// mem_ctrl_req_ready can get delayed at most 1 cycle

// dcache, store, miss
// pipeline_resp_valid is false until mem_ctrl_resp_valid is true
