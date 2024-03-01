// Instruction Fetch Unit
module ifu #(
    parameter I$_BLOCK_SIZE = ICACHE_DATA_BLOCK_SIZE
    parameter I$_NUM_SETS = ICACHE_NUM_SETS,
    parameter I$_NUM_WAYS = ICACHE_NUM_WAYS,
) (
    input wire [ADDR_WIDTH-1:0] recovery_PC,
    input wire recovery_PC_valid,
    input wire backend_stall, 
    input wire [I$_BLOCK_SIZE-1:0] dram_response,
    input wire dram_response_valid,
    
    // INTERFACE TO RENAME
    input wire dispatch_ready,
    output wire instr_valid,
    output wire [INSTR_WIDTH-1:0] instr_data,
);

// ::: PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
mux4 #(.WIDTH(ADDR_WIDTH)) (
    .d0(next_PC),
    .d1(recovery_PC),
    .d2(),
    .d3(recovery_PC),
    .s(),
    .y()
);

register #(.WIDTH(ADDR_WIDTH)) PC (
    .clk(),
    .rst_aL(),
    .we(),
    .din(),
    .dout()
);
// END PC MUX & PC :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
wire [I$_BLOCK_SIZE-1:0] icache_out_way;
wire icache_hit;
wire icache_miss;
INV_X1 icmiss(
    .A(icache_hit),
    .ZN(icache_miss)
);
cache #(
    .ADDR_WIDTH(ADDR_WIDTH)     
    .I$_BLOCK_SIZE(I$_BLOCK_SIZE),  
    .I$_NUM_SETS(I$_NUM_SETS),
    .I$_NUM_WAYS(I$_NUM_WAYS),
) icache (
    .PC(PC),
    .we(/*TODO*/),
    .write_data(/*TODO*/),
    .selected_data_way(icache_out_way),
    .icache_hit(icache_hit)
);

// select instruction within way
wire [INSTR_WIDTH-1:0] selected_instr;
mux2 #(ADDR_WIDTH) instr_in_way_mux (
    .d0(icache_out_way[I$_BLOCK_SIZE:(I$_BLOCK_SIZE/I$_NUM_WAYS)]),
    .d1(icache_out_way[(I$_BLOCK_SIZE/I$_NUM_WAYS - 1):0]),
    .s(PC[NUM_OFFSET_BITS-1]),
    .y(selected_instr)
);
// END ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::
wire br_prediction;
wire is_cond_branch;
wire [ADDR_WIDTH-1:0] next_PC;
predicted_NPC #() pred_NPC (
    .instr(selected_instr),
    .PC(PC),
    .is_cond_branch(is_cond_branch),
    .br_prediction(br_prediction),
    .next_PC(next_PC)
);
// END PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::

// ::: INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
`define IFIFO_ENTRY_WIDTH (INSTR_WIDTH /*instruction*/ 
                         + ADDR_WIDTH /*PC*/
                         + 1 /*branch info valid bit*/
                         + 1 /*Prediction bit - 1 taken, 0 not taken*/
                         + ADDR_WIDTH /*TARGET PC*/)
wire IFIFO_ready_enq;
wire [IFIFO_ENTRY_WIDTH-1:0] IFIFO_data_enq = {selected_instr,
                                                PC,
                                                is_cond_branch,  // branch info valid bit
                                                br_prediction,
                                                br_target_PC}
fifo #(
    .DATA_WIDTH(IFIFO_ENTRY_WIDTH),
    .FIFO_DEPTH(8)
) instruction_FIFO (
    .clk(clk),
    .rst_aL(rst_aL),
    .ready_enq(IFIFO_ready_enq), // output
    .valid_enq(icache_hit),  // input
    .data_enq(IFIFO_data_enq),
    .ready_deq(dispatch_ready),   // input
    .valid_deq(instr_valid,),  // output
    .data_deq(instr_data)
);

wire IFIFO_full_stall;
NAND2_X1 instr_FIFO_stall (
    .A1(IFIFO_ready_enq),
    .A2(icache_hit),
    .ZN(IFIFO_full_stall)
)
// END INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// END::::::::: internal IFU module instantiations ::::::::::::::::::::::::::::::

endmodule



