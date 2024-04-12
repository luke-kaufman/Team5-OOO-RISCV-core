`ifndef REGFILE_GOLDEN_V
`define REGFILE_GOLDEN_V

`include "misc/global_defs.svh"
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
    parameter N_WRITE_PORTS = 2
) (
    input wire clk,
    input wire rst_aL,

    input wire [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr,
    output wire [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data,

    input wire [N_WRITE_PORTS-1:0] wr_en,
    input wire [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr,
    input wire [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data,

    // for testing
    input wire init,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_regfile_state,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] current_regfile_state
);
    // state elements
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] regfile_r;

    // next state signals
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] regfile_next;

    // output drivers
    for (genvar i = 0; i < N_READ_PORTS; i++) begin
        assign rd_data[i] = regfile_r[rd_addr[i]];
    end

    // next state logic with dynamic slicing
    always_comb begin
        regfile_next = regfile_r;
        for (int i = 0; i < N_WRITE_PORTS; i++) begin
            if (wr_en[i]) begin
                regfile_next[wr_addr[i]] = wr_data[i];
            end
        end
    end

    // state update
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init) begin
            regfile_r <= init_regfile_state;
        end else if (!rst_aL) begin
            regfile_r <= 0;
        end else begin
            regfile_r <= regfile_next;
        end
    end

    // for testing
    assign current_regfile_state = regfile_r;

    // assertions
    function void assert_diff_write_addrs(edge_t _edge);
        for (int i = 0; i < N_WRITE_PORTS; i++) begin
            for (int j = i+1; j < N_WRITE_PORTS; j++) begin
                if ((wr_en[i] && wr_en[j]) && (wr_addr[i] == wr_addr[j])) begin
                    $error(
                        "Assertion failed: write addresses from different ports are the same after %0s.\n\
                        wr_addr[%0d] = %0d, wr_addr[%0d] = %0d\n",
                        _edge == NEGEDGE ? "setting init_state and driving inputs" : "state transition",
                        i, wr_addr[i], j, wr_addr[j]
                    );
                end
            end
        end
    endfunction

    always @(negedge clk) begin #1
        assert_diff_write_addrs(NEGEDGE);
    end
    always @(posedge clk) begin #1
        assert_diff_write_addrs(POSEDGE);
    end

    // for (genvar i = 0; i < N_WRITE_PORTS; i++) begin
    //     for (genvar j = i + 1; j < N_WRITE_PORTS; j++) begin
    //         assert property (@(posedge clk) disable iff (!rst_aL) wr_en[i] && wr_en[j] |-> wr_addr[i] != wr_addr[j]);
    //     end
    // end
endmodule

`endif
