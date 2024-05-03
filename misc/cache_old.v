`ifndef CACHE_V
`define CACHE_V

// `include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"
`include "sram/icache_data_sram.v"
`include "sram/dcache_data_sram_netlist_only.v"
`include "sram/tag_array_sram.v"
`include "misc/dff_we.v"
`include "misc/cmp/cmp32.v"
`include "misc/onehot_mux/onehot_mux.v"
`include "misc/mux/mux_.v"
`include "misc/lfsr.v"


// TODO: make this truly parametrizable?
// TODO: change BLOCK_SIZE to be in terms of bytes, not bits?
module cache_old #(
    parameter BLOCK_SIZE_BITS = `ICACHE_DATA_BLOCK_SIZE,  // just defaults
    parameter NUM_SETS = `ICACHE_NUM_SETS,  // just defaults
    parameter NUM_WAYS = `ICACHE_NUM_WAYS,  // just defaults
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
    input wire [`ADDR_WIDTH-1:0] PC_addr,
    input wire we_aL,
    input wire dcache_is_ST,  // if reason for d-cache access is to store something (used for dirty bit)
    input wire [WRITE_SIZE_BITS-1:0] write_data,  // 64 for icache (DRAMresponse) 8 bits for dcache

    input wire csb0_in,

    output wire [BLOCK_SIZE_BITS-1:0] selected_data_way,
    output wire cache_hit
);

// access cache bit fields
`define get_tag     `ADDR_WIDTH-1:(NUM_SET_BITS+NUM_OFFSET_BITS)
`define get_set_num  (NUM_SET_BITS+NUM_OFFSET_BITS-1):NUM_OFFSET_BITS
`define get_offset   NUM_OFFSET_BITS-1:0

// wire we_aH;
// INV_X1 we_aH_INV (
//     .A(we_aL),
//     .ZN(we_aH)
// );

wire [NUM_WAYS-1:0] we_mask;

