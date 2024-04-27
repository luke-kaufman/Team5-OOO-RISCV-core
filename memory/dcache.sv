`ifndef DCACHE_V
`define DCACHE_V

`include "misc/global_defs.svh"
`include "misc/lfsr_8bit.v"
`include "sram/tag_array_sram.v"
`include "sram/dcache_data_sram.v"
`include "sram/icache_data_sram.v"

module dcache #(
    parameter int unsigned VERBOSE = 0,
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
    input cache_type_t pipeline_req_cache_type,
    input req_type_t pipeline_req_type, // 0: read, 1: write
    input req_width_t pipeline_req_width, // 0: byte, 1: halfword, 2: word (only for dcache)
    input dcache_addr_t pipeline_req_addr,
    input wire word_t pipeline_req_wr_data, // (only for writes)

    // FROM CACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
    output logic mem_ctrl_req_valid,
    output req_type_t mem_ctrl_req_type, // 0: read, 1: write
    output main_mem_block_addr_t mem_ctrl_req_block_addr,
    output block_data_t mem_ctrl_req_block_data, // (only for dcache and stores)
    output req_width_t mem_ctrl_req_width, // (only for dcache and stores) TODO: temporary
    output addr_t mem_ctrl_req_addr, // (only for dcache and stores) TODO: temporary
    output logic mem_ctrl_req_writethrough,
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
        logic [`BLOCK_DATA_WIDTH-1:0] way1_data;
        logic [`BLOCK_DATA_WIDTH-1:0] way0_data;
    } data_array_set_t;

    typedef struct packed {
        logic valid;
        req_type_t req_type;
        req_width_t width;
        dcache_addr_t addr;
        word_t wr_data;
        logic refill;
    } tag_stage_buffer_t;

    typedef struct packed {
        logic valid;
        req_type_t req_type;
        dcache_addr_t addr;
        logic [1:0] sel_way;
        logic refill;
    } data_stage_buffer_t;

    wire random_way;
    lfsr_8bit lfsr (
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .out_bit(random_way)
    );

    tag_stage_buffer_t tag_stage_buffer;
    tag_stage_buffer_t next_tag_stage_buffer;
    data_stage_buffer_t data_stage_buffer;
    data_stage_buffer_t next_data_stage_buffer;

    logic mem_ctrl_resp_was_valid;
    logic refill_waiting;
    logic [1:0] refill_writing;
    logic next_mem_ctrl_resp_was_valid;
    logic next_refill_waiting;
    logic [1:0] next_refill_writing;

    wire tag_array_set_t tag_array_dout;
    wire data_array_set_t data_array_dout;

    // assertion: refill_wmask[1] and refill_wmask[0] should not be true at the same time
    wire [1:0] refill_wmask = {
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b00) ? 2'b01 :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b01) ? 2'b10 :
        ({tag_array_dout.way1_valid, tag_array_dout.way0_valid} == 2'b10) ? 2'b01 :
                                                                            {random_way, ~random_way}
    };

    wire mem_ctrl_req_success = mem_ctrl_req_valid & mem_ctrl_req_ready;

    wire tag_array_csb = mem_ctrl_resp_valid     |
                         tag_stage_buffer.refill |
                       (~tag_stage_buffer.valid  &
                        ~refill_waiting &
                        ~pipeline_resp_valid     &
                         pipeline_req_valid)     ;
    wire tag_array_web = mem_ctrl_resp_valid ? 1'b1 :
                                               1'b0 ;
    wire [1:0] tag_array_wmask = refill_wmask;
    wire dcache_index_t tag_array_addr = pipeline_req_addr.index;
    wire tag_array_set_t tag_array_din = '{
        way1_valid: 1'b1,                // should be masked out if this is not the random way selected
        way1_tag: pipeline_req_addr.tag, // should be masked out if this is not the random way selected
        way0_valid: 1'b1,                // should be masked out if this is not the random way selected
        way0_tag: pipeline_req_addr.tag  // should be masked out if this is not the random way selected
    };
    sram_64x48_1rw_wsize24 #(.VERBOSE(VERBOSE)) tag_array (
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

    // assertion: sel_way1 and sel_way0 should not be true at the same time
    wire sel_way1 = tag_stage_buffer.valid &
                    tag_array_dout.way1_valid  &
                    (tag_array_dout.way1_tag == tag_stage_buffer.addr.tag);
    wire sel_way0 = tag_stage_buffer.valid &
                    tag_array_dout.way0_valid  &
                    (tag_array_dout.way0_tag == tag_stage_buffer.addr.tag);
    wire tag_array_hit = sel_way1 | sel_way0; // NOTE?: not guarded by pipeline_req_valid_latched and mem_ctrl_resp_waiting

    always_comb begin
        next_tag_stage_buffer = '{
            valid: tag_array_csb,
            req_type: pipeline_req_type,
            width: pipeline_req_width,
            addr: pipeline_req_addr,
            wr_data: pipeline_req_wr_data,
            refill: mem_ctrl_resp_valid
        };
    end
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init | !rst_aL) begin
            tag_stage_buffer <= '{default: 0};
        end else begin
            tag_stage_buffer <= next_tag_stage_buffer;
        end
    end

    always_comb begin
        if (mem_ctrl_resp_valid) begin
            next_mem_ctrl_resp_was_valid = 1'b1;
        end else if (mem_ctrl_resp_was_valid) begin
            next_mem_ctrl_resp_was_valid = 1'b0;
        end else begin
            next_mem_ctrl_resp_was_valid = mem_ctrl_resp_was_valid;
        end
        if (mem_ctrl_req_success & ~mem_ctrl_req_writethrough) begin
            next_refill_waiting = 1'b1;
        end else if (mem_ctrl_resp_valid) begin
            next_refill_waiting = 1'b0;
        end else begin
            next_refill_waiting = refill_waiting;
        end
        if (mem_ctrl_resp_valid) begin
            next_refill_writing = 2'd2;
        end else if (refill_writing > 0) begin
            next_refill_writing = refill_writing - 2'd1;
        end else begin
            next_refill_writing = refill_writing;
        end
    end
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init | !rst_aL) begin
            mem_ctrl_resp_was_valid <= 1'b0;
            refill_waiting <= 1'b0;
            refill_writing <= 2'd0;
        end else begin
            mem_ctrl_resp_was_valid <= next_mem_ctrl_resp_was_valid;
            refill_waiting <= next_refill_waiting;
            refill_writing <= next_refill_writing;
        end
    end

    wire data_array_csb = mem_ctrl_resp_valid      |
                          data_stage_buffer.refill |
                        (~refill_waiting           &
                         ~pipeline_resp_valid      &
                          tag_array_hit)           ;
    wire data_array_web = mem_ctrl_resp_valid                                  ? 1'b1 :
                          tag_array_hit & (tag_stage_buffer.req_type == WRITE) ? 1'b1 :
                                                                                 1'b0 ;
    wire [7:0] data_array_store_wmask = tag_stage_buffer.width == BYTE     ? 1'b1    << tag_stage_buffer.addr.offset[2:0] :
                                        tag_stage_buffer.width == HALFWORD ? 2'b11   << tag_stage_buffer.addr.offset[2:0] :
                                        tag_stage_buffer.width == WORD     ? 4'b1111 << tag_stage_buffer.addr.offset[2:0] :
                                                                             0 ;
    wire [15:0] data_array_refill_wmask = {{8{refill_wmask[1]}}, {8{refill_wmask[0]}}};
    wire [15:0] data_array_wmask = ({15{mem_ctrl_resp_valid}} & data_array_refill_wmask)                            |
                                   ({{8{sel_way1 & (tag_stage_buffer.req_type == WRITE)}} & data_array_store_wmask,
                                     {8{sel_way0 & (tag_stage_buffer.req_type == WRITE)}} & data_array_store_wmask});
    wire dcache_index_t data_array_addr = tag_stage_buffer.addr.index;
    wire data_array_set_t data_array_din = '{
        way1_data: mem_ctrl_resp_valid                ? mem_ctrl_resp_block_data            :
                   tag_stage_buffer.width == BYTE     ? {8{tag_stage_buffer.wr_data[7:0]}}  :
                   tag_stage_buffer.width == HALFWORD ? {4{tag_stage_buffer.wr_data[15:0]}} :
                   tag_stage_buffer.width == WORD     ? {2{tag_stage_buffer.wr_data}}       :
                                                        0                                   ,
        way0_data: mem_ctrl_resp_valid                ? mem_ctrl_resp_block_data            :
                   tag_stage_buffer.width == BYTE     ? {8{tag_stage_buffer.wr_data[7:0]}}  :
                   tag_stage_buffer.width == HALFWORD ? {4{tag_stage_buffer.wr_data[15:0]}} :
                   tag_stage_buffer.width == WORD     ? {2{tag_stage_buffer.wr_data}}       :
                                                        0
    };
    sram_64x128_1rw_wsize8 #(.VERBOSE(VERBOSE)) data_array (
        .clk0(clk),
        .init(init),
        .rst_aL(rst_aL),
        .csb0(~data_array_csb), // active low
        .web0(~data_array_web), // active low
        .wmask0(data_array_wmask),
        .addr0(data_array_addr),
        .din0(data_array_din),
        .dout0(data_array_dout)
    );

    always_comb begin
        next_data_stage_buffer = '{
            valid: data_array_csb,
            req_type: tag_stage_buffer.req_type,
            addr: tag_stage_buffer.addr,
            sel_way: data_stage_buffer.refill ? refill_wmask : {sel_way1, sel_way0},
            refill: mem_ctrl_resp_valid
        };
    end
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init | !rst_aL) begin
            data_stage_buffer <= '{default: 0};
        end else begin
            data_stage_buffer <= next_data_stage_buffer;
        end
    end

    assign mem_ctrl_req_valid = tag_stage_buffer.valid   &
                                (refill_writing == 2'd0) &
                                (~tag_array_hit | (tag_stage_buffer.req_type == WRITE)); // write-through
    assign mem_ctrl_req_type = tag_stage_buffer.req_type; // write-through
    assign mem_ctrl_req_block_addr = {tag_stage_buffer.addr.tag, tag_stage_buffer.addr.index};
    // assign mem_ctrl_req_block_data = sel_way0 ? data_array_dout.way0_data :
    //                                  sel_way1 ? data_array_dout.way1_data :
    //                                             0; // since miss, a read request is being made and this value is not used
    assign mem_ctrl_req_block_data = {32'b0, tag_stage_buffer.wr_data}; // TODO: temporary
    assign mem_ctrl_req_width = tag_stage_buffer.width; // TODO: temporary
    assign mem_ctrl_req_addr = tag_stage_buffer.addr; // TODO: temporary
    assign mem_ctrl_req_writethrough = tag_stage_buffer.valid & tag_array_hit & (tag_stage_buffer.req_type == WRITE);

    assign pipeline_resp_valid = data_stage_buffer.valid &
                                ~data_stage_buffer.refill;
    assign pipeline_resp_rd_data =
        data_stage_buffer.sel_way[0] ? data_array_dout.way0_data[8*data_stage_buffer.addr.offset+:32] :
        data_stage_buffer.sel_way[1] ? data_array_dout.way1_data[8*data_stage_buffer.addr.offset+:32] :
                                       0; // since miss, a read request is being made and this value is not used


    // logic pipeline_req_valid_latched;
    // req_type_t pipeline_req_type_latched;
    // req_width_t pipeline_req_width_latched;
    // addr_t pipeline_req_addr_latched;
    // logic [N_TAG_BITS-1:0] pipeline_req_addr_tag_latched;
    // logic [N_INDEX_BITS-1:0] pipeline_req_addr_index_latched;
    // logic [N_OFFSET_BITS-1:0] pipeline_req_addr_offset_latched;
    // assign {
    //     pipeline_req_addr_tag_latched,
    //     pipeline_req_addr_index_latched,
    //     pipeline_req_addr_offset_latched
    // } = pipeline_req_addr_latched; // TODO: double-check
    // word_t pipeline_req_wr_data_latched;
    // logic pipeline_resp_was_valid; // skid preventing latch
    // logic mem_ctrl_resp_waiting;   // double request preventing latch
    // logic [1:0] mem_ctrl_resp_writing;
    // logic tag_array_hit_latched;
    // logic sel_way0_latched;
    // logic sel_way1_latched;

    // // TODO: double-check if pipeline_req_valid_latched is good

    // // TODO: does this kind of always_ff cause any problems?
    // // TODO: no negedge rst_aL in the sensitivity list? (copied behavioral sram)
    // always @(posedge clk or posedge init or negedge rst_aL) begin
    //     if (init | !rst_aL) begin
    //         pipeline_req_valid_latched <= '0;
    //         pipeline_req_type_latched <= req_type_t'(0);
    //         pipeline_req_width_latched <= req_width_t'(0);
    //         pipeline_req_addr_latched <= '0;
    //         // pipeline_req_addr_tag_latched <= '0;
    //         // pipeline_req_addr_index_latched <= '0;
    //         // pipeline_req_addr_offset_latched <= '0;
    //         pipeline_req_wr_data_latched <= '0;
    //         pipeline_resp_was_valid <= '0;
    //         mem_ctrl_resp_waiting <= '0;
    //         mem_ctrl_resp_writing <= '0;
    //         tag_array_hit_latched <= '0;
    //         sel_way0_latched <= '0;
    //         sel_way1_latched <= '0;
    //     end else begin
    //         pipeline_req_valid_latched <= pipeline_req_valid;
    //         pipeline_req_type_latched <= pipeline_req_type;
    //         pipeline_req_width_latched <= pipeline_req_width;
    //         pipeline_req_addr_latched <= pipeline_req_addr;
    //         // pipeline_req_addr_tag_latched <= pipeline_req_addr_tag;
    //         // pipeline_req_addr_index_latched <= pipeline_req_addr_index;
    //         // pipeline_req_addr_offset_latched <= pipeline_req_addr_offset;
    //         pipeline_req_wr_data_latched <= pipeline_req_wr_data;
    //         if (pipeline_resp_was_valid) begin
    //             pipeline_resp_was_valid <= 0;
    //         end else if (pipeline_resp_valid) begin
    //             pipeline_resp_was_valid <= 1;
    //         end else begin
    //             pipeline_resp_was_valid <= pipeline_resp_was_valid;
    //         end
    //         if (mem_ctrl_req_success) begin
    //             mem_ctrl_resp_waiting <= 1;
    //         end else if (mem_ctrl_resp_valid) begin
    //             mem_ctrl_resp_waiting <= 0;
    //         end else begin
    //             mem_ctrl_resp_waiting <= mem_ctrl_resp_waiting;
    //         end
    //         if (mem_ctrl_resp_valid) begin
    //             mem_ctrl_resp_writing <= 2'd2;
    //         end else if (mem_ctrl_resp_writing > 0) begin
    //             mem_ctrl_resp_writing <= mem_ctrl_resp_writing - 2'd1;
    //         end else begin
    //             mem_ctrl_resp_writing <= mem_ctrl_resp_writing;
    //         end
    //         tag_array_hit_latched <= tag_array_hit;
    //         sel_way0_latched <= sel_way0;
    //         sel_way1_latched <= sel_way1;
    //     end
    // end

    // assign mem_ctrl_req_valid = pipeline_req_valid_latched      &
    //                             ~mem_ctrl_resp_waiting          &
    //                             (mem_ctrl_resp_writing == 2'd0) &
    //                             (~tag_array_hit | (pipeline_req_type_latched == WRITE)); // write-through
    // assign mem_ctrl_req_type = ~tag_array_hit ? READ : // all misses should do a refill first
    //                                             pipeline_req_type_latched; // write-through
    // assign mem_ctrl_req_block_addr = {pipeline_req_addr_tag_latched, pipeline_req_addr_index_latched};
    // // assign mem_ctrl_req_block_data = sel_way0 ? data_array_dout.way0_data :
    // //                                  sel_way1 ? data_array_dout.way1_data :
    // //                                             0; // since miss, a read request is being made and this value is not used
    // assign mem_ctrl_req_block_data = {32'b0, pipeline_req_wr_data_latched}; // TODO: temporary
    // assign mem_ctrl_req_width = pipeline_req_width_latched; // TODO: temporary
    // assign mem_ctrl_req_addr = pipeline_req_addr_latched; // TODO: temporary

    // assign pipeline_resp_valid = pipeline_req_cache_type == ICACHE ? pipeline_req_valid_latched &
    //                                                                  tag_array_hit              :
    //                              pipeline_req_cache_type == DCACHE ? pipeline_req_valid_latched & // TODO: double latch
    //                                                                  ~pipeline_resp_was_valid   &
    //                                                                  tag_array_hit_latched      :
    //                                                                  0;
    // // FIXME: serialize this as well (double latch?)
    // assign pipeline_resp_rd_data = sel_way0 ? data_array_dout.way0_data[8*pipeline_req_addr_offset_latched+:32] :
    //                                sel_way1 ? data_array_dout.way1_data[8*pipeline_req_addr_offset_latched+:32] :
    //                                           0; // since miss, a read request is being made and this value is not used




    // assertions
    // sel_way1 and sel_way0 should not be true at the same time
    // refill_wmask[1] and refill_wmask[0] should not be true at the same time

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
