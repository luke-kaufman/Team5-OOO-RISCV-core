`ifndef GLOBAL_DEFS_V
`define GLOBAL_DEFS_V

// use defines if these values are needed across multiple modules
// just use parameters otherwise
// can have parameters that are the same as these defines but 
// do use these global defines to initalize those parameters

`define PC_WIDTH 32
`define ADDR_WIDTH 32
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

`define ROB_DEPTH 16
`define ROB_ID_WIDTH $clog2(`ROB_DEPTH)
`define ARF_DEPTH 32
`define ARF_ID_WIDTH $clog2(`ARF_DEPTH)

`define REG_WIDTH 32

`define IIQ_ENTRY_WIDTH 32 // TODO: this is a placeholder. calculate the actual width.
`define LSQ_ENTRY_WIDTH 81

typedef struct packed {
    logic dst_valid;
    logic [`ARF_ID_WIDTH-1:0] dst_arf_id;
    logic [`PC_WIDTH-1:0] pc;
} rob_dispatch_data_t;

typedef struct packed {
    logic dst_valid;
    logic [`ARF_ID_WIDTH-1:0] dst_arf_id;
    logic [`PC_WIDTH-1:0] pc;
    logic ld_mispredict;
    logic br_mispredict;
    logic reg_ready;
    logic [`REG_WIDTH-1:0] reg_data;
} rob_entry_t;

`endif
