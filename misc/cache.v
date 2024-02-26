// TODO: make this truly parametrizable?
// TODO: change I$_BLOCK_SIZE to be in terms of bytes, not bits?
module cache #(
    parameter ADDR_WIDTH = 32,     // 32 bits
    parameter I$_BLOCK_SIZE = 64,  // 64 bits
    parameter I$_NUM_SETS = 64,
    parameter I$_NUM_WAYS = 2,
    //::: local params ::: don't override
    parameter NUM_SET_BITS = $clog2(I$_NUM_SETS),
    parameter NUM_OFFSET_BITS = $clog2(I$_BLOCK_SIZE >> 3),
    parameter TAG_ENTRY_SIZE = ADDR_WIDTH - (NUM_SET_BITS + NUM_OFFSET_BITS) + 1 /*valid bit*/
) (
    input wire [ADDR_WIDTH-1:0] PC,
    input wire we,
    input wire [I$_BLOCK_SIZE-1:0] write_data,
    output wire [I$_BL-1:0] selected_data_way,
    output wire icache_hit
);

// ::: 2 banked icache tag and data array ::::::::::::::

// ::: 2 tag banks :::::::::::::::::::::::::::::::::::::
icache_tag_bank tag_b1 (
    .clk(clk),
    .rst(rst),
    .en(en),
    .dout(dout)
);
icache_tag_bank tag_b2 (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .dout(dout)
);

// capture 2 tag bank outputs
wire way0_v, way1_v;
wire [TAG_ENTRY_SIZE-1:0] way0_tag, wire1_tag;
assign {way0_v, way0_tag, way1_v, way1_tag} = {tag_b1.dout, tag_b2.dout};

// END 2 tag banks :::::::::::::::::::::::::::::::::::::

// ::: 2 data banks ::::::::::::::::::::::::::::::::::::
icache_data_bank data_b1 (
    
);
icache_data_bank data_b2 (
    
);

// capture 2 data bank outputs
wire [I$_BLOCK_SIZE-1:0] way0_data, way1_data;
assign {way0_data, way1_data} = {data_b1.dout, data_b2.dout};

// END 2 data banks ::::::::::::::::::::::::::::::::::::

// END 2 banked icache tag and data array ::::::::::::::

// ::: process icache tag and data bank outputs ::::::::

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
onehot_mux2 #(I$_BLOCK_SIZE) way_data_mux (
    .d0(way0_data),
    .d1(way1_data),
    .s({way1_selected, way0_selected}),
    .y(selected_data_way)
);

// END process icache tag and data bank outputs ::::::::

endmodule