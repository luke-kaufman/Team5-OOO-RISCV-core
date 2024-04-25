module lsq_simple #(
    parameter type ENTRY_T,
    parameter int unsigned N_ENTRIES,
    localparam int unsigned PTR_WIDTH = $clog2(N_ENTRIES),
    localparam int unsigned CTR_WIDTH = PTR_WIDTH + 1
) (
    input logic clk,
    input logic rst_aL,
    input logic flush,

    output logic enq_ready,
    input logic enq_valid,
    input ENTRY_T enq_data,

    input logic deq_valid,
    output ENTRY_T deq_data,

    input logic [N_ENTRIES-1:0] wr_en,
    input ENTRY_T [N_ENTRIES-1:0] wr_data,

    output ENTRY_T [N_ENTRIES-1:0] entries,
    output logic [CTR_WIDTH-1:0] enq_ctr_out,

    // for testing
    input logic init,
    input ENTRY_T [N_ENTRIES-1:0] init_entries,
    input logic [CTR_WIDTH-1:0] init_enq_ctr,
    input logic [CTR_WIDTH-1:0] init_deq_ctr
);
    ENTRY_T [N_ENTRIES-1:0] lsq_entries;
    logic [CTR_WIDTH-1:0] enq_ctr;
    logic [CTR_WIDTH-1:0] deq_ctr;

    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] deq_ptr = deq_ctr[PTR_WIDTH-1:0];
    wire fifo_empty = enq_ctr == deq_ctr;
    wire fifo_full = (enq_ctr[PTR_WIDTH] != deq_ctr[PTR_WIDTH]) && (enq_ctr[PTR_WIDTH-1:0] == deq_ctr[PTR_WIDTH-1:0]);

    assign enq_ready = ~fifo_full;
    assign deq_data = lsq_entries[deq_ptr];
    assign entries = lsq_entries;
    assign enq_ctr_out = enq_ctr;

    // FIXME: breaking dispatch_ready for IFU->Dispatch because x
    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init) begin
            lsq_entries <= init_entries;
            enq_ctr <= init_enq_ctr;
            deq_ctr <= init_deq_ctr;
        end else if (!rst_aL | flush) begin
            lsq_entries <= '0;
            enq_ctr <= '0;
            deq_ctr <= '0;
        end else begin
            if (enq_valid && enq_ready) begin
                lsq_entries[enq_ptr] <= enq_data;
            end
            for (int i = 0; i < N_ENTRIES; i++) begin
                if (wr_en[i]) begin
                    lsq_entries[i] <= wr_data[i];
                end
            end
            if (enq_valid && enq_ready) begin
                enq_ctr <= enq_ctr + 1;
            end
            if (deq_valid) begin
                deq_ctr <= deq_ctr + 1;
            end
        end
    end
endmodule