`ifndef CACHE_V
`define CACHE_V

`include "misc/global_defs.svh"
`include "misc/lfsr_8bit.v"
`include "sram/tag_array_sram.v"
`include "sram/dcache_data_sram.v"
`include "sram/icache_data_sram.v"

module cache #(
    parameter cache_type_t CACHE_TYPE,
    parameter int unsigned N_SETS,
    localparam int unsigned N_OFFSET_BITS = $clog2(`BLOCK_DATA_WIDTH / 8),
    localparam int unsigned N_INDEX_BITS = $clog2(N_SETS),
    localparam int unsigned N_TAG_BITS = `ADDR_WIDTH - N_OFFSET_BITS - N_INDEX_BITS
) (
    input logic clk,
    input logic init,
    input logic rst_aL,
    input logic flush, // TODO: do we have to flush anything in cache? (we don't need to flush the lfsr)

    // FROM PIPELINE TO CACHE (REQUEST) (LATENCY-SENSITIVE)
    input logic pipeline_req_valid,
    input req_type_t pipeline_req_type, // 0: read, 1: write
    input req_width_t pipeline_req_width, // 0: byte, 1: halfword, 2: word (only for dcache)
    input addr_t pipeline_req_addr,
    input word_t pipeline_req_wr_data, // (only for writes)

    // FROM CACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
    output logic mem_ctrl_req_valid,
    output req_type_t mem_ctrl_req_type, // 0: read, 1: write
    output main_mem_block_addr_t mem_ctrl_req_block_addr,
    output block_data_t mem_ctrl_req_block_data, // (only for dcache and stores)
    input logic mem_ctrl_req_ready, // (icache has priority. for icache, if valid is true, then ready is also true.)

    // FROM MEM_CTRL TO CACHE (RESPONSE) (LATENCY-SENSITIVE)
    input logic mem_ctrl_resp_valid,
    input block_data_t mem_ctrl_resp_block_data,

    // FROM CACHE TO PIPELINE (RESPONSE)
    output logic pipeline_resp_valid, // cache hit
    output word_t pipeline_resp_rd_data
);
    typedef struct packed {
        logic way1_valid;
        logic [N_TAG_BITS-1:0] way1_tag;
        logic way0_valid;
        logic [N_TAG_BITS-1:0] way0_tag;
    } tag_array_set_t;

    typedef struct packed {
        logic [`BLOCK_DATA_WIDTH-1:0] way0_data;
        logic [`BLOCK_DATA_WIDTH-1:0] way1_data;
    } data_array_set_t;

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

    tag_array_set_t tag_array_dout;
    wire tag_array_csb = mem_ctrl_resp_valid | pipeline_req_valid;
    wire tag_array_web = mem_ctrl_resp_valid;
    wire [1:0] tag_array_wmask = {
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b00) ? 2'b01                                           :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b01) ? 2'b10                                           :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b10) ? 2'b01                                           :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b11) ? {random_way, ~random_way}                       :
                                                                            0
    };
    wire [N_INDEX_BITS-1:0] tag_array_addr = pipeline_req_addr_index;
    tag_array_set_t tag_array_din = '{
        way1_valid: 1'b1,                // should be masked out if this is not the random way selected
        way1_tag: pipeline_req_addr_tag, // should be masked out if this is not the random way selected
        way0_valid: 1'b1,                // should be masked out if this is not the random way selected
        way0_tag: pipeline_req_addr_tag  // should be masked out if this is not the random way selected
    };

    // Tag array
    sram_64x48_1rw_wsize24 tag_array (
        .clk0(clk),
        .init(init),
        .rst_aL(rst_aL),
        .csb0(~tag_array_csb), // active low
        .web0(~tag_array_web), // active low
        .wmask0(tag_array_wmask),
        .addr0(tag_array_addr),
        .din0(tag_array_din),
        .dout0(tag_array_dout)
    );

    wire mem_ctrl_req_success = mem_ctrl_req_valid & mem_ctrl_req_ready;

    logic pipeline_req_valid_latched;
    req_type_t pipeline_req_type_latched;
    req_width_t pipeline_req_width_latched;
    logic [N_TAG_BITS-1:0] pipeline_req_addr_tag_latched;
    logic [N_INDEX_BITS-1:0] pipeline_req_addr_index_latched;
    logic [N_OFFSET_BITS-1:0] pipeline_req_addr_offset_latched;
    logic pipeline_resp_was_valid; // skid preventing latch
    logic mem_ctrl_resp_waiting;   // double request preventing latch
    // TODO: does this kind of always_ff cause any problems?
    // TODO: no negedge rst_aL in the sensitivity list? (copied behavioral sram)
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init | !rst_aL) begin
            pipeline_req_valid_latched <= 0;
            pipeline_req_type_latched <= req_type_t'(0);
            pipeline_req_width_latched <= req_width_t'(0);
            pipeline_req_addr_tag_latched <= 0;
            pipeline_req_addr_index_latched <= 0;
            pipeline_req_addr_offset_latched <= 0;
            pipeline_resp_was_valid <= 0;
            mem_ctrl_resp_waiting <= 0;
        end else begin
            pipeline_req_valid_latched <= pipeline_req_valid;
            pipeline_req_type_latched <= pipeline_req_type;
            pipeline_req_width_latched <= pipeline_req_width;
            pipeline_req_addr_tag_latched <= pipeline_req_addr_tag;
            pipeline_req_addr_index_latched <= pipeline_req_addr_index;
            pipeline_req_addr_offset_latched <= pipeline_req_addr_offset;
            if (pipeline_resp_was_valid) begin
                pipeline_resp_was_valid <= 0;
            end else if (pipeline_resp_valid) begin
                pipeline_resp_was_valid <= 1;
            end else begin
                pipeline_resp_was_valid <= pipeline_resp_was_valid;
            end
            if (mem_ctrl_req_success) begin
                mem_ctrl_resp_waiting <= 1;
            end else if (mem_ctrl_resp_valid) begin
                mem_ctrl_resp_waiting <= 0;
            end else begin
                mem_ctrl_resp_waiting <= mem_ctrl_resp_waiting;
            end
        end
    end

    wire sel_way0 = tag_array_dout.way0_valid & (tag_array_dout.way0_tag == pipeline_req_addr_tag_latched);
    wire sel_way1 = tag_array_dout.way1_valid & (tag_array_dout.way1_tag == pipeline_req_addr_tag_latched);
    wire tag_array_hit = sel_way0 | sel_way1; // NOTE: not guarded by pipeline_req_valid_latched and mem_ctrl_resp_waiting
    assign mem_ctrl_req_valid = pipeline_req_valid_latched &
                                ~mem_ctrl_resp_waiting     &
                                (~tag_array_hit | (pipeline_req_type_latched == WRITE)); // write-through
    assign mem_ctrl_req_type = ~tag_array_hit ? READ : // all misses should do a refill first
                                                pipeline_req_type_latched; // write-through
    assign mem_ctrl_req_block_addr = {pipeline_req_addr_tag_latched, pipeline_req_addr_index_latched};
    assign mem_ctrl_req_block_data = sel_way0 ? data_array_dout.way0_data :
                                     sel_way1 ? data_array_dout.way1_data :
                                                0; // since miss, a read request is being made and this value is not used

    assign pipeline_resp_valid = pipeline_req_valid_latched &
                                 ~pipeline_resp_was_valid   &
                                 tag_array_hit;
    assign pipeline_resp_rd_data = sel_way0 ? data_array_dout.way0_data[8*pipeline_req_addr_offset_latched+:32] :
                                   sel_way1 ? data_array_dout.way1_data[8*pipeline_req_addr_offset_latched+:32] :
                                              0; // since miss, a read request is being made and this value is not used

    wire data_array_csb = mem_ctrl_resp_valid | pipeline_req_valid;
    wire data_array_web = mem_ctrl_resp_valid | (pipeline_req_valid & (pipeline_req_type == WRITE));
    wire [1:0] icache_data_array_wmask = {
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b00) ? 2'b01                                           :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b01) ? 2'b10                                           :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b10) ? 2'b01                                           :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b11) ? {random_way, ~random_way}                       :
                                                                            0
    };
    // NOTE: we assume that the pipeline already force aligns the stores to the correct offset!
    wire [7:0] dcache_data_array_store_wmask = pipeline_req_width == BYTE     ? 1'b1 << pipeline_req_addr_offset[2:0]      :
                                               pipeline_req_width == HALFWORD ? 2'b11 << pipeline_req_addr_offset[2:0]     :
                                               pipeline_req_width == WORD     ? 4'b1111 << pipeline_req_addr_offset[2:0]   :
                                                                                0                                          ;
    wire [15:0] dcache_data_array_wmask = {
        {8{random_way == 1'b1}} | ({8{sel_way1}} & dcache_data_array_store_wmask),
        {8{random_way == 1'b0}} | ({8{sel_way0}} & dcache_data_array_store_wmask)
    };
    wire [N_INDEX_BITS-1:0] data_array_addr = pipeline_req_addr_index;
    data_array_set_t data_array_din = '{
        way0_data: mem_ctrl_resp_valid            ? mem_ctrl_resp_block_data                   :
                   pipeline_req_width == BYTE     ? {8{pipeline_req_wr_data[7:0]}}             :
                   pipeline_req_width == HALFWORD ? {4{pipeline_req_wr_data[15:0]}}            :
                   pipeline_req_width == WORD     ? {2{pipeline_req_wr_data}}                  :
                                                    0                                          ,
        way1_data: mem_ctrl_resp_valid            ? mem_ctrl_resp_block_data                   :
                   pipeline_req_width == BYTE     ? {8{pipeline_req_wr_data[7:0]}}             :
                   pipeline_req_width == HALFWORD ? {4{pipeline_req_wr_data[15:0]}}            :
                   pipeline_req_width == WORD     ? {2{pipeline_req_wr_data}}                  :
                                                    0
    };
    data_array_set_t data_array_dout;

    // Data array
    if (CACHE_TYPE == ICACHE) begin
        sram_64x128_1rw_wsize64 icache_data_array (
            .clk0(clk),
            .init(init),
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
            .init(init),
            .rst_aL(rst_aL),
            .csb0(~data_array_csb), // active low
            .web0(~data_array_web), // active low
            .wmask0(dcache_data_array_wmask),
            .addr0(data_array_addr),
            .din0(data_array_din),
            .dout0(data_array_dout)
        );
    end

    // assertions
    // sel_way0 and sel_way1 should not be true at the same time

endmodule

`endif

// writethrough

// dcache, store, hit
// pipeline_resp_valid is true
// mem_ctrl_req_valid is true ()
// NOTE: this seems to be correct for now, but is a potential source of bugs in the future (because of latency-sensitivity).
// mem_ctrl_req_ready can get delayed at most 1 cycle

// dcache, store, miss
// pipeline_resp_valid is false until mem_ctrl_resp_valid is true
// TODO: first, cache refill, then, write-through (main_mem first-write-then-read request type?)
