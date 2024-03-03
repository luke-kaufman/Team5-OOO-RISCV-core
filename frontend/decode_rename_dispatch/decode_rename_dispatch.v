`include "freepdk-45nm/stdcells.v"
`include "misc/regfile/regfile32_2r2w.v"
`include "misc/regfile/regfile32_3r1w.v"
`include "misc/fifo.v"

module decode_rename_dispatch #(
    localparam ROB_DISPATCH_DATA_WIDTH = ,
    localparam IIQ_DISPATCH_DATA_WIDTH = ,
    localparam LSQ_DISPATCH_DATA_WIDTH = ,
) (
    input wire clk,
    input wire rst_aL,
    // INTERFACE TO FETCH
    input wire instr_valid,
    input wire [INSTR_WIDTH-1:0] instr,
    // INTERFACE TO INTEGER ISSUE QUEUE
    input wire iiq_dispatch_ready,
    output wire iiq_dispatch_valid,
    output wire [IIQ_DISPATCH_DATA_WIDTH-1:0] iiq_dispatch_data,
    // INTERFACE TO LOAD/STORE QUEUE
    input wire lsq_dispatch_ready,
    output wire lsq_dispatch_valid,
    output wire [LSQ_DISPATCH_DATA_WIDTH-1:0] lsq_dispatch_data
);
    // internal signals
    wire rs1_valid;
    wire rs2_valid;
    wire rd_valid;
    wire [REG_BITS-1:0] rs1;
    wire [REG_BITS-1:0] rs2;
    wire [REG_BITS-1:0] rd;
    wire rs1_retired;
    wire rs2_retired;
    
    wire dispatch;

    // TODO: FIX
    instr_decode instr_decode (
        .clk(clk),
        .rst_aL(rst_aL),
        .instr_valid(instr_valid),
        .instr(instr),
        .decoded_instr(decoded_instr),
        .instr_type(instr_type),
        .src1(src1),
        .src2(src2),
        .dst(dst),
        .imm(imm),
        .branch(branch),
        .branch_target(branch_target),
        .valid(valid)
    );

    // Register Alias Table: ARF/ROB Table [0: ARF (retired), 1: ROB (speculative)]
    regfile32_2r2w #(.DATA_WIDTH(4)) arf_rob_table (
        .clk(clk),
        .rst_aL(rst_aL),
        
        .rd_addr0(rs1),
        .rd_data0(rs1_retired),
        
        .rd_addr1(rs2),
        .rd_data1(rs2_retired),
        
        // (synchronous) reset port to mark rd as retired
        .wr_en0(),
        .wr_addr0(),
        .wr_data0(1'b0),
        
        // (synchronous) set port to mark rd as speculative
        .wr_en1(),
        .wr_addr1(rd),
        .wr_data1(1'b1)
    );
    // Register Alias Table: Tag Table
    regfile32_3r1w #(.DATA_WIDTH(1)) tag_table (
        .clk(clk),
        .rst_aL(rst_aL),

        .rd_addr0(rs1),
        .rd_data0(),

        .rd_addr1(rs2),
        .rd_data1(),

        .rd_addr2(),
        .rd_data2(),
        // write port to rename rd to a new speculative (ROB) tag
        .wr_en(),
        .wr_addr(rd),
        .wr_data()
    );
    
    fifo rob #(
        .DATA_WIDTH(ROB_DISPATCH_DATA_WIDTH),
        .FIFO_DEPTH(16)
    ) (
        .clk(clk),
        .rst_aL(rst_aL),
        .ready_enq(dispatch),

    )
endmodule