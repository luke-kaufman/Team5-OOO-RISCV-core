`include "issue/integer_issue.sv"
// `include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"

module integer_issue_tb();
    reg clk, rst_aL;
    // INTERFACE TO DISPATCH
    wire dispatch_ready;
    reg dispatch_valid;
    reg iiq_entry_t dispatch_data;
    // INTERFACE TO EXECUTE
    wire issue_valid;
    wire [ISSUE_DATA_WIDTH-1:0] issue_data;
    integer_issue dut(clk, rst_aL, dispatch_ready, dispatch_valid, dispatch_data, issue_valid, issue_data);

endmodule