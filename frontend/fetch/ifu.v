`ifndef IFU_V
`define IFU_V

`include "misc/global_defs.svh"
// `include "freepdk-45nm/stdcells.v"
`include "misc/cache.v"
`include "misc/fifo.v"
`include "frontend/fetch/predicted_NPC.v"

// Instruction Fetch Unit
module ifu #(
    parameter I$_BLOCK_SIZE = `ICACHE_DATA_BLOCK_SIZE,
    parameter I$_NUM_SETS = `ICACHE_NUM_SETS,
    parameter I$_NUM_WAYS = `ICACHE_NUM_WAYS
) (
    // from top.sv
    input wire clk,
    input wire rst_aL,
    input wire csb0_in,
    // backend interactions
    input wire [`ADDR_WIDTH-1:0] recovery_PC,
    input wire recovery_PC_valid,
    input wire backend_stall,
    // Main memory interaction for both LOADS and ICACHE (rd only)
    input wire                               recv_main_mem_valid,
    input wire                               recv_main_mem_lsu_aL_ifu_aH,  // if main mem data is meant for LSU or IFU
    input wire [`ICACHE_DATA_BLOCK_SIZE-1:0] recv_main_mem_data,
    // Main memory interaction only for STORES (wr only)
    output wire                   send_en_main_mem,
    output wire                   send_main_mem_lsu_aL_ifu_aH,
    output wire [`ADDR_WIDTH-1:0] send_main_mem_addr,
    output wire [2:0]             send_size_main_mem, // {Word, Halfword, Byte}
    output wire [`WORD_WIDTH-1:0] send_main_mem_data, // write up to a word
    // IFU <-> DISPATCH
    input wire ififo_dispatch_ready,
    output wire ififo_dispatch_valid,
    output wire [`IFIFO_ENTRY_WIDTH-1:0] ififo_dispatch_data,

    input wire fetch_redirect_valid
);

// wires
wire icache_hit;
wire icache_miss;
wire [I$_BLOCK_SIZE-1:0] icache_data_way;
wire [`ADDR_WIDTH-1:0] PC_mux_out;
wire [`ADDR_WIDTH-1:0] next_PC;
wire [`ADDR_WIDTH-1:0] PC_wire;
wire IFIFO_stall;

// ::: PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// Stall aggregator (OR-gate)
wire stall;
OR3_X1 stall_gate (
    .A1(icache_miss),
    .A2(IFIFO_stall),
    .A3(backend_stall),
    .ZN(stall)
);

wire [`ADDR_WIDTH-1:0] PC_mux_local_out;
mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(4)
) PC_mux_local(
    .ins({recovery_PC, // if recovery
          recovery_PC, // if recovery
          PC_wire,     // if stall
          next_PC      // predicted nextPC
          }),
    .sel({recovery_PC_valid, stall}),
    .out(PC_mux_local_out)
);

mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(2)
) PC_mux (
    .ins({recv_main_mem_addr, PC_mux_local_out}),
    .sel(recv_main_mem_valid),
    .out(PC_mux_out)
);

reg_ #(.WIDTH(`ADDR_WIDTH)) PC (
    // NO FLUSH HERE, NEED TO WRITE NEW PC DURING THAT
    .clk(clk),
    .rst_aL(rst_aL),
    .we(1'b1),  // always write since PC_mux will feed PC itself when stalling
    .din(PC_mux_out),
    .dout(PC_wire)
);
// END PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
INV_X1 icmiss(
    .A(icache_hit),
    .ZN(icache_miss)
);

wire icache_we_aL;
INV_X1 response_v_to_we_aL (
    .A(recv_main_mem_valid),
    .ZN(icache_we_aL)
);
cache #(
    .BLOCK_SIZE_BITS(I$_BLOCK_SIZE),
    .NUM_SETS(I$_NUM_SETS),
    .NUM_WAYS(I$_NUM_WAYS),
    .NUM_TAG_CTRL_BITS(`ICACHE_NUM_TAG_CTRL_BITS),  // 1 for valid bit
    .WRITE_SIZE_BITS(`ICACHE_WRITE_SIZE_BITS)    // 64 for icache (DRAMresponse)
) icache (
    .clk(clk),
    .rst_aL(rst_aL),
    .addr(PC_mux_out),
    .PC_addr(PC.dout),
    .dcache_is_ST(1'b0), // not used in icache
    .we_aL(icache_we_aL),
    .write_data(recv_main_mem_data),
    .csb0_in(csb0_in),

    .cache_hit(icache_hit),
    .selected_data_way(icache_data_way)
);

// select instruction within way
wire [`INSTR_WIDTH-1:0] selected_instr;
// mux_ #(
mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(2)
) instr_in_way_mux (
    .ins({icache_data_way[(I$_BLOCK_SIZE - 1):`ADDR_WIDTH],
          icache_data_way[(`ADDR_WIDTH - 1):0]}),
    .sel(PC_wire[2]),
    .out(selected_instr)
);
// END ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::
wire br_prediction;
wire is_cond_branch;
predicted_NPC pred_NPC (
    .instr(selected_instr),
    .PC(PC_wire),
    .is_cond_branch(is_cond_branch),
    .br_prediction(br_prediction),
    .next_PC(next_PC)
);
// END PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::


// ::: INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

wire IFIFO_enq_ready;

wire ififo_entry_t IFIFO_enq_data;
assign IFIFO_enq_data.instr = selected_instr;
assign IFIFO_enq_data.pc = PC_wire;
assign IFIFO_enq_data.is_cond_br = is_cond_branch;
assign IFIFO_enq_data.br_dir_pred = br_prediction;
assign IFIFO_enq_data.br_target_pred = next_PC;

fifo #(
    .ENTRY_WIDTH(`IFIFO_ENTRY_WIDTH),
    .N_ENTRIES(8)
) instruction_FIFO (
    .flush(fetch_redirect_valid),
    .clk(clk),
    .rst_aL(rst_aL),
    .enq_data(IFIFO_enq_data),   // input - data
    .enq_ready(IFIFO_enq_ready), // output - can fifo receive data?
    .enq_valid(icache_hit),      // input - enqueue if icache hit
    .deq_ready(ififo_dispatch_ready),  // input - interface from dispatch
    .deq_valid(ififo_dispatch_valid),     // output - interface to dispatch
    .deq_data(ififo_dispatch_data) // output - dispatched instr
);

INV_X1 instr_FIFO_stall (
    .A(IFIFO_enq_ready),
    .ZN(IFIFO_stall)
);
// END INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// END::::::::: internal IFU module instantiations ::::::::::::::::::::::::::::::

endmodule

`endif
