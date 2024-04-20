`ifndef CACHE_V
`define CACHE_V

`include "misc/global_defs.svh"

module cache #(
    parameter cache_type_t CACHE_TYPE,
    parameter int unsigned N_SETS,
    localparam int unsigned N_OFFSET_BITS = $clog2(`BLOCK_DATA_WIDTH),
    localparam int unsigned N_INDEX_BITS = $clog2(N_SETS),
    localparam int unsigned N_TAG_BITS = `ADDR_WIDTH - N_OFFSET_BITS - N_INDEX_BITS
) (
    input logic clk,
    input logic rst_aL,
    input logic flush, // TODO: do we have to flush anything in cache? (we don't need to flush the lfsr)

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
    // wire tag_array_wmask =
    struct packed {
        logic way1_valid;
        logic [N_TAG_BITS-1:0] way1_tag;
        logic way0_valid;
        logic [N_TAG_BITS-1:0] way0_tag;
    } tag_array_dout;
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

    struct packed {
        logic [`BLOCK_DATA_WIDTH-1:0] way0_data;
        logic [`BLOCK_DATA_WIDTH-1:0] way1_data;
    } data_array_dout;
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
            .dout0(data_array_dout)
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

    wire [N_TAG_BITS-1:0] pipeline_req_addr_tag;
    wire [N_INDEX_BITS-1:0] pipeline_req_addr_index;
    wire [N_OFFSET_BITS-1:0] pipeline_req_addr_offset;
    assign {pipeline_req_addr_tag, pipeline_req_addr_index, pipeline_req_addr_offset} = pipeline_req_addr;
    wire sel_way0 = tag_array_dout.way0_valid & (tag_array_dout.way0_tag == pipeline_req_addr_tag);
    wire sel_way1 = tag_array_dout.way1_valid & (tag_array_dout.way1_tag == pipeline_req_addr_tag);


    lfsr_8bit lfsr (
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .out_bit()
    );

    // truth table
    // WAY1V WAY0V we_mask[1] we_mask[0]
    // 0     0     0          1          both invalid just write to 0
    // 0     1     1          0          if way 0 valid, write to way 1
    // 1     0     0          1          if way 1 valid, write to way 0
    // 1     1     1/2        1/2        randomly evict

    
endmodule

`endif

// writethrough

// dcache, store, hit
// pipeline_resp_valid is true
// NOTE: this seems to be correct for now, but is a potential source of bugs in the future (because of latency-sensitivity).
// mem_ctrl_req_ready can get delayed at most 1 cycle

// dcache, store, miss
// pipeline_resp_valid is false until mem_ctrl_resp_valid is true
