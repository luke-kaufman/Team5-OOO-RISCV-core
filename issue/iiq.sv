`ifndef IIQ_SV
`define IIQ_SV

`include "misc/global_defs.svh"
`include "freepdk-45nm/stdcells.v"
`include "misc/regfile.v"
`include "misc/fifo.v"
`include "misc/fifo_ram.v"

module iiq #(

) (
    input wire clk,
    input wire rst_aL,

    // dispatch interface: ready & valid
    output wire dispatch_ready,
    input wire dispatch_valid,
    input wire iiq_entry_t dispatch_data,

    // issue interface: always ready (all integer instructions take 1 cycle to execute)
    output wire issue_valid,
    output wire iiq_entry_t issue_data

    // wakeup interface:
    // integer (instruction) target wakeup:
    input wire int_wakeup_valid,
    input wire rob_id_t int_wakeup_rob_id,

    // load-store (instruction) target wakeup:
    input wire ls_wakeup_valid,
    input wire rob_id_t ls_wakeup_rob_id
);
    shift_queue #(
        .N_ENTRIES(`IIQ_N_ENTRIES),
        .ENTRY_WIDTH(`IIQ_ENTRY_WIDTH)
    ) iiq_mem (
        .clk(clk),
        .rst_aL(rst_aL),
        
        .enq_ready(),
        .enq_valid(),
        .enq_data(),
        
        .deq_ready(),
        .deq_sel_onehot(),
        .deq_valid(),
        .deq_data(),
        
        .wr_en(),
        .wr_data(),
        .entry_douts()
    )
endmodule

`endif
