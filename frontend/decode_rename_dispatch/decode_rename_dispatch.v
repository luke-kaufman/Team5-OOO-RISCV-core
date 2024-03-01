module decode_rename_dispatch #() (
    input wire clk,
    input wire rst_aL,
    // INTERFACE TO FETCH
    input wire instr_valid,
    input wire [INSTR_WIDTH-1:0] instr,
);
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

    // Register Alias Table: ARF/ROB Table
    regfile32_3r1w #(.DATA_WIDTH(1)) arf_rob_table (
        .clk(clk),
        .rst_aL(rst_aL),
        .rd_addr0(),
        .rd_addr1(),
        .rd_addr2(),
        .wr_addr(),
        .wr_en(),
        .wr_data()
    );
    // Register Alias Table: Tag Table
    regfile32_2r2w #(.DATA_WIDTH(4)) tag_table (
        .clk(clk),
        .rst_aL(rst_aL),
        .rd_addr0(),
        .rd_addr1(),
        .wr_addr0(),
        .wr_addr1(),
        .wr_en0(),
        .wr_en1(),
        .wr_data0(),
        .wr_data1()
    )

    // 
    fifo16 rob (
        .clk(clk),
        .rst_aL(rst_aL),
        .wr_en(),
        .wr_data(),
        .rd_en(),
        .rd_data()
    )
endmodule