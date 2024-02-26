// use defines if these values are needed across multiple modules
// just use parameters otherwise
// can have parameters that are the same as these defines but 
// do use these global defines to initalize those parameters

`define ADDR_WIDTH 32
`define INSTR_SIZE 32

`define ICACHE_NUM_SETS 64
`define ICACHE_TAG_ENTRY_SIZE 24
`define ICACHE_DATA_BLOCK_SIZE 64
`define ICACHE_NUM_WAYS 2

`define DCACHE_NUM_SETS 64
`define DCACHE_TAG_ENTRY_SIZE 25
`define DCACHE_DATA_BLOCK_SIZE 64
`define DCACHE_NUM_WAYS 2
