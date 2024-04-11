`ifndef IFU_V
`define IFU_V

`include "misc/global_defs.svh"
`include "freepdk-45nm/stdcells.v"
`include "misc/cache.v"
`include "misc/fifo.v"
`include "frontend/fetch/predicted_NPC.v"

// Instruction Fetch Unit
module ifu #(
    parameter I$_BLOCK_SIZE = `ICACHE_DATA_BLOCK_SIZE,
    parameter I$_NUM_SETS = `ICACHE_NUM_SETS,
    parameter I$_NUM_WAYS = `ICACHE_NUM_WAYS
) (
    input wire clk,
    input wire rst_aL,
    input wire [`ADDR_WIDTH-1:0] recovery_PC,
    input wire recovery_PC_valid,
    input wire backend_stall, 
    input wire [I$_BLOCK_SIZE-1:0] dram_response,
    input wire dram_response_valid,

    //testing
    input wire csb0_in,
    
    // INTERFACE TO RENAME
    input wire dispatch_ready,
    output wire instr_valid,
    output wire [`IFIFO_ENTRY_WIDTH-1:0] instr_to_dispatch
);

// wires
wire icache_miss;
wire [`ADDR_WIDTH-1:0] next_PC;
wire IFIFO_full_stall;

// ::: PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// Stall aggregator (OR-gate)
OR2_X1 stall_gate (
    .A1(icache_miss),
    .A2(IFIFO_full_stall)
);

mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(4)
) PC_mux(   
    .ins({recovery_PC, // if recovery
          recovery_PC, // if recovery
          PC.dout,     // if stall
          next_PC      // predicted nextPC
          }),
    .sel({recovery_PC_valid, stall_gate.ZN})
);

wire [`ADDR_WIDTH-1:0] PC_wire;
reg_ #(.WIDTH(`ADDR_WIDTH)) PC (
    .clk(clk),
    .rst_aL(rst_aL),
    .we(1'b1),  // always write since PC_mux will feed PC itself when stalling
    .din(PC_mux.out),
    .dout(PC_wire)
);
// END PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
INV_X1 icmiss(
    .A(icache.cache_hit),
    .ZN(icache_miss)
);

wire icache_we_aL;
INV_X1 response_v_to_we_aL (
    .A(dram_response_valid),
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
    .addr(PC_mux.out),
    .d_cache_is_ST(1'b0), // not used in icache
    .we_aL(icache_we_aL),
    .write_data(dram_response),

    .csb0_in(csb0_in)
);

// select instruction within way
wire [`INSTR_WIDTH-1:0] selected_instr;
mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(2)
) instr_in_way_mux (
    .ins({icache.selected_data_way[(I$_BLOCK_SIZE - 1):`ADDR_WIDTH],
          icache.selected_data_way[(`ADDR_WIDTH - 1):0]}),
    .sel(PC_wire[0]),
    .out(selected_instr)
);
// END ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::
wire br_prediction;
wire is_cond_branch;
predicted_NPC #() pred_NPC (
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
    .clk(clk),
    .rst_aL(rst_aL),
    .enq_ready(IFIFO_enq_ready), // output
    .enq_valid(icache.cache_hit),  // input
    .enq_data(IFIFO_enq_data),
    .deq_ready(dispatch_ready),   // input
    .deq_valid(instr_valid),  // output
    .deq_data(instr_to_dispatch)
);

NAND2_X1 instr_FIFO_stall (
    .A1(IFIFO_enq_ready),
    .A2(icache.cache_hit),
    .ZN(IFIFO_full_stall)
);
// END INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// END::::::::: internal IFU module instantiations ::::::::::::::::::::::::::::::

endmodule

`endif
