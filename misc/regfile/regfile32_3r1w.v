// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module regfile32_3r1w #(
    parameter DATA_WIDTH = 32,
    localparam REGFILE_DEPTH = 32,
    localparam ADDR_WIDTH = $clog2(REGFILE_DEPTH)
) (
    input wire clk,
    input wire rst_aL,
    input wire [ADDR_WIDTH-1:0] rd_addr0,
    input wire [ADDR_WIDTH-1:0] rd_addr1,
    input wire [ADDR_WIDTH-1:0] rd_addr2,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] rd_data0,
    output wire [DATA_WIDTH-1:0] rd_data1,
    output wire [DATA_WIDTH-1:0] rd_data2
);
    // decode the write address to a one-hot representation
    wire [REGFILE_DEPTH-1:0] wr_addr_onehot;
    decoder #(.IN_WIDTH(ADDR_WIDTH)) dec (
        .in(wr_addr),
        .out(wr_addr_onehot)
    );

    // gate the write enable signals
    wire [REGFILE_DEPTH-1:0] we;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            AND2_X1 we_gate (
                .A1(wr_en),
                .A2(wr_addr_onehot[i]),
                .ZN(we[i])
            );
        end
    endgenerate

    // the register file entries
    wire [DATA_WIDTH-1:0] [REGFILE_DEPTH-1:0] entry_douts;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            register #(.WIDTH(DATA_WIDTH)) regfile_entry (
                .clk(clk),
                .rst_aL(rst_aL),
                .we(we[i]),
                .din(wr_data),
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
    mux32 #(.WIDTH(DATA_WIDTH)) rd_addr2_mux (
        .ins(entry_douts),
        .sel(rd_addr2),
        .out(rd_data2)
    );
endmodule