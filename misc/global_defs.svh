`ifndef GLOBAL_DEFS_V
`define GLOBAL_DEFS_V

// use defines if these values are needed across multiple modules
// just use parameters otherwise
// can have parameters that are the same as these defines but
// do use these global defines to initalize those parameters

`define ADDR_WIDTH 32 // the width of a physical/virtual address (no virtual memory support yet)
`define INSTR_WIDTH 32
`define IMM_WIDTH 32
`define WORD_WIDTH 32

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

`define BLOCK_DATA_WIDTH 64
`define MAIN_MEM_N_BLOCKS (2**(`ADDR_WIDTH-$clog2(`BLOCK_DATA_WIDTH))) // TODO: `BLOCK_DATA_WIDTH vs. `BLOCK_DATA_WIDTH/8 ?P
`define MAIN_MEM_BLOCK_ADDR_WIDTH $clog2(`MAIN_MEM_N_BLOCKS)
`define MAIN_MEM_BLOCK_OFFSET_WIDTH $clog2(`BLOCK_DATA_WIDTH)

`define N_DCACHE_OFFSET_BITS $clog2(`DCACHE_DATA_BLOCK_SIZE/8)
`define N_DCACHE_INDEX_BITS $clog2(`DCACHE_NUM_SETS)
`define N_DCACHE_TAG_BITS (`ADDR_WIDTH - `N_DCACHE_OFFSET_BITS - `N_DCACHE_INDEX_BITS)

`define N_ICACHE_OFFSET_BITS $clog2(`ICACHE_DATA_BLOCK_SIZE/8)
`define ICACHE_INDEX_BITS $clog2(`ICACHE_NUM_SETS)
`define ICACHE_TAG_BITS (`ADDR_WIDTH - `N_ICACHE_OFFSET_BITS - `ICACHE_INDEX_BITS)

`define REG_DATA_WIDTH 32 // the width of data that is held in a retired (ARF) register or speculative (ROB) register
`define ARF_N_ENTRIES 32
`define ARF_ID_WIDTH $clog2(`ARF_N_ENTRIES)
`define ROB_N_ENTRIES 16
`define ROB_ID_WIDTH $clog2(`ROB_N_ENTRIES)
`define IIQ_N_ENTRIES 8
`define IIQ_ID_WIDTH $clog2(`IIQ_N_ENTRIES)
`define LSQ_N_ENTRIES 8
`define LSQ_ID_WIDTH $clog2(`LSQ_N_ENTRIES)
`define ST_BUF_N_ENTRIES 4
`define ST_BUF_ID_WIDTH $clog2(`ST_BUF_N_ENTRIES)
`define LD_BUF_N_ENTRIES 4
`define LD_BUF_ID_WIDTH $clog2(`LD_BUF_N_ENTRIES)

typedef logic [`ADDR_WIDTH-1:0] addr_t;
typedef logic [`INSTR_WIDTH-1:0] instr_t;
typedef logic [`IMM_WIDTH-1:0] imm_t;
typedef logic [`WORD_WIDTH-1:0] word_t;
typedef logic [`REG_DATA_WIDTH-1:0] reg_data_t;
typedef logic [`ARF_ID_WIDTH-1:0] arf_id_t;
typedef logic [`ROB_ID_WIDTH-1:0] rob_id_t;
// TODO: iiq_id and lsq_id? where would they be used?
typedef logic [`ST_BUF_ID_WIDTH-1:0] st_buf_id_t;

typedef logic [`BLOCK_DATA_WIDTH-1:0] block_data_t;
typedef logic [`MAIN_MEM_BLOCK_ADDR_WIDTH-1:0] main_mem_block_addr_t;
typedef logic [`MAIN_MEM_BLOCK_OFFSET_WIDTH-1:0] main_mem_block_offset_t;

typedef logic [`N_DCACHE_OFFSET_BITS-1:0] dcache_offset_t;
typedef logic [`N_DCACHE_INDEX_BITS-1:0] dcache_index_t;
typedef logic [`N_DCACHE_TAG_BITS-1:0] dcache_tag_t;

typedef logic [`N_ICACHE_OFFSET_BITS-1:0] icache_offset_t;
typedef logic [`ICACHE_INDEX_BITS-1:0] icache_index_t;
typedef logic [`ICACHE_TAG_BITS-1:0] icache_tag_t;

