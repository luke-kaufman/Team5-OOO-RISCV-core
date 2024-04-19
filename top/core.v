`ifndef CORE_V
`define CORE_V

`include "misc/global_defs.svh"
`include "frontend/fetch/ifu.v"
`include "frontend/dispatch/dispatch.sv"

module core #() (
    input wire clk,
    input wire rst_aL,
    input wire csb0_in,  // testing icache on
    // Main memory interaction for both LOADS and ICACHE (rd only)
    input wire                               recv_main_mem_valid,
    input wire                               recv_main_mem_lsu_aL_ifu_aH,  // if main mem data is meant for LSU or IFU
    input wire [`ADDR_WIDTH-1:0]             recv_main_mem_addr,
    input wire [2:0]                         recv_size_main_mem, // {Word, Halfword, Byte}
    input wire [`ICACHE_DATA_BLOCK_SIZE-1:0] recv_main_mem_data,
    // Main memory interaction only for STORES (wr only)
    output wire                   send_en_main_mem,
    output wire [`ADDR_WIDTH-1:0] send_main_mem_addr,
    output wire [2:0]             send_size_main_mem, // {Word, Halfword, Byte}
    output wire [`WORD_WIDTH-1:0] send_main_mem_data, // write up to a word
    // ARF out - for checking archiectural state
    output wire [ARF_N_ENTRIES-1:0][REG_DATA_WIDTH-1:0] ARF_OUT
);  
    // Inter-Stage connects
    wire [`ADDR_WIDTH-1:0] recovery_PC;/*ALU->IFU*/
    wire                   recovery_PC_valid;/*ALU->IFU*/ // a.k.a. branch prediction valid
    wire                   backend_stall; //? ambiguous - could be from any stage (IIQ full, LSQ full, etc.)
    
    // IFU <-> DISPATCH 
    wire                          ififo_dispatch_ready;  /*DIS->IFU*/
    wire                          ififo_dispatch_valid;  /*IFU->DIS*/
    wire [`IFIFO_ENTRY_WIDTH-1:0] ififo_dispatch_data;   /*IFU->DIS*/

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

    // ALU 

    // INSTRUCTION FETCH UNIT (IFU)
    
    // 
    mux_ #(
        .WIDTH(`ADDR_WIDTH),
        .N_INS(2)
    ) recovery_PC_mux ( 
        .ins({recv_main_mem_addr, PC_mux_local_out}),
        .sel(br_mispred),
        .out(PC_mux_out)
    );
    ifu ifu_dut (
        // from top.sv
        .clk(clk),
        .rst_aL(rst_aL),
        .csb0_in(csb0_in)
        // backend interactions
        .recovery_PC(recovery_PC),
        .recovery_PC_valid(recovery_PC_valid),
        .backend_stall(backend_stall),
        // main memory interactions
        .recv_main_mem_data(recv_main_mem_data),
        .recv_main_mem_valid(recv_main_mem_valid),
        .recv_main_mem_addr(recv_main_mem_addr)
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
        .iiq_issue_data(iiq_issue_data),    /*input*/
        .instr_rob_id_out(alu_broadcast_rob_id),  /*output*/ // sent to bypass paths  iiq for capture  used for indexing into rob for writeback
        .dst_valid(),         /*output*/ // to guard broadcast (iiq and lsq) and bypass (dispatch and issue) capture
        .dst(),               /*output*/
        .br_wb_valid(),       /*output*/ // change pc to npc in rob only if instr is b_type or jalr
        .npc(),               /*output*/ // next pc to be written back to rob.pc_npc (b_type or jalr)
        .br_mispred(alu_br_mispred)         /*output*/ // to be written back to rob.br_mispred (0: no misprediction  1: misprediction)
    );
    
    // LOAD STORE QUEUE (LSQ)

    // LOAD STORE EXECUTE (D-cache?)
    
endmodule
`endif CORE_V