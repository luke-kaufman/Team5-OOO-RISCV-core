`include "misc/global_defs.svh"
`include "freepdk-45nm/stdcells.v"
`include "misc/regfile.v"
`include "misc/fifo.v"
`include "misc/fifo_ram.v"

module integer_issue (
    input wire clk,
    input wire rst_aL,
    // INTERFACE TO DISPATCH
    output wire dispatch_ready,
    input wire dispatch_valid,
    input wire iiq_entry_t dispatch_data,
    // INTERFACE TO EXECUTE
    output wire issue_valid,
    output wire [ISSUE_DATA_WIDTH-1:0] issue_data
);
    // internal signals
    // wakeup feedback: (wakeup_valid, wakeup_tag/index, wakeup_data)
    wire wakeup_valid;

    shift_queue iiq #(
        .N_ENTRIES(`IIQ_N_ENTRIES),
        .ENTRY_WIDTH(`IIQ_ENTRY_WIDTH)
    ) (
        .clk(clk),
        .rst_aL(rst_aL),
        .enq_ready(dispatch_ready),
        .enq_valid(dispatch_valid),
    );

    
endmodule