// ::: TAG ARRAY :::::::::::::::::::::::::::::::::::::
// Both i-cache and d-cache are the same size
wire [47:0] tag_out;
sram_64x48_1rw_wsize24 tag_arr (
    .clk0(clk),
    .csb0(csb0_in),  // 1 chip
    .web0(we_aL),
    .rst_aL(rst_aL),
    .wmask0(we_mask),
    .addr0(addr[`get_set_num]),
    .din0({1'b1, addr[`get_tag], 1'b1, addr[`get_tag]}),
    .dout0(tag_out)
);

// capture Tag Array outputs
wire way0_v, way1_v;
wire [TAG_ENTRY_SIZE-2:0] way0_tag, way1_tag;  // -2 for valid bit
assign {way1_v, way1_tag, way0_v, way0_tag} = tag_out;
wire read_way0_selected, read_way1_selected;

// For dirty bits - write 1 when completing ST instruction
// genvar i;
// wire [NUM_SETS-1:0][NUM_WAYS-1:0] dirty_sets;
// generate
//     if(WRITE_SIZE_BITS == 8) begin  // FOR D-CACHE ONLY

//         AND2_X1 way0_dirty_we (
//             .A(we_aH),
//             .B(read_way0_selected)  // loops around from after ways tags are checked (increases crit path)
//         );
//         AND2_X1 way1_dirty_we (
//             .A(we_aH),
//             .B(read_way1_selected)
//         );

//         for(i = 0; i < NUM_SETS; i = i + 1) begin: ways_d
//             // set way0 dirty bit for this tag
//             OR2_X1 set_way0_d(
//                 .A(dcache_is_ST),
//                 .B(ways_d[i].way0_dirty.q)
//             );
//             dff_we way0_dirty (
//                 .clk(clk),
//                 .rst_aL(rst_aL),
//                 .we(way0_dirty_we.ZN),
//                 .d(set_way0_d.ZN)
//             );
//             assign dirty_sets[i][0] = way0_dirty.q;

//             // set way1 dirty bit for this tag
//             OR2_X1 set_way1_d(
//                 .A(dcache_is_ST),
//                 .B(ways_d[i].way1_dirty.q)
//             );
//             dff_we way1_dirty (
//                 .clk(clk),
//                 .rst_aL(rst_aL),
//                 .we(way1_dirty_we.ZN),
//                 .d(set_way1_d.ZN)
//             );
//             assign dirty_sets[i][1] = way1_dirty.q;

//         end

//         wire [NUM_WAYS-1:0] set_dirty_bits;
//         mux_ #(
//             .WIDTH(2),
//             .N_INS(NUM_SETS)
//         ) mux64_1 (
//             .ins(dirty_sets),
//             .sel(PC_addr[`get_set_num]),
//             .out(set_dirty_bits)
//         );
//     end
// endgenerate
// END TAG ARRAY :::::::::::::::::::::::::::::::::::::

// ::: DATA ARRAY ::::::::::::::::::::::::::::::::::::
// I-cache & D-cache same size but different write granularities
wire [127:0] data_out;
generate
    if (WRITE_SIZE_BITS == 64) begin: icache      // I-Cache
        sram_64x128_1rw_wsize64 icache_data_arr (
            .clk0(clk),
            .csb0(csb0_in),  // 1 chip
            .web0(we_aL),
            .rst_aL(rst_aL),
            .wmask0(we_mask),
            .addr0(addr[`get_set_num]),
            .din0({write_data, write_data}),
            .dout0(data_out)
        );
    end
    else if (WRITE_SIZE_BITS == 8) begin: dcache  // D-Cache
        sram_64x128_1rw_wsize8 dcache_data_arr (
            .clk0(clk),
            .csb0(0),  // 1 chip
            .web0(we_aL),
            .rst_aL(rst_aL),
            .wmask0(we_mask), // FIXME: should be size 16
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

// capture 2 data way outputs
wire [BLOCK_SIZE_BITS-1:0] way0_data, way1_data;
assign {way1_data, way0_data} = icache.icache_data_arr.dout0;

// END DATA ARRAY ::::::::::::::::::::::::::::::::::::

// ::: process cache tag and data bank outputs ::::::::

// select which way
wire way0_tag_match, way1_tag_match;
cmp32 way0_tag_check (
    .a({9'b0, way0_tag}),
    .b({9'b0, PC_addr[`get_tag]}),
    .y(way0_tag_match)
);
cmp32 way1_tag_check (
    .a({9'b0, way1_tag}),
    .b({9'b0, PC_addr[`get_tag]}),
    .y(way1_tag_match)
);

// check tag matches with valid bits
AND2_X1 way0_check_v(
    .A1(way0_tag_match),
    .A2(way0_v),
    .ZN(read_way0_selected)
);
AND2_X1 way1_check_v(
    .A1(way1_tag_match),
    .A2(way1_v),
    .ZN(read_way1_selected)
);

// FIX: NEED TO OVERWRITE IF TAG MATCH, PICK NON-VALID WAY if no tag match, or RANDOMLY PICK if no tag match and both valid
// AND2_X1 tag_match_detected (
//     .A1(way0_tag_match),
//     .A2(way1_tag_match)
// );
wire rst_aH;
INV_X1 rst_inv (
    .A(rst_aL),
    .ZN(rst_aH)
);
wire lfsr_out;
lfsr_1bit lfsr (
    .clk(clk),
    .reset(rst_aH),
    .q(lfsr_out)
);
INV_X1 lfsr_inv (
    .A(lfsr_out)
);
// truth tab
// WAY1V WAY0V we_mask[1] we_mask[0]
//  0     0     0         1  // both invalid just write to 0
//  0     1     1         0  // if way 0 valid, write to way 1
//  1     0     0         1  // if way 1 valid, write to way 0
//  1     1    1/2       1/2 (randomly evict)
wire [1:0] intr_we_mask;
mux_ #(
    .WIDTH(1),
    .N_INS(4)
) mux4_way_fill2 (
    .ins({lfsr_out, 1'b0, 1'b1, 1'b0}),
    .sel({way1_v, way0_v}),
    .out(intr_we_mask[1])
);
mux_ #(
    .WIDTH(1),
    .N_INS(4)
) mux4_way_fill1 (
    .ins({lfsr_inv.ZN, 1'b1, 1'b0, 1'b1}),
    .sel({way1_v, way0_v}),
    .out(intr_we_mask[0])
);

mux_ #(
    .WIDTH(2),
    .N_INS(4)
) mux4_way_fill (
    .ins({intr_we_mask, 2'b10, 2'b01, intr_we_mask}),
    .sel({way1_tag_match, way0_tag_match}),
    .out(we_mask)
);

// Cache hit - is either way selected and valid?
OR2_X1 icache_hit_or_gate(
    .A1(read_way0_selected),
    .A2(read_way1_selected),
    .ZN(cache_hit)
);

// select which data way
onehot_mux #(
    .WIDTH(BLOCK_SIZE_BITS),
    .N_INS(2)
)
way_data_mux (
    .clk(clk),
    .ins({way1_data, way0_data}),
    .sel({read_way1_selected, read_way0_selected}),
    .out(selected_data_way)
);

// END process cache tag and data bank outputs ::::::::

endmodule
`endif
