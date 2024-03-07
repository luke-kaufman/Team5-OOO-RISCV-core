`ifndef CACHE_V
`define CACHE_V

`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.vh"
`include "sram/icache_data_sram.v"
`include "sram/dcache_data_sram_netlist_only.v"
`include "sram/tag_array_sram.v"
`include "misc/dff_we.v"
`include "misc/cmp/cmp32.v"
`include "misc/onehot_mux/onehot_mux2.v"

// TODO: make this truly parametrizable?
// TODO: change BLOCK_SIZE to be in terms of bytes, not bits?
module cache #(
    parameter BLOCK_SIZE_BITS = `ICACHE_DATA_BLOCK_SIZE,  // 64 bits
    parameter NUM_SETS = `ICACHE_NUM_SETS,
    parameter NUM_WAYS = `ICACHE_NUM_WAYS,
    parameter NUM_TAG_CTRL_BITS = 1, // valid + dirty + etc.
    parameter WRITE_SIZE_BITS = 64,
    //::: local params ::: don't override
    localparam NUM_SET_BITS = $clog2(NUM_SETS),
    localparam NUM_OFFSET_BITS = $clog2(BLOCK_SIZE_BITS >> 3),
    localparam TAG_ENTRY_SIZE = `ADDR_WIDTH - (NUM_SET_BITS + NUM_OFFSET_BITS) + NUM_TAG_CTRL_BITS
) (
    input wire clk,
    input wire rst_aL,
    input wire [`ADDR_WIDTH-1:0] addr,
    input wire we_aL,
    input wire d_cache_is_ST,  // if reason for d-cache access is to store something (used for dirty bit)
    input wire [WRITE_SIZE_BITS-1:0] write_data,  // 64 for icache (DRAMresponse) 8 bits for dcache 
    output wire [BLOCK_SIZE_BITS-1:0] selected_data_way,
    output wire cache_hit
);

// access cache bit fields
`define get_tag     `ADDR_WIDTH-1 : (NUM_SET_BITS+NUM_OFFSET_BITS)
`define get_set_num  (NUM_SET_BITS+NUM_OFFSET_BITS-1) : NUM_OFFSET_BITS
`define get_offset   NUM_OFFSET_BITS-1 : 0

INV_X1 we_aH (
    .A(we_aL)
);

// ::: TAG ARRAY :::::::::::::::::::::::::::::::::::::
// Both i-cache and d-cache are the same size
wire [47:0] tag_out;
sram_64x48_1rw_wsize24 tag_arr (
    .clk0(clk),
    .csb0(1'b0),  // 1 chip
    .web0(we_aL),
    .wmask0({way1_selected, way0_selected}),
    .addr0(addr[`get_set_num]),
    .din0({1'b1, addr[`get_tag], 1'b1, addr[`get_tag]}),
    .dout0(tag_out)
);

// capture Tag Array outputs
wire way0_v, way1_v;
wire [TAG_ENTRY_SIZE-2:0] way0_tag, way1_tag;
assign {way0_v, way0_tag, way1_v, way1_tag} = tag_out;

// For dirty bits - write 1 when completing ST instruction
genvar i;
generate
    if(WRITE_SIZE_BITS == 8) begin  // FOR D-CACHE ONLY
        
        AND2_X1 way0_dirty_we (
            .A(we_aH.ZN),
            .B(way0_selected)  // loops around from after ways tags are checked (increases crit path)
        );
        AND2_X1 way1_dirty_we (
            .A(we_aH.ZN),
            .B(way1_selected)
        );

        for(i = 0; i < NUM_SETS; i = i + 1) begin: ways_d
            // set way0 dirty bit for this tag
            OR2_X1 set_way0_d(
                .A(d_cache_is_ST),
                .B(ways_d[i].way0_dirty.q)
            );
            dff_we way0_dirty (
                .clk(clk),
                .rst_aL(rst_aL),
                .we(way0_dirty_we.ZN),
                .d(set_way0_d.ZN)
            );

            // set way1 dirty bit for this tag
            OR2_X1 set_way1_d(
                .A(d_cache_is_ST),
                .B(ways_d[i].way1_dirty.q)
            );
            dff_we way1_dirty (
                .clk(clk),
                .rst_aL(rst_aL),
                .we(way1_dirty_we.ZN),
                .d(set_way1_d.ZN)
            );
        end
    end

    wire way0_dirty_bit, way1_dirty_bit;
    // assign way0_dirty_bit = ways_d[addr[`get_set_num]].way0_dirty.q; 
    // assign way1_dirty_bit = ways_d[addr[`get_set_num]].way1_dirty.q;
    mux64 #(.WIDTH(1)) mux64_1 (
        .ins(ways_d[].way0_dirty.q),
        .sel({1'b0, addr[`get_set_num]}),
        .out(way0_dirty_bit)
    );
endgenerate


// END TAG ARRAY :::::::::::::::::::::::::::::::::::::

// ::: DATA ARRAY ::::::::::::::::::::::::::::::::::::
// I-cache & D-cache same size but different write granularities
wire [127:0] data_out;
generate
    if (WRITE_SIZE_BITS == 64) begin      // I-Cache
        sram_64x128_1rw_wsize64 i_cache_data_arr (
            .clk0(clk),
            .csb0(1'b0),  // 1 chip
            .web0(we_aL),
            .wmask0({way1_selected, way0_selected}),
            .addr0(addr[`get_set_num]),
            .din0({write_data, write_data}),
            .dout0(data_out)
        );
    end
    else if (WRITE_SIZE_BITS == 8) begin  // D-Cache
        sram_64x128_1rw_wsize8 d_cache_data_arr (
            .clk0(clk),
            .csb0(0),  // 1 chip
            .web0(we_aL),
            .wmask0({way1_selected, way0_selected}),
            .addr0(addr[`get_set_num]),
            .din0({write_data, write_data}),
            .dout0(data_out)
        );
    end
    else begin
        // THROW ERROR THIS IS NOT POSSIBLE
        assign data_out = 0;
    end
endgenerate

// capture 2 data bank outputs
wire [BLOCK_SIZE_BITS-1:0] way0_data, way1_data;
assign {way0_data, way1_data} = data_out;

// END DATA ARRAY ::::::::::::::::::::::::::::::::::::

// ::: process cache tag and data bank outputs ::::::::

// select which way
wire way0_tag_match, way1_tag_match;
cmp32 way0_tag_check (
    .a({9'b0, way0_tag}),
    .b({9'b0, addr[`get_tag]}),
    .y(way0_tag_match)
);
cmp32 way1_tag_check (
    .a({9'b0, way1_tag}),
    .b({9'b0, addr[`get_tag]}),
    .y(way1_tag_match)
);

// check tag matches with valid bits
wire way0_selected, way1_selected;
AND2_X1 way0_check_v(
    .A1(way0_tag_match),
    .A2(way0_v),
    .ZN(way0_selected)
);
AND2_X1 way1_check_v(
    .A1(way1_tag_match),
    .A2(way1_v),
    .ZN(way1_selected)
);

// Cache hit - is either way selected and valid?
OR2_X1 icache_hit_or_gate(
    .A1(way0_selected),
    .A2(way1_selected),
    .ZN(cache_hit)
);

// select which data way
onehot_mux2 #(.WIDTH(BLOCK_SIZE_BITS)) way_data_mux (
    .d0(way0_data),
    .d1(way1_data),
    .s({way1_selected, way0_selected}),
    .y(selected_data_way)
);

// END process cache tag and data bank outputs ::::::::

endmodule
`endif
