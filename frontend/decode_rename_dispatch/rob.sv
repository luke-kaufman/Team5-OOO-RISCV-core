`include "misc/fifo_ram.v"
`include "misc/global_defs.svh"
`include "misc/mux/mux_.v"
`include "misc/and/and_.v"
`include "misc/inv.v"
`include "freepdk-45nm/stdcells.v"

module rob #(
    // localparam REG_DATA_BITS_END = `REG_WIDTH - 1,
    // localparam REG_READY_BIT_END = REG_DATA_BITS_END + 1,
    // localparam BR_MISPREDICT_BIT_END = REG_READY_BIT_END + 1,
    // localparam LD_MISPREDICT_BIT_END = BR_MISPREDICT_BIT_END + 1,
    // localparam PC_BITS_END = LD_MISPREDICT_BIT_END + `PC_WIDTH,
    // localparam DST_ARF_ID_BITS_END = PC_BITS_END + `ARF_ID_WIDTH,
    // localparam DST_VALID_BIT_END = DST_ARF_ID_BITS_END + 1, // the index of the last bit
    // localparam ENTRY_WIDTH = DST_VALID_BIT_END + 1 // the number of bits as opposed to the index of the last bit
    localparam ENTRY_WIDTH = $bits(rob_entry_t)
) (
    input wire clk,
    input wire rst_aL,

    // READY-THEN-VALID INTERFACE TO FETCH (ENQUEUE)
    output wire rob_dispatch_ready, // helping ready (ROB)
    input wire dispatch_valid, // demanding valid (ififo triple handshake with ROB, IIQ, and LSQ)
    input rob_dispatch_data_t rob_dispatch_data,

    // INTERFACE TO ARF (DEQUEUE)
    // ARF is always ready to accept data
    output wire retire_valid,
    output wire [`REG_WIDTH-1:0] retire_reg_data,

    // src1 ready/data info (REGISTER READ)
    input wire [`ROB_ID_WIDTH-1:0] rob_id_src1,
    output wire rob_reg_ready_src1,
    output wire [`REG_WIDTH-1:0] rob_reg_data_src1,
    // src2 ready/data info (REGISTER READ)
    input wire [`ROB_ID_WIDTH-1:0] rob_id_src2,
    output wire rob_reg_ready_src2,
    output wire [`REG_WIDTH-1:0] rob_reg_data_src2,

    // INTERFACE TO ALU (WRITEBACK)
    input wire wb_valid_alu,
    input wire [`ROB_ID_WIDTH-1:0] wb_rob_id_alu,
    input wire [`REG_WIDTH-1:0] wb_reg_data_alu,
    input wire wb_br_mispredict,

    // INTERFACE TO LSU (WRITEBACK)
    input wire wb_valid_lsu,
    input wire [`ROB_ID_WIDTH-1:0] wb_rob_id_lsu,
    input wire [`REG_WIDTH-1:0] wb_reg_data_lsu,
    input wire wb_ld_mispredict
);
    rob_entry_t [`ROB_N_ENTRIES-1:0] rob_state;
    rob_entry_t entry_wr_data_alu;
    rob_entry_t entry_wr_data_lsu;
    rob_wb_data_t wb_data_alu;
    rob_wb_data_t wb_data_lsu;

    // TODO: check the correctness of these entry_wr_data values for each instruction type
    // select the old reg_data/mispredict state or the new wb_reg_data/mispredict state depending on the wb_valid signal
    // for (genvar i = 0; i < `ROB_N_ENTRIES; i++) begin
    //     mux_ #(.N_INS(2), .WIDTH(BR_MISPREDICT_BIT_END+1)) wb_data_alu_mux (
    //         .sel(wb_valid_alu),
    //         .ins({
    //             rob_state[wb_rob_id_alu][BR_MISPREDICT_BIT_END:0],
    //             {wb_br_mispredict, 1'b1 /* REG READY */, wb_reg_data_alu}
    //         }),
    //         .out(wb_data_alu)
    //     );
    //     mux_ #(.N_INS(2), .WIDTH(LD_MISPREDICT_BIT_END+1)) wb_data_lsu_mux (
    //         .sel(wb_valid_lsu),
    //         .ins({
    //             rob_state[wb_rob_id_lsu][LD_MISPREDICT_BIT_END:0],
    //             {wb_ld_mispredict, rob_state[BR_MISPREDICT_BIT_END] /* BR MISPREDICT STATE */, 1'b1 /* REG READY */, wb_reg_data_lsu}
    //         }),
    //         .y(wb_data_lsu)
    //     );
    //     assign entry_wr_data_alu = {rob_state[wb_rob_id_alu][DST_VALID_BIT_END:LD_MISPREDICT_BIT_END], wb_data_alu};
    //     assign entry_wr_data_lsu = {rob_state[wb_rob_id_lsu][DST_VALID_BIT_END:BR_MISPREDICT_BIT_END], wb_data_lsu};
    // end

    rob_entry_t entry_rd_data_src1;
    rob_entry_t entry_rd_data_src2;
    rob_entry_t dispatch_entry_data;
    rob_entry_t retire_entry_data;
    fifo_ram #(
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_ENTRIES(`ROB_N_ENTRIES),
        .N_READ_PORTS(2),
        .N_WRITE_PORTS(2)
    ) rob (
        .clk(clk),
        .rst_aL(rst_aL),
        
        .enq_ready(rob_dispatch_ready),
        .enq_valid(dispatch_valid),
        .enq_data(dispatch_entry_data),

        // ARF is always ready to accept data
        .deq_valid(retire_valid),
        .deq_data(retire_entry_data),

        .rd_addr({rob_id_src1, rob_id_src2}),
        .rd_data({entry_rd_data_src1, entry_rd_data_src2}),

        .wr_en({wb_valid_alu, wb_valid_lsu}),
        .wr_addr({wb_rob_id_alu, wb_rob_id_lsu}),
        .wr_data({entry_wr_data_alu, entry_wr_data_lsu}),

        .entry_douts(rob_state)
    );

    // NOTE: currently ignoring load mispredicts while reading reg data
    assign rob_reg_ready_src1 = entry_rd_data_src1.reg_ready;
    assign rob_reg_data_src1 = entry_rd_data_src1.reg_data;
    assign rob_reg_ready_src2 = entry_rd_data_src2.reg_ready;
    assign rob_reg_data_src2 = entry_rd_data_src2.reg_data;

    wire not_br_mispredict;
    wire not_ld_mispredict;
    inv br_mispredict_inv (
        .a(retire_entry_data.br_mispredict),
        .y(not_br_mispredict)
    );
    inv ld_mispredict_inv (
        .a(retire_entry_data.ld_mispredict),
        .y(not_ld_mispredict)
    );
    and_ #(.N_INS(4)) retire_valid_and (
        .a({retire_entry_data.dst_valid, retire_entry_data.reg_ready, not_br_mispredict, not_ld_mispredict}),
        .y(retire_valid)
    );
    assign retire_reg_data = retire_entry_data.reg_data;
endmodule
