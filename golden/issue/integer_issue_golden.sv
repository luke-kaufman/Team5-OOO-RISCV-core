`include "misc/global_defs.svh"
// `include "freepdk-45nm/stdcells.v"
`include "misc/regfile.v"
`include "misc/fifo.v"
`include "misc/fifo_ram.v"

/*
    - Integer Issue Unit consists of a shift queue and a wakeup feedback mechanism.

*/

module integer_issue_golden (
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
    // state elements
