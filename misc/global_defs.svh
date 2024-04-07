`ifndef GLOBAL_DEFS_V
`define GLOBAL_DEFS_V

// use defines if these values are needed across multiple modules
// just use parameters otherwise
// can have parameters that are the same as these defines but 
// do use these global defines to initalize those parameters

`define ADDR_WIDTH 32 // the width of a physical/virtual address (no virtual memory support yet)
`define INSTR_WIDTH 32

`define ICACHE_NUM_SETS 64
`define ICACHE_TAG_ENTRY_SIZE 24
`define ICACHE_DATA_BLOCK_SIZE 64
`define ICACHE_NUM_WAYS 2
`define ICACHE_NUM_TAG_CTRL_BITS 1
`define ICACHE_WRITE_SIZE_BITS 64

`define DCACHE_NUM_SETS 64
`define DCACHE_TAG_ENTRY_SIZE 25
`define DCACHE_DATA_BLOCK_SIZE 64
`define DCACHE_NUM_WAYS 2
`define DCACHE_NUM_TAG_CTRL_BITS 2  // dirty and valid
`define DCACHE_WRITE_SIZE_BITS 8

`define REG_DATA_WIDTH 32 // the width of data that is held in a retired (ARF) register or speculative (ROB) register
`define ARF_N_ENTRIES 32
`define ARF_ID_WIDTH $clog2(`ARF_N_ENTRIES)
`define ROB_N_ENTRIES 16
`define ROB_ID_WIDTH $clog2(`ROB_N_ENTRIES)
`define IIQ_N_ENTRIES 16
`define IIQ_ID_WIDTH $clog2(`IIQ_N_ENTRIES)

typedef logic [`REG_DATA_WIDTH-1:0] reg_data_t;
typedef logic [`ARF_ID_WIDTH-1:0] arf_id_t;
typedef logic [`ROB_ID_WIDTH-1:0] rob_id_t;

// `define IFIFO_ENTRY_WIDTH = (`INSTR_WIDTH + `ADDR_WIDTH + 1 + 1 + `ADDR_WIDTH) 
typedef struct packed {
    logic [`INSTR_WIDTH-1:0] instr;
    logic [`ADDR_WIDTH-1:0] pc;
    logic is_cond_br;
    logic br_dir_pred;
    logic [`ADDR_WIDTH-1:0] br_target_pred;
} ififo_entry_t;
`define IFIFO_ENTRY_WIDTH $bits(ififo_entry_t)
/*instruction*/ 
/*PC*/
/*branch info valid bit*/
/*Prediction bit - 1 taken, 0 not taken*/
/*TARGET PC*/

typedef struct packed {
    logic dst_valid;
    arf_id_t dst_arf_id;
    logic [`ADDR_WIDTH-1:0] pc;
    logic ld_mispredict;
    logic br_mispredict;
    logic reg_ready;
    reg_data_t reg_data;
} rob_entry_t;
`define ROB_ENTRY_WIDTH $bits(rob_entry_t)

typedef struct packed {
    logic dst_valid;
    arf_id_t dst_arf_id;
    logic [`ADDR_WIDTH-1:0] pc;
} rob_dispatch_data_t;
`define ROB_DISPATCH_DATA_WIDTH $bits(rob_dispatch_data_t)

// typedef struct packed {
//     logic mispredict;
//     logic reg_ready;
//     reg_data_t reg_data;
// } rob_wb_data_t;

typedef struct packed {
    logic src1_valid; // valid stands for "exists"
    rob_id_t src1_rob_id;
    logic src1_ready; // ready stands for "produced"
    reg_data_t src1_data;
    logic src2_valid;
    rob_id_t src2_rob_id;
    logic src2_ready;
    reg_data_t src2_data;
    logic dst_valid;
    rob_id_t dst_rob_id;
    logic [2:0] alu_ctrl; // FIXME
    logic br_dir_pred; // FIXME (0: not taken, 1: taken) (get this from fetch)
    logic [31:0] jalr_target_pc; // FIXME (get this from fetch?)
} iiq_entry_t;
`define IIQ_ENTRY_WIDTH $bits(iiq_entry_t)

typedef struct packed { // FIXME
    logic ld_st; // 0: ld, 1: st
    rob_id_t base_rob_id;
    logic base_ready;
    logic [`ADDR_WIDTH-1:0] base_addr;
    rob_id_t st_data_ld_dst_rob_id;
    logic st_data_ready;
    reg_data_t st_data;
    logic [1:0] width; // 00: byte (8 bits), 01: half-word (16 bits), 10: word (32 bits)
    logic ld_sign; // 0: unsigned (LBU, LHU), 1: signed (LB, LH, LW)
    // FIXME: logic [`ST_BUF_ID_WIDTH-1:0] st_buf_id; ? (which of ld_buf and st_buf are allocated during dispatch?)
} lsq_entry_t;
`define LSQ_ENTRY_WIDTH $bits(lsq_entry_t)

typedef struct packed {
    logic [2:0] alu_ctrl; // FIXME
    reg_data_t src1_data;
    reg_data_t src2_data;
} iiq_issue_data_t;

`endif
