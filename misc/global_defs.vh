`ifndef GLOBAL_DEFS_V
`define GLOBAL_DEFS_V

// use defines if these values are needed across multiple modules
// just use parameters otherwise
// can have parameters that are the same as these defines but 
// do use these global defines to initalize those parameters

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

`define REG_BITS 5

`define ROB_ENTRY_WIDTH 32
`define ROB_DEPTH 16

`define IIQ_ENTRY_WIDTH 32 // TODO: this is a placeholder. calculate the actual width.
`define LSQ_ENTRY_WIDTH 81

`endif
