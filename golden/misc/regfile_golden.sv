`ifndef REGFILE_GOLDEN_V
`define REGFILE_GOLDEN_V

`include "misc/dec/dec_.v"
`include "misc/and/and_.v"
`include "misc/ff1/ff1.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module regfile_golden #(
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
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] regfile_r;



    // assertions
    // check that all write ports are to different addresses
    for (genvar i = 0; i < N_WRITE_PORTS; i++) begin
        for (genvar j = i + 1; j < N_WRITE_PORTS; j++) begin
            assert property (@(posedge clk) disable iff (!rst_aL) wr_en[i] && wr_en[j] |-> wr_addr[i] != wr_addr[j]);
        end
    end
endmodule

`endif
