`ifndef CORE_V
`define CORE_V

`include "misc/global_defs.svh"
`include "frontend/fetch/ifu.v"
`include "frontend/dispatch/dispatch.sv"

module core #() (
    input wire clk,
    input wire rst_aL,
    input wire csb0_in,  // testing icache on
    
    // ICACHE TO MEM CTRL
    input logic icache_req_valid,
    input main_mem_block_addr_t icache_req_block_addr,
    output logic icache_req_ready,
    // FROM MEM_CTRL TO ICACHE (RESPONSE) (LATENCY-SENSITIVE)
    output logic icache_resp_valid,
    output block_data_t icache_resp_block_data,
    
    // DCACHE TO MEM CTRL
    output logic dcache_req_valid,
    output req_type_t dcache_req_type, // 0: read, 1: write
    output main_mem_block_addr_t dcache_req_block_addr,
    output block_data_t dcache_req_block_data, // for writes
    // DCACHE FROM MEM CTRL
    input logic dcache_req_ready,
    input logic dcache_resp_valid,
    input block_data_t dcache_resp_block_data,
    
    // ARF out - for checking archiectural state
    output wire [ARF_N_ENTRIES-1:0][REG_DATA_WIDTH-1:0] ARF_OUT
);
    // IFU <-> DISPATCH
    wire               ififo_dispatch_ready;  /*DIS->IFU*/
    wire               ififo_dispatch_valid;  /*IFU->DIS*/
    wire ififo_entry_t ififo_dispatch_data;   /*IFU->DIS*/

    // DISPATCH <-> IIQ
    wire             iiq_dispatch_ready;
    wire             iiq_dispatch_valid;
    wire iiq_entry_t iiq_dispatch_data;
    // DISPATCH <- IIQ

    // DISPATCH <-> LSQ
    wire             lsq_dispatch_ready;
    wire             lsq_dispatch_valid;
    wire lsq_entry_t lsq_dispatch_data;
    // DISPATCH <-> ST_BUF
    wire                st_buf_dispatch_ready;
    wire                st_buf_dispatch_valid;
    wire st_buf_entry_t st_buf_dispatch_data;
    wire st_buf_id_t    st_buf_dispatch_id;
    // DISPATCH <- ALU
    wire            alu_broadcast_valid;
    wire rob_id_t   alu_broadcast_rob_id;
    wire reg_data_t alu_broadcast_reg_data;
    wire            alu_br_mispred;
    wire            fetch_redirect_valid;
    wire addr_t     fetch_redirect_pc;

    // DISPATCH <- LSU
    wire            ld_broadcast_valid;
    wire rob_id_t   ld_broadcast_rob_id;
    wire reg_data_t ld_broadcast_reg_data;
    wire            ld_mispred;

    // IIQ -> ALU and wakeup to dispatch
    wire iiq_issue_data_t iiq_issue_data;
    wire                  iiq_issue_valid;  // ALSO TO DISPATCH wakeup from IIQ
    wire rob_id_t         iiq_issue_rob_id; // ALSO TO DISPATCH wakeup from IIQ
    wire iiq_entry_t      iiq_issue_data


    // INSTRUCTION FETCH UNIT (IFU)
    ifu ifu_dut (
        // from top.sv
        .clk(clk),
        .rst_aL(rst_aL),
        .csb0_in(csb0_in),
        // backend interactions - TODO FIX DUPLICATION
        .flush(fetch_redirect_valid),
        .recovery_PC(fetch_redirect_pc),
        .recovery_PC_valid(fetch_redirect_valid),
        .backend_stall(fetch_redirect_valid),
        // main memory interactions
        .recv_main_mem_data(recv_main_mem_data),
        .recv_main_mem_valid(recv_main_mem_valid),
        .recv_main_mem_addr(recv_main_mem_addr),
        // IFU <-> DISPATCH
        .ififo_dispatch_ready(ififo_dispatch_ready),  // input
        .ififo_dispatch_valid(ififo_dispatch_valid),  // output
        .ififo_dispatch_data(ififo_dispatch_data)     // output
    );

    // DISPATCH (DECODE, RENAME, ROB here)
    dispatch dispatch_dut (
        .clk(clk),       /*input*/
        .rst_aL(rst_aL), /*input*/
        // INTERFACE TO INSRUCTION FIFO (IFIFO)
        .ififo_dispatch_ready(ififo_dispatch_ready),  // output
        .ififo_dispatch_valid(ififo_dispatch_valid),  // input
        .ififo_dispatch_data(ififo_dispatch_data),  // input
        // INTERFACE TO INTEGER ISSUE QUEUE (IIQ)
        .iiq_dispatch_ready(iiq_dispatch_ready),  /*input*/
        .iiq_dispatch_valid(iiq_dispatch_valid),  /*output*/
        .iiq_dispatch_data(iiq_dispatch_data),   /*output*/
        // integer wakeup (from IIQ)
        .iiq_wakeup_valid(iiq_issue_valid),   /*input*/
        .iiq_wakeup_rob_id(iiq_issue_rob_id),  /*input*/
        // INTERFACE TO LOAD-STORE QUEUE (LSQ)
        .lsq_dispatch_ready(lsq_dispatch_ready),  /*input*/
        .lsq_dispatch_valid(lsq_dispatch_valid),  /*output*/
        .lsq_dispatch_data(lsq_dispatch_data),   /*output*/
        // INTERFACE TO STORE BUFFER (ST_BUF)
        .st_buf_dispatch_ready(st_buf_dispatch_ready),  /*input*/
        .st_buf_dispatch_valid(st_buf_dispatch_valid),  /*output*/
        .st_buf_dispatch_data(st_buf_dispatch_data),   /*output*/
        .st_buf_dispatch_id(st_buf_dispatch_id),     /*input*/
        // INTERFACE TO ARITHMETIC-LOGIC UNIT (ALU)
        .alu_broadcast_valid(alu_broadcast_valid),     /*input*/
        .alu_broadcast_rob_id(alu_broadcast_rob_id),    /*input*/
        .alu_broadcast_reg_data(alu_broadcast_reg_data),  /*input*/
        .alu_br_mispred(alu_br_mispred),          /*input*/
        // INTERFACE TO LOAD-STORE UNIT (LSU)
        .ld_broadcast_valid(ld_broadcast_valid),     /*input*/
        .ld_broadcast_rob_id(ld_broadcast_rob_id),    /*input*/
        .ld_broadcast_reg_data(ld_broadcast_reg_data),  /*input*/
        .ld_mispred(ld_mispred)              /*input*/
    );

    // INTEGER ISSUE QUEUE (IIQ)
    integer_issue integer_issue_dut (
        .clk(clk),        /*input*/
        .rst_aL(rst_aL),  /*input*/
        .flush(fetch_redirect_valid),
        // dispatch interface: ready & valid
        .dispatch_ready(iiq_dispatch_ready),  /*output*/
        .dispatch_valid(iiq_dispatch_valid),  /*input*/
        .dispatch_data(iiq_dispatch_data),   /*input*/
        // issue interface: always ready (all integer instructions take 1 cycle to execute)
        .issue_valid(iiq_issue_valid),  /*output*/
        .issue_rob_id(iiq_issue_rob_id)  /*output*/
        .issue_data(iiq_issue_data),   /*output*/
        // alu broadcast:
        .alu_broadcast_valid(alu_broadcast_valid),     /*input*/
        .alu_broadcast_rob_id(alu_broadcast_rob_id),    /*input*/
        .alu_broadcast_reg_data(alu_broadcast_reg_data),  /*input*/
        // load broadcast:
        .ld_broadcast_valid(ld_broadcast_valid),    /*input*/
        .ld_broadcast_rob_id(ld_broadcast_rob_id),   /*input*/
        .ld_broadcast_reg_data(ld_broadcast_reg_data)  /*input*/
    );

    // ARITHMETIC-LOGIC UNIT (ALU) (i.e. integer execute)
    integer_execute integer_execute_dut (
        .iiq_issue_data(iiq_issue_data),         /*input*/
        .instr_rob_id_out(alu_broadcast_rob_id), /*output*/ // sent to bypass paths  iiq for capture  used for indexing into rob for writeback
        .dst_valid(alu_broadcast_valid),         /*output*/ // to guard broadcast (iiq and lsq) and bypass (dispatch and issue) capture
        .dst(alu_broadcast_reg_data),            /*output*/
        .br_wb_valid(fetch_redirect_valid),      /*output*/ // change pc to npc in rob only if instr is b_type or jalr
        .npc(fetch_redirect_pc),                 /*output*/ // next pc to be written back to rob.pc_npc (b_type or jalr)
        .br_mispred(alu_br_mispred)              /*output*/ // to be written back to rob.br_mispred (0: no misprediction  1: misprediction)
    );

    // DUMB LSU
    load_store_simple lsu (
        .clk(clk), /*input*/
        .rst_aL(rst_aL), /*input*/
        .csb0_in(csb0_in), /*input*/
        .flush(fetch_redirect_valid), /*input*/
        // TO MEM CTRL - outputs
        .dcache_req_valid(),
        .dcache_req_type(), // 0: read 1: write
        .dcache_req_block_addr(),
        .dcache_req_block_data(), // for writes
        // FROM MEM CTRL - inputs
        .dcache_req_ready(),
        .dcache_resp_valid(),
        .dcache_resp_block_data(),
        // dispatch interface: ready & valid
        .dispatch_ready(iiq_dispatch_ready),  /*output*/
        .dispatch_valid(iiq_dispatch_valid),  /*input*/
        .dispatch_data(iiq_dispatch_data),   /*input*/
        // alu broadcast:
        .alu_broadcast_valid(alu_broadcast_valid),     /*input*/
        .alu_broadcast_rob_id(alu_broadcast_rob_id),    /*input*/
        .alu_broadcast_reg_data(alu_broadcast_reg_data),  /*input*/
        // load broadcast:
        .ld_broadcast_valid(ld_broadcast_valid),    /*output*/
        .ld_broadcast_rob_id(ld_broadcast_rob_id),   /*output*/
        .ld_broadcast_reg_data(ld_broadcast_reg_data)  /*output*/
    );

    // LOAD STORE QUEUE (LSQ)
    // LOAD STORE EXECUTE (D-cache?)

endmodule
`endif CORE_V