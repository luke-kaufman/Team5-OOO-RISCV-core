// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module regfile32_2r2w #(
    parameter DATA_WIDTH = 32,
    localparam REGFILE_DEPTH = 32,
    localparam ADDR_WIDTH = $clog2(REGFILE_DEPTH)
) (
    input wire clk,
    input wire rst_aL,
    input wire [ADDR_WIDTH-1:0] rd_addr0,
    input wire [ADDR_WIDTH-1:0] rd_addr1,
    input wire [ADDR_WIDTH-1:0] wr_addr0,
    input wire [ADDR_WIDTH-1:0] wr_addr1,
    input wire wr_en0,
    input wire wr_en1,
    input wire [DATA_WIDTH-1:0] wr_data0,
    input wire [DATA_WIDTH-1:0] wr_data1,
    output wire [DATA_WIDTH-1:0] rd_data0,
    output wire [DATA_WIDTH-1:0] rd_data1
);
    // decode the write address to a one-hot representation
    wire [REGFILE_DEPTH-1:0] wr_addr0_onehot;
    wire [REGFILE_DEPTH-1:0] wr_addr1_onehot;
    decoder #(.IN_WIDTH(ADDR_WIDTH)) dec0 (
        .in(wr_addr0),
        .out(wr_addr0_onehot)
    );
    decoder #(.IN_WIDTH(ADDR_WIDTH)) dec1 (
        .in(wr_addr1),
        .out(wr_addr1_onehot)
    );

    // gate the write enable signals
    wire [REGFILE_DEPTH-1:0] we0;
    wire [REGFILE_DEPTH-1:0] we1;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            AND2_X1 we0_gate (
                .A1(wr_en0),
                .A2(wr_addr0_onehot[i]),
                .ZN(we0[i])
            );
            AND2_X1 we1_gate (
                .A1(wr_en1),
                .A2(wr_addr1_onehot[i]),
                .ZN(we1[i])
            );
        end
    endgenerate

    // combine the write enable signals
    wire [REGFILE_DEPTH-1:0] we;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            OR2_X1 we_or (
                .A1(we0[i]),
                .A2(we1[i]),
                .ZN(we[i])
            );
        end
    endgenerate

    // ff1 for the one-hot select signals of the mux to select the data input of each register file entry
    wire [REGFILE_DEPTH-1:0] din_mux_sel;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            ff1_2 din_mux_sel_ff1 (
                // we0 has priority over we1
                .d({we1[i], we0[i]}),
                .q(din_mux_sel[i])
            );
        end
    endgenerate

    // select the data input of each register file entry
    wire [DATA_WIDTH-1:0] [REGFILE_DEPTH-1:0] din;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            mux2 #(.WIDTH(DATA_WIDTH)) din_mux (
                .sel(din_mux_sel[i]),
                .in0(wr_data0),
                .in1(wr_data1),
                .out(din[i])
            );
        end
    endgenerate

    // the register file entries
    wire [DATA_WIDTH-1:0] [REGFILE_DEPTH-1:0] entry_douts;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            register #(.DATA_WIDTH(DATA_WIDTH)) regfile_entry (
                .clk(clk),
                .rst_aL(rst_aL),
                .we(we[i]),
                .din(din[i]),
                .dout(entry_douts[i])
            );
        end
    endgenerate

    // select the read data
    mux32 #(.WIDTH(DATA_WIDTH)) rd_addr0_mux (
        .ins(entry_douts),
        .sel(rd_addr0),
        .out(rd_data0)
    );
    mux32 #(.WIDTH(DATA_WIDTH)) rd_addr1_mux (
        .ins(entry_douts),
        .sel(rd_addr1),
        .out(rd_data1)
    );
endmodule