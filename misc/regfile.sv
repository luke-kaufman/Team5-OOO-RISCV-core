`ifndef REGFILE_V
`define REGFILE_V

`include "misc/dec/dec_.v"
`include "misc/and/and_.v"
`include "misc/ff1/ff1.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module regfile #(
    parameter ENTRY_WIDTH = 32,
    parameter N_ENTRIES = 32,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),

    parameter N_READ_PORTS = 2,
    parameter N_WRITE_PORTS = 1
) (
    input wire clk,
    input wire rst_aL,

    input wire [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr,
    output wire [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data,

    input wire [N_WRITE_PORTS-1:0] wr_en,
    input wire [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr,
    input wire [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data
);
    // decode the write address(es) to a one-hot representation
    wire [N_WRITE_PORTS-1:0] [N_ENTRIES-1:0] wr_addr_onehot;
    for (genvar i = 0; i < N_WRITE_PORTS; i++) begin
        dec_ #(.IN_WIDTH(PTR_WIDTH)) wr_addr_dec (
            .in(wr_addr[i]),
            .out(wr_addr_onehot[i])
        );
    end

    // gate the write enable signal(s) with the one-hot address(es) to generate the precursor we signal(s) corresponding to each write port
    wire [N_ENTRIES-1:0] [N_WRITE_PORTS-1:0] we_pre;
    for (genvar i = 0; i < N_WRITE_PORTS; i++) begin
        for (genvar j = 0; j < N_ENTRIES; j++) begin
            and_ #(.N_INS(2)) we_pre_and (
                .a({wr_en[i], wr_addr_onehot[i][j]}),
                .y(we_pre[j][i])
            );
        end
    end

    // combine the precursor we signals to generate the final we signal for each entry
    wire [N_ENTRIES-1:0] we;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        or_ #(.N_INS(N_WRITE_PORTS)) we_or (
            .a(we_pre[i]),
            .y(we[i])
        );
    end

    // ff1 to generate a one-hot select signal for the din mux of each entry (prioritize less significant write ports, e.g., 0 > 1 > 2 > ...)
    wire [N_ENTRIES-1:0] [N_WRITE_PORTS-1:0] din_onehot_mux_sel;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        ff1 #(.WIDTH(N_WRITE_PORTS)) din_onehot_mux_sel_ff1 (
            .a(we_pre[i]),
            .y(din_onehot_mux_sel[i])
        );
    end

    // select the din of each entry based on the one-hot select signal
    wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] din;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        onehot_mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_WRITE_PORTS)) din_onehot_mux (
            .ins(wr_data),
            .sel(din_onehot_mux_sel[i]),
            .out(din[i])
        );
    end

    // the register file entries
    wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        reg_ #(.WIDTH(ENTRY_WIDTH)) entry_reg ( // NOTE: STATEFUL
            .clk(clk),
            .rst_aL(rst_aL),
            .we(we[i]),
            .din(din[i]),
            .dout(entry_douts[i])
        );
    end

    // select the read data
    for (genvar i = 0; i < N_READ_PORTS; i++) begin
        mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_ENTRIES)) rd_data_mux (
            .ins(entry_douts),
            .sel(rd_addr[i]),
            .out(rd_data[i])
        );
    end

    // assertions
    // check that all write ports are to different addresses
    for (genvar i = 0; i < N_WRITE_PORTS; i++) begin
        for (genvar j = i + 1; j < N_WRITE_PORTS; j++) begin
            assert property (@(posedge clk) disable iff (!rst_aL) wr_en[i] && wr_en[j] |-> wr_addr[i] != wr_addr[j]);
        end
    end
endmodule

`endif
