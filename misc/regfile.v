module regfile #(
    parameter N_READ_PORTS = 1,
    parameter N_WRITE_PORTS = 1,
    parameter REGFILE_DEPTH = 32,
    parameter DATA_WIDTH = 32,
    localparam ADDR_WIDTH = $clog2(REGFILE_DEPTH)
) (
    input wire clk,
    input wire rst_aL,
    input wire [ADDR_WIDTH-1:0] [N_READ_PORTS-1:0] rd_addr,
    input wire [ADDR_WIDTH-1:0] [N_WRITE_PORTS-1:0] wr_addr,
    input wire [N_WRITE_PORTS-1:0] wr_en,
    input wire [DATA_WIDTH-1:0] [N_WRITE_PORTS-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] [N_READ_PORTS-1:0] rd_data
);
    // generate the decoders for the write addresses
    wire [REGFILE_DEPTH-1:0] [N_WRITE_PORTS-1:0] wr_addr_onehot;
    generate
        for (genvar i = 0; i < N_WRITE_PORTS; i = i + 1) begin
            decoder #(.IN_WIDTH(ADDR_WIDTH)) dec (
                .in(wr_addr[i]),
                .out(wr_addr_onehot[i])
            );
        end
    endgenerate

    // generate the addressed write enable signals for each write port
    wire [REGFILE_DEPTH-1:0] [N_WRITE_PORTS-1:0] wr_en_addressed;
    generate
        for (genvar i = 0; i < N_WRITE_PORTS; i = i + 1) begin
                for (genvar j = 0; j < REGFILE_DEPTH; j = j + 1) begin
                    AND2_X1 and_gate (
                        .A1(wr_en[i]),
                        .A2(wr_addr_onehot[i][j]),
                        .ZN(wr_en_addressed[i][j])
                    );
                end
        end
    endgenerate

    // generate the write enable signals for each register file entry
    wire [REGFILE_DEPTH-1:0] [N_WRITE_PORTS-1:0] we;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            Or #(.WIDTH(N_WRITE_PORTS)) or_gate (
                .ins(wr_en_addressed[N_WRITE_PORTS-1:0][i]),
                .out(we[i])
            );
        end
    endgenerate

    // generate the ff1s for the one-hot select signals of the data in mux of each register file entry
    wire [REGFILE_DEPTH-1:0] [N_WRITE_PORTS-1:0] wr_addr_onehot_ff1;
    generate
        for (genvar i = 0; i < N_WRITE_PORTS; i = i + 1) begin
            ff1 #(.WIDTH(REGFILE_DEPTH)) wr_addr_onehot_ff1_inst (
                .d(wr_addr_onehot[i]),
                .q(wr_addr_onehot_ff1[i])
            );
        end
    endgenerate

    // generate the muxes for the write data of each register file entry
    wire [DATA_WIDTH-1:0] [REGFILE_DEPTH-1:0] entry_dins;
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            mux #(.WIDTH(DATA_WIDTH), .N_INS(N_WRITE_PORTS)) wr_data_mux (
                .ins(wr_data),
                .sel(wr_addr),
                .out(entry_dins[i])
            );
        end
    endgenerate

    // generate the register file entries
    wire [DATA_WIDTH-1:0] entry_douts [REGFILE_DEPTH-1:0];
    generate
        for (genvar i = 0; i < REGFILE_DEPTH; i = i + 1) begin
            register #(.DATA_WIDTH(DATA_WIDTH)) regfile_entry (
                .clk(clk),
                .rst_aL(rst_aL),
                .we(we[0][i]),
                .din(wr_data[0]),
                .dout(entry_douts[i])
            );
        end
    endgenerate

endmodule