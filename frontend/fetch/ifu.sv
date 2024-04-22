`ifndef IFU_V
`define IFU_V

`include "misc/global_defs.svh"
// `include "freepdk-45nm/stdcells.v"
`include "memory/cache.sv"
`include "misc/fifo.v"
`include "frontend/fetch/predicted_NPC.v"

// Instruction Fetch Unit
module ifu (
    // from top.sv
    input wire clk,
    input wire init,
    input addr_t init_pc,
    input wire rst_aL,
    // input wire csb0_in,
    // backend interactions
    input wire [`ADDR_WIDTH-1:0] recovery_PC,
    input wire fetch_redirect_valid,
    // MEM CTRL REQUEST
    output logic mem_ctrl_req_valid,
    output main_mem_block_addr_t mem_ctrl_req_block_addr,
    input logic mem_ctrl_req_ready,
    // MEM CTRL RESPONSE
    input logic mem_ctrl_resp_valid,
    input block_data_t mem_ctrl_resp_block_data,
    // IFU <-> DISPATCH
    input wire ififo_dispatch_ready,
    output wire ififo_dispatch_valid,
    output wire [`IFIFO_ENTRY_WIDTH-1:0] ififo_dispatch_data

);

// wires
wire icache_hit;
wire icache_miss;
wire [`ICACHE_DATA_BLOCK_SIZE-1:0] icache_data_way;
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
    // .A3(backend_stall),
    .A3('0),
    .ZN(stall)
);

mux_ #(
    .WIDTH(`ADDR_WIDTH),
    .N_INS(4)
) PC_mux(
    .ins({recovery_PC, // if recovery
          recovery_PC, // if recovery
          PC_wire,     // if stall
          next_PC      // predicted nextPC
          }),
    .sel({fetch_redirect_valid, stall}),
    .out(PC_mux_out)
);

reg_ #(.WIDTH(`ADDR_WIDTH)) PC (
    // NO FLUSH HERE, NEED TO WRITE NEW PC DURING THAT
    .clk(clk),
    .rst_aL(rst_aL),
    .flush(fetch_redirect_valid),
    .we(1'b1),  // always write since PC_mux will feed PC itself when stalling
    .din(PC_mux_out),
    .dout(PC_wire),

    .init(init),
    .init_state(init_pc)
);
// END PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
INV_X1 icmiss(
    .A(icache_hit),
    .ZN(icache_miss)
);

wire [`INSTR_WIDTH-1:0] selected_instr;
cache #(
    .CACHE_TYPE(ICACHE),
    .N_SETS(`ICACHE_NUM_SETS)
) icache (
    .clk(clk),  /*input logic*/
    .rst_aL(rst_aL),  /*input logic*/
    .init(init),  /*input logic*/
    .flush(fetch_redirect_valid),  /*input logic*/  // TODO: do we have to flush anything in cache? (we don't need to flush the lfsr)

    // FROM PIPELINE TO CACHE (REQUEST) (LATENCY-SENSITIVE)
    .pipeline_req_valid(1'b1), // can change /*input logic*/
    .pipeline_req_type(READ), /*input req_type_t*/ // 0: read 1: write
    .pipeline_req_width(WORD), //** Shouldnt matter? /*input req_width_t*/ // 0: byte 1: halfword 2: word (only for dcache and stores)
    .pipeline_req_addr(PC_mux_out), /*input addr_t*/
    .pipeline_req_wr_data(), /*input word_t*/ // (only for writes)

    // FROM CACHE TO MEM_CTRL (REQUEST) (LATENCY-INSENSITIVE)
    .mem_ctrl_req_valid(mem_ctrl_req_valid), /*output logic*/
    .mem_ctrl_req_type(READ), // NOT USED always read /*output req_type_t*/ // 0: read 1: write
    .mem_ctrl_req_block_addr(mem_ctrl_req_block_addr), /*output main_mem_block_addr_t*/
    .mem_ctrl_req_block_data(), /* NOT USED output block_data_t*/ // (only for dcache and stores)
    .mem_ctrl_req_ready(mem_ctrl_req_ready), /*input logic*/ // (icache has priority. for icache if valid is true then ready is also true.)

    // FROM MEM_CTRL TO CACHE (RESPONSE) (LATENCY-SENSITIVE)
    .mem_ctrl_resp_valid(mem_ctrl_resp_valid), /*input logic*/
    .mem_ctrl_resp_block_data(mem_ctrl_resp_block_data), /*input block_data_t*/

    // FROM CACHE TO PIPELINE (RESPONSE)
    .pipeline_resp_valid(icache_hit), /*output logic*/ // cache hit
    .pipeline_resp_rd_data(selected_instr) /*output block_data_t*/
);

// cache #(
//     .BLOCK_SIZE_BITS(`ICACHE_DATA_BLOCK_SIZE),
//     .NUM_SETS(I$_NUM_SETS),
//     .NUM_WAYS(I$_NUM_WAYS),
//     .NUM_TAG_CTRL_BITS(`ICACHE_NUM_TAG_CTRL_BITS),  // 1 for valid bit
//     .WRITE_SIZE_BITS(`ICACHE_WRITE_SIZE_BITS)    // 64 for icache (DRAMresponse)
// ) icache (
//     .clk(clk),
//     .rst_aL(rst_aL),
//     .addr(PC_mux_out),
//     .PC_addr(PC.dout),
//     .dcache_is_ST(1'b0), // not used in icache
//     .we_aL(icache_we_aL),
//     .write_data(recv_main_mem_data),
//     .csb0_in(csb0_in),

//     .cache_hit(icache_hit),
//     .selected_data_way(icache_data_way)
// );
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
    .clk(clk),
    .init(init),
    .rst_aL(rst_aL),

    .flush(fetch_redirect_valid),
    .enq_data(IFIFO_enq_data),   // input - data
    .enq_ready(IFIFO_enq_ready), // output - can fifo receive data?
    .enq_valid(icache_hit),      // input - enqueue if icache hit
    .deq_ready(ififo_dispatch_ready),  // input - interface from dispatch
    .deq_valid(ififo_dispatch_valid),     // output - interface to dispatch
    .deq_data(ififo_dispatch_data), // output - dispatched instr

    .init_entry_reg_state('0),
    .init_enq_up_counter_state('0),
    .init_deq_up_counter_state('0),
    .current_entry_reg_state(),
    .current_enq_up_counter_state(),
    .current_deq_up_counter_state()
);

INV_X1 instr_FIFO_stall (
    .A(IFIFO_enq_ready),
    .ZN(IFIFO_stall)
);
// END INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// END::::::::: internal IFU module instantiations ::::::::::::::::::::::::::::::

endmodule

`endif
