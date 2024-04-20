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
    // TODO: how to use mem_ctrl_req_ready?

    // FROM MEM_CTRL TO CACHE (RESPONSE) (LATENCY-SENSITIVE)
    input logic mem_ctrl_resp_valid,
    input block_data_t mem_ctrl_resp_block_data,

    // FROM CACHE TO PIPELINE (RESPONSE)
    output logic pipeline_resp_valid,
    output word_t pipeline_resp_rd_data
);
    typedef struct packed {
        logic way1_valid;
        logic [N_TAG_BITS-1:0] way1_tag;
        logic way0_valid;
        logic [N_TAG_BITS-1:0] way0_tag;
    } tag_array_word_t;

    typedef struct packed {
        logic [`BLOCK_DATA_WIDTH-1:0] way0_data;
        logic [`BLOCK_DATA_WIDTH-1:0] way1_data;
    } data_array_word_t;

    wire random_way;
    lfsr_8bit lfsr (
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .out_bit(random_way)
    );

    wire [N_TAG_BITS-1:0] pipeline_req_addr_tag;
    wire [N_INDEX_BITS-1:0] pipeline_req_addr_index;
    wire [N_OFFSET_BITS-1:0] pipeline_req_addr_offset;
    assign {pipeline_req_addr_tag, pipeline_req_addr_index, pipeline_req_addr_offset} = pipeline_req_addr;

    wire tag_array_csb = mem_ctrl_resp_valid | pipeline_req_valid;
    wire tag_array_web = mem_ctrl_resp_valid;
    wire [1:0] tag_array_wmask = {random_way == 1'b1, random_way == 1'b0};
    wire [N_INDEX_BITS-1:0] tag_array_addr = pipeline_req_addr_index;
    tag_array_word_t tag_array_din = '{
        .way1_valid: 1'b1,                // should be masked out if this is not the random way selected
        .way1_tag: pipeline_req_addr_tag, // should be masked out if this is not the random way selected
        .way0_valid: 1'b1,                // should be masked out if this is not the random way selected
        .way0_tag: pipeline_req_addr_tag  // should be masked out if this is not the random way selected
    };
    tag_array_word_t tag_array_dout;

    // Tag array
    sram_64x48_1rw_wsize24 tag_array (
        .clk0(clk),
        .rst_aL(rst_aL),
        .csb0(~tag_array_csb), // active low
        .web0(~tag_array_web), // active low
        .wmask0(tag_array_wmask),
        .addr0(tag_array_addr),
        .din0(tag_array_din),
        .dout0(tag_array_dout)
    );

    logic [N_TAG_BITS-1:0] pipeline_req_addr_tag_latched;
    always_ff @(posedge clk) begin // TODO: no negedge rst_aL in the sensitivity list? (copied behavioral sram)
        if (!rst_aL) begin
            pipeline_req_addr_tag_latched <= 0;
        end else begin
            pipeline_req_addr_tag_latched <= pipeline_req_addr_tag;
        end
    end

    wire sel_way0 = tag_array_dout.way0_valid & (tag_array_dout.way0_tag == pipeline_req_addr_tag_latched);
    wire sel_way1 = tag_array_dout.way1_valid & (tag_array_dout.way1_tag == pipeline_req_addr_tag_latched);

    wire data_array_csb = mem_ctrl_resp_valid | pipeline_req_valid;
    wire data_array_web = mem_ctrl_resp_valid | (pipeline_req_valid & (pipeline_req_type == WRITE));
    wire [1:0]  icache_data_array_wmask = {random_way == 1'b1, random_way == 1'b0};
    wire [15:0] dcache_data_array_wmask = {
        {8{random_way == 1'b1}} | ({8{sel_way1}} & (1 << pipeline_req_addr_offset[2:0])),
        {8{random_way == 1'b0}} | ({8{sel_way0}} & (1 << pipeline_req_addr_offset[2:0]))
    };
    wire [N_INDEX_BITS-1:0] data_array_addr = pipeline_req_addr_index;
    data_array_word_t data_array_din = '{
        way0_data: mem_ctrl_resp_valid               ? mem_ctrl_resp_block_data        :
                   pipeline_req_wr_width == BYTE     ? {8{pipeline_req_wr_data[7:0]}}  :
                   pipeline_req_wr_width == HALFWORD ? {4{pipeline_req_wr_data[15:0]}} :
                   pipeline_req_wr_width == WORD     ? {2{pipeline_req_wr_data}}       :
                                                       {64{1'b0}}                      ,
        way1_data: mem_ctrl_resp_valid               ? mem_ctrl_resp_block_data        :
                   pipeline_req_wr_width == BYTE     ? {8{pipeline_req_wr_data[7:0]}}  :
                   pipeline_req_wr_width == HALFWORD ? {4{pipeline_req_wr_data[15:0]}} :
                   pipeline_req_wr_width == WORD     ? {2{pipeline_req_wr_data}}       :
                                                       {64{1'b0}}
    };
    data_array_word_t data_array_dout;

    // Data array
    if (CACHE_TYPE == ICACHE) begin
        sram_64x128_1rw_wsize64 icache_data_array (
            .clk0(clk),
            .rst_aL(rst_aL),
            .csb0(~data_array_csb), // active low
            .web0(~data_array_web), // active low
            .wmask0(icache_data_array_wmask),
            .addr0(data_array_addr),
            .din0(data_array_din),
            .dout0(data_array_dout)
        );
    end else if (CACHE_TYPE == DCACHE) begin
        sram_64x128_1rw_wsize8 dcache_data_array (
            .clk0(clk),
            .rst_aL(rst_aL),
            .csb0(~data_array_csb), // active low
            .web0(~data_array_web), // active low
            .wmask0(dcache_data_array_wmask),
            .addr0(data_array_addr),
            .din0(data_array_din),
            .dout0(data_array_dout)
        );
    end

    assign mem_ctrl_req_valid =

endmodule

`endif

// writethrough

// dcache, store, hit
// pipeline_resp_valid is true
// NOTE: this seems to be correct for now, but is a potential source of bugs in the future (because of latency-sensitivity).
// mem_ctrl_req_ready can get delayed at most 1 cycle

// dcache, store, miss
// pipeline_resp_valid is false until mem_ctrl_resp_valid is true
