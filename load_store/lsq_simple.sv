module lsq_simple #(
    parameter int unsigned N_ENTRIES,
    parameter type ENTRY_T
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

    // for testing
    input logic init,
    input ENTRY_T [N_ENTRIES-1:0] init_entries
);
    ENTRY_T [N_ENTRIES-1:0] lsq_entries;

    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (init) begin
            lsq_entries <= init_entries;
        end else if (!rst_aL | flush) begin
            lsq_entries <= '{default: 0};
        end else begin
            for (int i = 0; i < N_ENTRIES; i++) begin
                if (wr_en[i]) begin
                    lsq_entries[i] <= wr_data[i];
                end
            end
        end
    end
endmodule