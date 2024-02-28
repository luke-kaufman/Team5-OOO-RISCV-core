module decode_rename_dispatch #() (
    input clk,
    // INTERFACE TO FETCH
    input wire instr_to_decode_valid,
    input wire [INSTR_WIDTH-1:0] instr_to_decode,
);
    regfile32_2r2w #(.DATA_WIDTH(4)) tag_table (
        .clk

    regfile32_3r1w #(.DATA_WIDTH(1)) arf_rob_table (
        .clk
endmodule