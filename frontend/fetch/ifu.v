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
    
    output wire instr_o
);

// :::::::::::: internal IFU wires and registers between modules :::::::::::::::

register #(.WIDTH(ADDR_WIDTH)) PC;

// to nextPC mux
wire IFIFO_full_stall;
wire i$_miss_stall;
// TODO: maybe predict jalr target later? or PC + 4
wire jalr_stall;

// END::::::::: internal IFU wires and registers between modules :::::::::::::::

// :::::::::::: internal IFU module instantiations :::::::::::::::::::::::::::::

// ::: ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
wire [I$_BLOCK_SIZE-1:0] icache_out_way;
wire icache_hit;
cache icache # (
    .ADDR_WIDTH(ADDR_WIDTH)     
    .I$_BLOCK_SIZE(I$_BLOCK_SIZE),  
    .I$_NUM_SETS(I$_NUM_SETS),
    .I$_NUM_WAYS(I$_NUM_WAYS),
) (
    .PC(PC),
    .we(/*TODO*/),
    .write_data(/*TODO*/),
    .selected_data_way(icache_out_way),
    .icache_hit(icache_hit)
);

// select instruction within way
wire [ADDR_WIDTH-1:0] selected_instr;
mux2 #(ADDR_WIDTH) instr_in_way_mux (
    .d0(icache_out_way[I$_BLOCK_SIZE:(I$_BLOCK_SIZE/I$_NUM_WAYS)]),
    .d1(icache_out_way[(I$_BLOCK_SIZE/I$_NUM_WAYS - 1):0]),
    .s(PC[NUM_OFFSET_BITS-1]),
    .y(selected_instr)
);
// END ICACHE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::
predicted_NPC #() pred_NPC (

);
// END PREDICTED NEXT PC BLOCK :::::::::::::::::::::::::::::::::::::::::::::::::

// ::: INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
fifo #(
    .DATA_WIDTH(INSTR_WIDTH /*instruction*/ 
              + ADDR_WIDTH /*PC*/
              + 1 /*Prediction bit - 1 taken, 0 not taken*/
              + ADDR_WIDTH /*TARGET PC*/),
    .FIFO_DEPTH(8)
) instruction_FIFO (
    
);
// END INSTRUCTION FIFO ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// END::::::::: internal IFU module instantiations ::::::::::::::::::::::::::::::

endmodule



