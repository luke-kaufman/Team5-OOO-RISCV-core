module load_store_issue #(

) (
    input wire clk,
    input wire rst_aL,

);
    shift_queue lsq (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(),
        .enq_valid(),
        .enq_data(),

        .deq_ready(),
        .deq_sel_onehot(),
        .deq_valid(),
        .deq_data(),

        .wr_en(),
        .wr_data(),

        .entry_douts(),
    );
endmodule