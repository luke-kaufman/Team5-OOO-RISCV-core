module decode_rename_dispatch #() (
    // INTERFACE TO FETCH
    input wire instr_to_decode_valid,
    input wire [INSTR_WIDTH-1:0] instr_to_decode,
);
    rat #() rat (
        .dispatch_ready(dispatch_ready),
        .instr_valid(instr_valid),
        .instr_data(instr_data),
    );
endmodule