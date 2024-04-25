`ifndef CORE_V
`define CORE_V

`include "misc/global_defs.svh"
`include "frontend/fetch/ifu.sv"
`include "frontend/dispatch/dispatch_simple.sv"
`include "integer/integer_issue.sv"
`include "integer/integer_execute.sv"
`include "load_store/load_store_simple.sv"

module core #(parameter VERBOSE = 0) (
    input wire clk,
    input wire init,
    input addr_t init_pc,
    input addr_t init_sp,
    input wire rst_aL,

    // ICACHE MEM CTRL REQUEST
    output logic icache_mem_ctrl_req_valid,
    output main_mem_block_addr_t icache_mem_ctrl_req_block_addr,
    input logic icache_mem_ctrl_req_ready,

    // ICACHE MEM CTRL RESPONSE
    input logic icache_mem_ctrl_resp_valid,
    input block_data_t icache_mem_ctrl_resp_block_data,

    // DCACHE MEM CTRL REQUEST
    output logic dcache_mem_ctrl_req_valid,
    output req_type_t dcache_mem_ctrl_req_type, // 0: read, 1: write
    output main_mem_block_addr_t dcache_mem_ctrl_req_block_addr,
    output block_data_t dcache_mem_ctrl_req_block_data, // for writes
    input logic dcache_mem_ctrl_req_ready,

    // DCACHE MEM CTRL RESPONSE
    input logic dcache_mem_ctrl_resp_valid,
    input block_data_t dcache_mem_ctrl_resp_block_data,

    // ARF out - for checking archiectural state
    output logic [`ARF_N_ENTRIES-1:0][`REG_DATA_WIDTH-1:0] ARF_OUT
);
    // IFU <-> DISPATCH
    wire               ififo_dispatch_ready;  /*DIS->IFU*/
    wire               ififo_dispatch_valid;  /*IFU->DIS*/
    ififo_entry_t      ififo_dispatch_data;   /*IFU->DIS*/
    wire               fetch_redirect_valid;
    addr_t             fetch_redirect_pc;

    // DISPATCH <-> IIQ
    wire             iiq_dispatch_ready;
    wire             iiq_dispatch_valid;
    iiq_entry_t      iiq_dispatch_data;
    // DISPATCH <- IIQ

    // DISPATCH <-> LSQ
    wire             lsq_dispatch_ready;
    wire             lsq_dispatch_valid;
    lsq_simple_entry_t      lsq_dispatch_data;
    // DISPATCH <-> ST_BUF
    wire                st_buf_dispatch_ready;
    wire                st_buf_dispatch_valid;
    st_buf_entry_t st_buf_dispatch_data;
    st_buf_id_t    st_buf_dispatch_id;
    // DISPATCH <- ALU
    wire            alu_broadcast_valid;
    wire       execute_valid;
    rob_id_t   alu_broadcast_rob_id;
    reg_data_t alu_broadcast_reg_data;
    wire       alu_npc_wb_valid; // only true when instr is b_type or jalr
    wire       alu_npc_mispred; // always true for jalr, only true for b_type when actual mispredict
    addr_t     alu_npc;
    wire            alu_br_mispred;


    // DISPATCH <- LSU
    wire            ld_broadcast_valid;
    rob_id_t   ld_broadcast_rob_id;
    reg_data_t ld_broadcast_reg_data;
    wire            ld_mispred;

    // IIQ -> ALU and wakeup to dispatch
    iiq_issue_data_t iiq_issue_data;
    wire                  iiq_issue_valid;  // ALSO TO DISPATCH wakeup from IIQ
    rob_id_t         iiq_issue_rob_id; // ALSO TO DISPATCH wakeup from IIQ

    // INSTRUCTION FETCH UNIT (IFU)
    ifu _ifu (
        // from top.sv
        .clk(clk),
        .init(init),
        .init_pc(init_pc),
        .rst_aL(rst_aL),
        // backend interactions
        .fetch_redirect_valid(fetch_redirect_valid),
        .fetch_redirect_PC(fetch_redirect_pc),
        // .backend_stall(),  // OR with other stuff?
        // ICACHE MEM CTRL REQUEST
        .mem_ctrl_req_valid(icache_mem_ctrl_req_valid),            /*output logic*/
        .mem_ctrl_req_block_addr(icache_mem_ctrl_req_block_addr),  /*output main_mem_block_addr_t*/
        .mem_ctrl_req_ready(icache_mem_ctrl_req_ready),            /*input logic*/
        // ICACHE MEM CTRL RESPONSE
        .mem_ctrl_resp_valid(icache_mem_ctrl_resp_valid),            /*input logic*/
        .mem_ctrl_resp_block_data(icache_mem_ctrl_resp_block_data),  /*input block_data_t*/
        // IFU <-> DISPATCH
        .ififo_dispatch_ready(ififo_dispatch_ready),  // input
        .ififo_dispatch_valid(ififo_dispatch_valid),  // output
        .ififo_dispatch_data(ififo_dispatch_data)     // output
    );

    // DISPATCH (DECODE, RENAME, ROB here)
    dispatch_simple _dispatch (
        .clk(clk),       /*input*/
        .init(init),
        .init_sp(init_sp),
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
        // // INTERFACE TO STORE BUFFER (ST_BUF)
        // .st_buf_dispatch_ready(st_buf_dispatch_ready),  /*input*/
        // .st_buf_dispatch_valid(st_buf_dispatch_valid),  /*output*/
        // .st_buf_dispatch_data(st_buf_dispatch_data),   /*output*/
        // .st_buf_dispatch_id(st_buf_dispatch_id),     /*input*/
        // INTERFACE TO ARITHMETIC-LOGIC UNIT (ALU)
        .execute_valid(execute_valid),
        .alu_broadcast_valid(alu_broadcast_valid),     /*input*/
        .alu_broadcast_rob_id(alu_broadcast_rob_id),    /*input*/
        .alu_broadcast_reg_data(alu_broadcast_reg_data),  /*input*/
        .alu_npc_wb_valid(alu_npc_wb_valid),  /*input*/ // only true when instr is b_type or jalr
        .alu_npc_mispred(alu_npc_mispred),  /*input*/ // always true for jalr, only true for b_type when actual mispredict
        .alu_npc(alu_npc),                  /*input*/
        // INTERFACE TO LOAD-STORE UNIT (LSU)
        .ld_broadcast_valid(ld_broadcast_valid),     /*input*/
        .ld_broadcast_rob_id(ld_broadcast_rob_id),    /*input*/
        .ld_broadcast_reg_data(ld_broadcast_reg_data),  /*input*/
        // .ld_mispred(ld_mispred)              /*input*/
        // INTERFACE TO FETCH
        .fetch_redirect_valid(fetch_redirect_valid), /*output wire*/
        .fetch_redirect_pc(fetch_redirect_pc), /*output wire addr_t*/

        .ARF_OUT(ARF_OUT)
    );

    // INTEGER ISSUE QUEUE (IIQ)
    integer_issue _integer_issue (
        .clk(clk),        /*input*/
        .init(init),
        .rst_aL(rst_aL),  /*input*/
        .fetch_redirect_valid(fetch_redirect_valid),
        // dispatch interface: ready & valid
        .dispatch_ready(iiq_dispatch_ready),  /*output*/
        .dispatch_valid(iiq_dispatch_valid),  /*input*/
        .dispatch_data(iiq_dispatch_data),   /*input*/
        // issue interface: always ready (all integer instructions take 1 cycle to execute)
        .issue_valid(iiq_issue_valid),  /*output*/
        .issue_rob_id(iiq_issue_rob_id),  /*output*/
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
    integer_execute _integer_execute (
        .clk(clk),
        .rst_aL(rst_aL),

        .iiq_issue_data(iiq_issue_data),         /*input*/
        .instr_rob_id_out(alu_broadcast_rob_id), /*output*/ // sent to bypass paths  iiq for capture  used for indexing into rob for writeback
        .execute_valid(execute_valid),     /*output*/ // to guard broadcast (iiq and lsq) and bypass (dispatch and issue) capture
        .alu_broadcast_valid(alu_broadcast_valid), // output
        .dst(alu_broadcast_reg_data),            /*output*/
        .npc_wb_valid(alu_npc_wb_valid),         /*output*/ // change pc to npc in rob only if instr is b_type or jalr
        .npc_mispred(alu_npc_mispred),           /*output*/ // to be written back to rob.br_mispred (0:no misprediction 1: misprediction)
        .npc(alu_npc)                            /*output*/ // next pc to be written back to rob.pc_npc (b_type or jalr)
    );

    // DUMB LSU
    load_store_simple #(.VERBOSE(VERBOSE)) lsu (
        .clk(clk), /*input*/
        .rst_aL(rst_aL), /*input*/
        .flush(fetch_redirect_valid), /*input*/
        // DCACHE MEM CTRL REQUEST
        .mem_ctrl_req_valid(dcache_mem_ctrl_req_valid), // output logic
        .mem_ctrl_req_type(dcache_mem_ctrl_req_type), // output req_type_t  // 0: read 1: write
        .mem_ctrl_req_block_addr(dcache_mem_ctrl_req_block_addr), // output main_mem_block_addr_t
        .mem_ctrl_req_block_data(dcache_mem_ctrl_req_block_data), // output block_data_t  // for writes
        // DCACHE MEM CTRL RESPONSE
        .mem_ctrl_req_ready(dcache_mem_ctrl_req_ready), // input logic
        .mem_ctrl_resp_valid(dcache_mem_ctrl_resp_valid), // input logic
        .mem_ctrl_resp_block_data(dcache_mem_ctrl_resp_block_data), // input block_data_t
        // dispatch interface: ready & valid
        .dispatch_ready(lsq_dispatch_ready),  /*output*/
        .dispatch_valid(lsq_dispatch_valid),  /*input*/
        .dispatch_data(lsq_dispatch_data),   /*input*/
        // IIQ wakeup
        .iiq_wakeup_valid(iiq_issue_valid),  // input
        .iiq_wakeup_rob_id(iiq_issue_rob_id),  // input
        // alu broadcast:
        .alu_broadcast_valid(alu_broadcast_valid),     /*input*/
        .alu_broadcast_rob_id(alu_broadcast_rob_id),    /*input*/
        .alu_broadcast_reg_data(alu_broadcast_reg_data),  /*input*/
        // // load broadcast:
        .lsu_broadcast_valid(ld_broadcast_valid),    /*output*/
        .lsu_broadcast_rob_id(ld_broadcast_rob_id),   /*output*/
        .lsu_broadcast_reg_data(ld_broadcast_reg_data),  /*output*/

        .init(init),
        .init_entries('0)
    );

    // LOAD STORE QUEUE (LSQ)
    // LOAD STORE EXECUTE (D-cache?)

endmodule
`endif