typedef enum {ICACHE = 0, DCACHE = 1} cache_type_t;
typedef enum {READ = 0, WRITE = 1} req_type_t;
typedef enum {BYTE = 1, HALFWORD = 2, WORD = 4} req_width_t; // TODO: double-check if these hardcoded values work

`define I_IMM(instr) ({                  {21{instr[31]}}                , instr[30:25], instr[24:21], instr[20] })
`define S_IMM(instr) ({                  {21{instr[31]}}                , instr[30:25], instr[11:8] , instr[7]  })
`define B_IMM(instr) ({            {20{instr[31]}}           , instr[7] , instr[30:25], instr[11:8] ,   1'b0    })
`define U_IMM(instr) ({ instr[31], instr[30:20], instr[19:12],                    12'b0                         })
`define J_IMM(instr) ({     {12{instr[31]}}    , instr[19:12], instr[20], instr[30:25], instr[24:21],   1'b0    })

typedef struct packed {
    instr_t instr;
    addr_t pc;
    logic is_cond_br;
    logic br_dir_pred;
    addr_t br_target_pred;
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
    addr_t pc_npc; // pc if a load instruction, npc if a branch instruction
    // logic ld_mispred; // FIXME
    logic br_mispred;
    logic is_executed;
    reg_data_t reg_data;
} rob_entry_t;
`define ROB_ENTRY_WIDTH $bits(rob_entry_t)

typedef struct packed {
    logic dst_valid;
    arf_id_t dst_arf_id;
    addr_t pc;
} rob_dispatch_data_t;
`define ROB_DISPATCH_DATA_WIDTH $bits(rob_dispatch_data_t)

// typedef struct packed {
//     logic mispred;
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
    rob_id_t instr_rob_id;
    imm_t imm;
    addr_t pc;
    logic [2:0] funct3; // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    logic is_r_type;
    logic is_i_type;
    logic is_u_type; // lui and auipc only
    logic is_b_type;
    logic is_j_type; // jal only
    logic is_sub; // if is_r_type, 0 = add, 1 = sub
    logic is_sra_srai; // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    logic is_lui; // if is_u_type, 0 = auipc, 1 = lui
    logic is_jalr; // if is_i_type, 0 = else, 1 = jalr
    logic br_dir_pred; // (0: not taken, 1: taken) (get this from fetch)
    addr_t br_target_pred;
} iiq_entry_t;
`define IIQ_ENTRY_WIDTH $bits(iiq_entry_t)

typedef struct packed {
    logic ld_st; // 0: ld, 1: st
    rob_id_t base_addr_rob_id;
    logic base_addr_ready;
    addr_t base_addr;
    imm_t imm;
    rob_id_t st_data_rob_id;
    logic st_data_ready;
    reg_data_t st_data;
    rob_id_t instr_rob_id;
    logic [1:0] width; // 00: byte (8 bits), 01: half-word (16 bits), 10: word (32 bits)
    logic ld_sign; // 0: unsigned (LBU, LHU), 1: signed (LB, LH, LW)
    logic [`ST_BUF_ID_WIDTH-1:0] st_buf_id; // only st_buf is allocated during dispatch, not ld_buf
} lsq_entry_t;
`define LSQ_ENTRY_WIDTH $bits(lsq_entry_t)

typedef struct packed {
    logic ld_st; // 0: ld, 1: st
    rob_id_t base_addr_rob_id;
    logic base_addr_ready;
    addr_t base_addr;
    imm_t imm;
    rob_id_t st_data_rob_id;
    logic st_data_ready;
    reg_data_t st_data;
    rob_id_t instr_rob_id;
    req_width_t width;
    logic ld_sign; // 0: signed, 1: unsigned
} lsq_simple_entry_t;
`define LSQ_SIMPLE_ENTRY_WIDTH $bits(lsq_simple_entry_t)

typedef struct packed {
    reg_data_t src1_data;
    reg_data_t src2_data;
    rob_id_t instr_rob_id; // received from issue
    imm_t imm;
    addr_t pc;
    logic [2:0] funct3; // determines branch type, alu operation type (add(i), sll(i), xor(i), etc.)
    logic is_r_type;
    logic is_i_type;
    logic is_u_type; // lui and auipc only
    logic is_b_type;
    logic is_j_type; // jal only
    logic is_sub; // if is_r_type, 0 = add, 1 = sub
    logic is_sra_srai; // if shift, 0 = sll(i) | srl(i), 1 = sra(i)
    logic is_lui; // if is_u_type, 0 = auipc, 1 = lui
    logic is_jalr; // if is_i_type, 0 = else, 1 = jalr
    logic br_dir_pred; // (0: not taken, 1: taken)
} iiq_issue_data_t;
`define IIQ_ISSUE_DATA_WIDTH $bits(iiq_issue_data_t)

typedef struct packed {
    addr_t eff_addr;
    logic [1:0] ld_width;
    logic is_dcache_initiated; // FIXME the name, TODO plan how to use it
    rob_id_t instr_rob_id;
    reg_data_t ld_data; // NOTE: already (sign/zero) extended for the destination register
} ld_buf_entry_t;
`define LD_BUF_ENTRY_WIDTH $bits(ld_buf_entry_t)

typedef struct packed {
    addr_t eff_addr;
    reg_data_t st_data;
    logic [2:0] st_width;
} st_buf_entry_t;
`define ST_BUF_ENTRY_WIDTH $bits(st_buf_entry_t)

typedef struct packed {
    logic valid;
    logic rd_wr; // 0: rd, 1: wr
    addr_t addr;
    logic [1:0] width;
    reg_data_t data; // only for wr requests
} lsu_dcache_req_t;

typedef struct packed {
    logic valid;
    reg_data_t data;
} dcache_lsu_resp_t; // only in response to rd requests

typedef struct packed {
    logic valid;
    addr_t addr;
} ifu_icache_req_t;

typedef struct packed {
    logic valid;
    instr_t instr;
} icache_ifu_resp_t;

typedef struct packed {
    logic valid;
    logic rd_wr;
    main_mem_block_addr_t addr;
    block_data_t data;
} dcache_main_mem_req_t;

typedef struct packed {
    logic valid;
    main_mem_block_addr_t addr;
    block_data_t data;
} icache_main_mem_req_t;

typedef struct packed {
    logic valid;
    logic i_d; // 0: instruction, 1: data
    main_mem_block_addr_t addr;
    block_data_t data;
} main_mem_req_t;

typedef struct packed {
    logic valid;
    logic i_d; // 0: instruction, 1: data
    block_data_t data;
} main_mem_resp_t;

typedef struct packed {
    logic valid;
    block_data_t data;
} main_mem_dcache_resp_t;

typedef struct packed {
    logic valid;
    block_data_t data;
} main_mem_icache_resp_t;

typedef enum {POSEDGE, NEGEDGE} edge_t;

`define LUI_OPCODE    7'b0110111
`define AUIPC_OPCODE  7'b0010111
`define JAL_OPCODE    7'b1101111
`define JALR_OPCODE   7'b1100111
`define BR_OPCODE     7'b1100011
`define LD_OPCODE     7'b0000011
`define ST_OPCODE     7'b0100011
`define OP_IMM_OPCODE 7'b0010011
`define OP_OPCODE     7'b0110011

`define BEQ_FUNCT3 3'b000
`define BNE_FUNCT3 3'b001
`define BLT_FUNCT3 3'b100
`define BGE_FUNCT3 3'b101
`define BLTU_FUNCT3 3'b110
`define BGEU_FUNCT3 3'b111

`define LB_FUNCT3 3'b000
`define LH_FUNCT3 3'b001
`define LW_FUNCT3 3'b010
`define LBU_FUNCT3 3'b100
`define LHU_FUNCT3 3'b101

`define SB_FUNCT3 3'b000
`define SH_FUNCT3 3'b001
`define SW_FUNCT3 3'b010

`define ADD_FUNCT3 3'b000
`define ADDI_FUNCT3 3'b000
`define SUB_FUNCT3 3'b000
`define SLL_FUNCT3 3'b001
`define SLLI_FUNCT3 3'b001
`define SLT_FUNCT3 3'b010
`define SLTI_FUNCT3 3'b010
`define SLTU_FUNCT3 3'b011
`define SLTIU_FUNCT3 3'b011
`define XOR_FUNCT3 3'b100
`define XORI_FUNCT3 3'b100
`define SRL_FUNCT3 3'b101
`define SRLI_FUNCT3 3'b101
`define SRA_FUNCT3 3'b101
`define SRAI_FUNCT3 3'b101
`define OR_FUNCT3 3'b110
`define ORI_FUNCT3 3'b110
`define AND_FUNCT3 3'b111
`define ANDI_FUNCT3 3'b111

`define opcode_bits 6:0
`define rd_bits 11:7
`define funct3_bits 14:12
`define rs1_bits 19:15
`define rs2_bits 24:20
`define funct7_bits 31:25
typedef logic [6:0] opcode_t;
typedef logic [2:0] funct3_t;
typedef logic [6:0] funct7_t;

// typedef struct packed {
//     logic [6:0] funct7;
//     logic [4:0] rs2;
//     logic [4:0] rs1;
//     logic [2:0] funct3;
//     logic [4:0] rd;
//     logic [6:0] opcode;
// } r_type_instr_t;

// typedef struct packed {
//     logic [11:0] imm;
//     logic [4:0] rs1;
//     logic [2:0] funct3;
//     logic [4:0] rd;
//     logic [6:0] opcode;
// } i_type_instr_t;

// typedef struct packed {
//     logic [11:5] imm11_5;
//     logic [4:0] rs2;
//     logic [4:0] rs1;
//     logic [2:0] funct3;
//     logic [4:0] imm4_0;
//     logic [6:0] opcode;
// } s_type_instr_t;

// typedef struct packed {
//     logic imm12;
//     logic [10:5] imm10_5;
//     logic [4:0] rs2;
//     logic [4:0] rs1;
//     logic [2:0] funct3;
//     logic [4:1] imm4_1;
//     logic imm11;
//     logic [6:0] opcode;
// } b_type_instr_t;

// typedef struct packed {
//     logic [31:12] imm31_12;
//     logic [4:0] rd;
//     logic [6:0] opcode;
// } u_type_instr_t;

// typedef struct packed {
//     logic imm20;
//     logic [10:1] imm10_1;
//     logic imm11;
//     logic [19:12] imm19_12;
//     logic [4:0] rd;
//     logic [6:0] opcode;
// } j_type_instr_t;

virtual class rng #(parameter WIDTH);
    static function void rng(output [WIDTH-1:0] data);
        for (int i = 0; i < WIDTH; i += 32) begin
            data[i+:32] = $urandom();
        end
    endfunction
endclass

// typedef struct packed {
//     logic  csb0_reg;
//     logic  web0_reg;
//     logic [NUM_WMASKS-1:0]  wmask0_reg;
//     logic [ADDR_WIDTH-1:0]  addr0_reg;
//     logic [DATA_WIDTH-1:0]  din0_reg;
// } icache_sram_latches_state_t;

// typedef struct packed {

// } icache_latches_state_t;

// typedef struct packed {

// } pc_state_t;

// typedef struct packed {

// } icache_lfsr_state_t;

// typedef struct packed {

// } icache_tag_array_state_t;

// typedef struct packed {

// } icache_data_array_state_t;

// typedef struct packed {

// } ififo_state_t;

// typedef struct packed {

// } rat_state_t;

// typedef struct packed {

// } rob_state_t;

// typedef struct packed {

// } arf_state_t;

// typedef struct packed {

// } iiq_state_t;

// typedef struct packed {

// } lsq_simple_state_t;

// typedef struct packed {

// } integer_issue_buffer_state_t;

// typedef struct packed {

// } dcache_sram_latches_state_t;

// typedef struct packed {

// } dcache_latches_state_t;

// typedef struct packed {

// } dcache_lfsr_state_t;

// typedef struct packed {

// } dcache_tag_array_state_t;

// typedef struct packed {

// } dcache_data_array_state_t;

// typedef struct packed {

// } req_pipeline_state_t;

// typedef struct packed {

// } main_mem_state_t;

`endif
