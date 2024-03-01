// TODO: make this truly parametrizable?
// TODO: change BLOCK_SIZE to be in terms of bytes, not bits?
module cache #(
    parameter BLOCK_SIZE = ICACHE_DATA_BLOCK_SIZE,  // 64 bits
    parameter NUM_SETS = ICACHE_NUM_SETS,
    parameter NUM_WAYS = ICACHE_NUM_WAYS,
    parameter NUM_TAG_CTRL_BITS = 1 // valid + dirty + etc.
    parameter WRITE_SIZE_BITS = 64
    //::: local params ::: don't override
    localparam NUM_SET_BITS = $clog2(NUM_SETS),
    localparam NUM_OFFSET_BITS = $clog2(BLOCK_SIZE >> 3),
    localparam TAG_ENTRY_SIZE = ADDR_WIDTH - (NUM_SET_BITS + NUM_OFFSET_BITS) + NUM_TAG_CTRL_BITS
) (
    input wire clk,
    input wire rst_aL,
    input wire [ADDR_WIDTH-1:0] PC,
    input wire we,
    input wire [BLOCK_SIZE-1:0] write_data,
    output wire [BLOCK_SIZE-1:0] selected_data_way,
    output wire icache_hit
);

// ::: TAG ARRAY :::::::::::::::::::::::::::::::::::::
// Both i-cache and d-cache are the same size
wire [47:0] tag_out;
sram_64x48_1rw_wsize24 tag_arr (
    .clk0(clk),
    .csb0_aL(0),  // 1 chip
    .web0_aL(/*TODO*/),
    .addr0(/*TODO*/),
    .din0(/*TODO*/),
    .dout0(tag_out)
);

generate
    if(WRITE_SIZE_BITS == 8) begin  // FOR D-CACHE ONLY
        register #(.WIDTH(64)) way0_dirtys (
            .clk(clk),
            .rst_aL(rst_aL),
            .we(),
            .din(),
            // .dout()
        );
        register #(.WIDTH(64)) way1_dirtys (
            .clk(clk),
            .rst_aL(rst_aL),
            .we(),
            .din(),
            // .dout()
        );
    end
endgenerate

// capture Tag Array outputs
wire way0_v, way0_dirty, way1_v, way1_dirty;
wire [TAG_ENTRY_SIZE-1:0] way0_tag, way1_tag;
assign {way0_dirty, way1_dirty} = {way0_dirtys.dout[/*ADDR*/], way1_dirtys.dout[/*ADDR*/]};
assign {way0_v, way0_tag, way1_v, way1_tag} = tag_out;

// END TAG ARRAY :::::::::::::::::::::::::::::::::::::

// ::: DATA ARRAY ::::::::::::::::::::::::::::::::::::
// I-cache & D-cache same size but different write granularities
wire [127:0] data_out;
generate
    if (WRITE_SIZE_BITS == 64) begin      // I-Cache
        sram_64x128_1rw_wsize64 i_cache_data_arr (
            .clk0(clk),
            .csb0_aL(0),  // 1 chip
            .web0_aL(/*TODO*/),
            .addr0(/*TODO*/),
            .din0(/*TODO*/),
            .dout0(data_out)
        );
    end
    else if (WRITE_SIZE_BITS == 8) begin  // D-Cache
        sram_64x128_1rw_wsize8 d_cache_data_arr (
            .clk0(clk),
            .csb0_aL(0),  // 1 chip
            .web0_aL(/*TODO*/),
            .addr0(/*TODO*/),
            .din0(/*TODO*/),
            .dout0(data_out)
        );
    end
    else begin
        // THROW ERROR THIS IS NOT POSSIBLE
        assign data_out = 0;
    end

endgenerate

// capture 2 data bank outputs
wire [BLOCK_SIZE-1:0] way0_data, way1_data;
assign {way0_data, way1_data} = data_out;

// END DATA ARRAY ::::::::::::::::::::::::::::::::::::



// ::: process cache tag and data bank outputs ::::::::

// select which instruction within way
wire way0_tag_match, way1_tag_match;
cmp32 way0_tag_check (
    .a(tag_b1),
    .b(PC[(ADDR_WIDTH-1):(ADDR_WIDTH-TAG_ENTRY_SIZE+1)]),
    .y(way0_tag_match)
);
cmp32 way1_tag_check (
    .a(tag_b2),
    .b(PC[(ADDR_WIDTH-1):(ADDR_WIDTH-TAG_ENTRY_SIZE+1)]),
    .y(way1_tag_match)
);

// check tag matches with valid bits
wire way0_selected, way1_selected;
AND2_X1 way0_check_v(
    .A1(way0_tag_match),
    .A2(way0_v),
    .ZN(way0_selected),
);
AND2_X1 way1_check_v(
    .A1(way1_tag_match),
    .A2(way1_v),
    .ZN(way1_selected),
);

// Cache hit - is either way selected and valid?
OR2_X1 icache_hit_or_gate(
    .A1(way0_selected),
    .A2(way1_selected),
    .ZN(icache_hit)
);

// select which data way
onehot_mux2 #(BLOCK_SIZE) way_data_mux (
    .d0(way0_data),
    .d1(way1_data),
    .s({way1_selected, way0_selected}),
    .y(selected_data_way)
);

// END process cache tag and data bank outputs ::::::::

endmodule