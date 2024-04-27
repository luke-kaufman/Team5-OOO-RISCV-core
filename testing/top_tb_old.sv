`include "misc/global_defs.svh"
`include "top/top.sv"

`define NUM_SETS 2  // number of test sets

module top_tb_old #(
    parameter VERBOSE = 0,
    parameter N_RANDOM_TESTS = 100,
    parameter HIGHEST_PC = 32'h80000,
    localparam main_mem_block_addr_t HIGHEST_INSTR_BLOCK_ADDR = HIGHEST_PC >> `MAIN_MEM_BLOCK_OFFSET_WIDTH
);
    typedef enum {
        IFU_STAGE,
        DISPATCH_STAGE,
        INTEGER_STAGE,
        LSU_STAGE,
        NUM_STAGES
    } STAGE;

    // classes for wrapping test data
    class ProgramWrapper;
        int prog[int];  // actual map/dict of program
        int start_PC;
        int num_instrs;
        int prog_addrs[256]; // 256 max number of instructions in Icache
    endclass

    // class CoreOutWrapper;
    //     // something else here ?
    //     // IFUOutWrapper ifu_out;
    //     // DispatchOutWrapper dispatch_out;
    //     // IntegerOutWrapper integer_out;
    //     // LSUOutWrapper lsu_out;
    // endclass

    class IFUOutWrapper;
        ififo_entry_t ifu_out[int];
    endclass

    class DispatchOutWrapper;
        iiq_entry_t iiq_out[int];
        lsq_entry_t lsq_out[int];
    endclass
    // class IntegerOutWrapper;
    //     reg_data_t alu_out[int];
    // endclass
    // class LSUOutWrapper;
    //     reg_data_t ld_out[int];
    // endclass

    bit ALL_VERBOSE = 0;
    bit FETCH_VERBOSE = 0 | ALL_VERBOSE;
    bit DISP_VERBOSE = 1 | ALL_VERBOSE;
    bit IIQ_VERBOSE = 0 | ALL_VERBOSE;
    bit ALU_VERBOSE = 0 | ALL_VERBOSE;
    bit LSU_VERBOSE = 0 | ALL_VERBOSE;

    int cycle;
    int prev_PC;
    int curr_PC;
    int num_directed_tests[`NUM_SETS][NUM_STAGES];
    int num_directed_tests_passed[`NUM_SETS][NUM_STAGES];
    ProgramWrapper test_programs[`NUM_SETS];
    IFUOutWrapper test_ifu_outs[`NUM_SETS];

    /*input*/ bit clk=1;
    /*input*/ reg rst_aL=1;
    /*input*/ bit csb0_in=1;
    /*input*/ bit init=0;
    /*input*/ addr_t init_sp=0;

    bit testing = 1;
    block_data_t test_icache_fill_block = 0;

    // clock generation & other external core inputs
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        forever #HALF_PERIOD clk = ~clk;
    end

    block_data_t init_main_mem_state [HIGHEST_INSTR_BLOCK_ADDR:0];
    // ARF OUT from core
    wire [`ARF_N_ENTRIES-1:0][`REG_DATA_WIDTH-1:0] arf_out_data;
    wire block_data_t main_mem_out_data[HIGHEST_INSTR_BLOCK_ADDR:0];

    // TOP INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    top #(
        .VERBOSE(VERBOSE),
        .HIGHEST_PC(HIGHEST_PC)
    ) _top (
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .init_pc(32'h1018c),
        .init_arf_state('0),

        .init_main_mem_state(init_main_mem_state),  // input block_data_t [`MAIN_MEM_N_BLOCKS]
        .ARF_OUT(arf_out_data), // output [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0]
        .MAIN_MEM_OUT(main_mem_out_data)
    );
    // END TOP INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    task build_testcases(int s_i);
        case (s_i)
            0 : begin // TEST SET 1: just instructions
                // ififo_dispatch_ready = 1;
                test_programs[s_i] = new();
                test_programs[s_i].num_instrs=7;
                test_programs[s_i].start_PC=32'h1018c;
                init_sp = test_programs[s_i].start_PC-4;
                test_programs[s_i].prog[32'h1018c]=32'hfe010113; // add sp,sp,-32
                test_programs[s_i].prog[32'h10190]=32'h00812e23; // sw s0,28(sp)
                test_programs[s_i].prog[32'h10194]=32'h00912c23; // sw s1,24(sp)
                test_programs[s_i].prog[32'h10198]=32'h02010413; // add s0,sp,32
                // test_programs[s_i].prog[32'h1019c]=32'hfea42623; // sw a0,-20(s0)
                // test_programs[s_i].prog[32'h101a0]=32'hfeb42423; // sw a1,-24(s0)
                test_programs[s_i].prog[32'h1019c]=32'h00f00493; // li s1,15
                // test_programs[s_i].prog[32'h101a8]=32'h01348493; // add s1,s1,19
                // test_programs[s_i].prog[32'h101ac]=32'hffc48493; // add s1,s1,-4
                // test_programs[s_i].prog[32'h101b0]=32'h00048713; // mv a4,s1
                // test_programs[s_i].prog[32'h101b4]=32'h800007b7; // lui a5,0x80000
                // test_programs[s_i].prog[32'h101b8]=32'h00f747b3; // xor a5,a4,a5
                // test_programs[s_i].prog[32'h101bc]=32'h00078493; // mv s1,a5
                // test_programs[s_i].prog[32'h101c0]=32'h800007b7; // lui a5,0x80000
                // test_programs[s_i].prog[32'h101c4]=32'hfff78793; // add a5,a5,-1 # 7fffffff <__BSS_END__+0x7ffed77f>
                // test_programs[s_i].prog[32'h101c8]=32'h00f4f4b3; // and s1,s1,a5
                // test_programs[s_i].prog[32'h101cc]=32'h00048793; // mv a5,s1
                // test_programs[s_i].prog[32'h101d0]=32'h00078513; // mv a0,a5
                test_programs[s_i].prog[32'h101a0]=32'h01c12403; // lw s0,28(sp)
                test_programs[s_i].prog[32'h101a4]=32'h01812483; // lw s1,24(sp)
                // test_programs[s_i].prog[32'h101dc]=32'h02010113; // add sp,sp,32
                // test_programs[s_i].prog[32'h101e0]=32'h00008067; // ret
                test_programs[s_i].prog_addrs[0]=32'h1018c;
                test_programs[s_i].prog_addrs[1]=32'h10190;
                test_programs[s_i].prog_addrs[2]=32'h10194;
                test_programs[s_i].prog_addrs[3]=32'h10198;
                test_programs[s_i].prog_addrs[4]=32'h1019c;
                test_programs[s_i].prog_addrs[5]=32'h101a0;
                test_programs[s_i].prog_addrs[6]=32'h101a4;
                test_programs[s_i].prog_addrs[7]=32'h101a8;
                test_programs[s_i].prog_addrs[8]=32'h101ac;
                test_programs[s_i].prog_addrs[9]=32'h101b0;
                test_programs[s_i].prog_addrs[10]=32'h101b4;
                test_programs[s_i].prog_addrs[11]=32'h101b8;
                test_programs[s_i].prog_addrs[12]=32'h101bc;
                test_programs[s_i].prog_addrs[13]=32'h101c0;
                test_programs[s_i].prog_addrs[14]=32'h101c4;
                test_programs[s_i].prog_addrs[15]=32'h101c8;
                test_programs[s_i].prog_addrs[16]=32'h101cc;
                test_programs[s_i].prog_addrs[17]=32'h101d0;
                test_programs[s_i].prog_addrs[18]=32'h101d4;
                test_programs[s_i].prog_addrs[19]=32'h101d8;
                test_programs[s_i].prog_addrs[20]=32'h101dc;
                test_programs[s_i].prog_addrs[21]=32'h101e0;

                // construct output to check against
                test_ifu_outs[s_i] = new();
                foreach (test_programs[s_i].prog[key_PC]) begin
                    test_ifu_outs[s_i].ifu_out[key_PC].instr = test_programs[s_i].prog[key_PC];
                    test_ifu_outs[s_i].ifu_out[key_PC].pc = key_PC;
                    test_ifu_outs[s_i].ifu_out[key_PC].is_cond_br = 0;
                    test_ifu_outs[s_i].ifu_out[key_PC].br_dir_pred = (key_PC == 32'h101e0);
                    test_ifu_outs[s_i].ifu_out[key_PC].br_target_pred = key_PC + 4;
                end
            end
            1 : begin // TEST SET 2: BREAKS BECAUSE DYNAM FOR LOOP - Correctly predicted branches
                // ififo_dispatch_ready = 1;
                test_programs[s_i] = new();
                test_programs[s_i].num_instrs=27;
                test_programs[s_i].start_PC=32'h1018c;
                init_sp = test_programs[s_i].start_PC-4;
                test_programs[s_i].prog[32'h1018c]=32'hfd010113; // add sp,sp,-48
                test_programs[s_i].prog[32'h10190]=32'h02812623; // sw s0,44(sp)
                test_programs[s_i].prog[32'h10194]=32'h03010413; // add s0,sp,48
                test_programs[s_i].prog[32'h10198]=32'hfca42e23; // sw a0,-36(s0)
                test_programs[s_i].prog[32'h1019c]=32'hfcb42c23; // sw a1,-40(s0)
                test_programs[s_i].prog[32'h101a0]=32'hfe042623; // sw zero,-20(s0)
                test_programs[s_i].prog[32'h101a4]=32'hfec42783; // lw a5,-20(s0)
                test_programs[s_i].prog[32'h101a8]=32'h0007c863; // bltz a5,101b8 <main+0x2c>
                test_programs[s_i].prog[32'h101ac]=32'h0000c7b7; // lui a5,0xc
                test_programs[s_i].prog[32'h101b0]=32'heef78793; // add a5,a5,-273 # beef <exit-0x41a5>
                test_programs[s_i].prog[32'h101b4]=32'hfef42623; // sw a5,-20(s0)
                test_programs[s_i].prog[32'h101b8]=32'hfe042623; // sw zero,-20(s0)
                test_programs[s_i].prog[32'h101bc]=32'h01c0006f; // j 101d8 <main+0x4c>
                test_programs[s_i].prog[32'h101c0]=32'hfec42783; // lw a5,-20(s0)
                test_programs[s_i].prog[32'h101c4]=32'h00178793; // add a5,a5,1
                test_programs[s_i].prog[32'h101c8]=32'hfef42623; // sw a5,-20(s0)
                test_programs[s_i].prog[32'h101cc]=32'hfec42783; // lw a5,-20(s0)
                test_programs[s_i].prog[32'h101d0]=32'h00178793; // add a5,a5,1
                test_programs[s_i].prog[32'h101d4]=32'hfef42623; // sw a5,-20(s0)
                test_programs[s_i].prog[32'h101d8]=32'hfec42703; // lw a4,-20(s0)
                test_programs[s_i].prog[32'h101dc]=32'h00100793; // li a5,1
                test_programs[s_i].prog[32'h101e0]=32'hfee7d0e3; // bge a5,a4,101c0 <main+0x34>
                test_programs[s_i].prog[32'h101e4]=32'hfec42783; // lw a5,-20(s0)
                test_programs[s_i].prog[32'h101e8]=32'h00078513; // mv a0,a5
                test_programs[s_i].prog[32'h101ec]=32'h02c12403; // lw s0,44(sp)
                test_programs[s_i].prog[32'h101f0]=32'h03010113; // add sp,sp,48
                test_programs[s_i].prog[32'h101f4]=32'h00008067; // ret
                test_programs[s_i].prog_addrs[0]=32'h1018c;
                test_programs[s_i].prog_addrs[1]=32'h10190;
                test_programs[s_i].prog_addrs[2]=32'h10194;
                test_programs[s_i].prog_addrs[3]=32'h10198;
                test_programs[s_i].prog_addrs[4]=32'h1019c;
                test_programs[s_i].prog_addrs[5]=32'h101a0;
                test_programs[s_i].prog_addrs[6]=32'h101a4;
                test_programs[s_i].prog_addrs[7]=32'h101a8;
                test_programs[s_i].prog_addrs[8]=32'h101ac;
                test_programs[s_i].prog_addrs[9]=32'h101b0;
                test_programs[s_i].prog_addrs[10]=32'h101b4;
                test_programs[s_i].prog_addrs[11]=32'h101b8;
                test_programs[s_i].prog_addrs[12]=32'h101bc;
                test_programs[s_i].prog_addrs[13]=32'h101c0;
                test_programs[s_i].prog_addrs[14]=32'h101c4;
                test_programs[s_i].prog_addrs[15]=32'h101c8;
                test_programs[s_i].prog_addrs[16]=32'h101cc;
                test_programs[s_i].prog_addrs[17]=32'h101d0;
                test_programs[s_i].prog_addrs[18]=32'h101d4;
                test_programs[s_i].prog_addrs[19]=32'h101d8;
                test_programs[s_i].prog_addrs[20]=32'h101dc;
                test_programs[s_i].prog_addrs[21]=32'h101e0;
                test_programs[s_i].prog_addrs[22]=32'h101e4;
                test_programs[s_i].prog_addrs[23]=32'h101e8;
                test_programs[s_i].prog_addrs[24]=32'h101ec;
                test_programs[s_i].prog_addrs[25]=32'h101f0;
                test_programs[s_i].prog_addrs[26]=32'h101f4;

                // construct output to check against
                test_ifu_outs[s_i] = new();
                foreach (test_programs[s_i].prog[key_PC]) begin
                    test_ifu_outs[s_i].ifu_out[key_PC].instr = test_programs[s_i].prog[key_PC];
                    test_ifu_outs[s_i].ifu_out[key_PC].pc = key_PC;
                    if(key_PC == 32'h101a8) begin
                        test_ifu_outs[s_i].ifu_out[key_PC].is_cond_br = 1;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_dir_pred = 0;  // not taken
                        test_ifu_outs[s_i].ifu_out[key_PC].br_target_pred = key_PC + 4; // not taken
                    end
                    else if(key_PC == 32'h101bc) begin
                        test_ifu_outs[s_i].ifu_out[key_PC].is_cond_br = 0;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_dir_pred = 1;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_target_pred = 32'h101d8; // 101d8
                    end
                    else if(key_PC == 32'h101e0) begin
                        test_ifu_outs[s_i].ifu_out[key_PC].is_cond_br = 1;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_dir_pred = 1;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_target_pred = 32'h101c0; // 101c0
                    end
                    else begin
                        test_ifu_outs[s_i].ifu_out[key_PC].is_cond_br = 0;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_dir_pred = 0;
                        test_ifu_outs[s_i].ifu_out[key_PC].br_target_pred = key_PC + 4;
                    end
                end
            end
            // default:
        endcase
    endtask

    task fetch_negedge_dump(int cycle);
        // $display("Fetch_redirect_pc %8h", _top._core._ifu.fetch_redirect_PC);
        $display("PC_wire %8h", _top._core._ifu.PC_wire);
        // $display("next_pc %8h", _top._core._ifu.next_PC);
        // $display("Fetch_redirect_valid %1b", _top._core._ifu.fetch_redirect_valid);
        // $display("stall %1b", _top._core._ifu.stall);
        $display("IFIFO STALL %1b ICACHE MISS %1b", _top._core._ifu.IFIFO_stall, _top._core._ifu.icache_miss);
        // $display("tag_array_hit %1b", _top._core._ifu.icache.tag_array_hit);
        // $display("pipeline_req_valid_latched %1b", _top._core._ifu.icache.pipeline_req_valid_latched);
        if(_top._core._ifu.icache_hit) begin
            $display("FETCH: FIFO ENTRY ABOUT TO BE LATCHED FOR THIS INSTRUCTION:");
            $display("FETCH: Set accessed: %6b", _top._core._ifu.icache.tag_array.addr0_reg);
            $display("FETCH: IFIFO_enq_data.instr: 0x%8h", _top._core._ifu.IFIFO_enq_data.instr);
            $display("FETCH: IFIFO_enq_data.pc: 0x%8h", _top._core._ifu.IFIFO_enq_data.pc);
            $display("FETCH: IFIFO_enq_data.is_cond_br: %1b" , _top._core._ifu.IFIFO_enq_data.is_cond_br);
            $display("FETCH: IFIFO_enq_data.br_dir_pred: %1b" , _top._core._ifu.IFIFO_enq_data.br_dir_pred);
            $display("FETCH: IFIFO_enq_data.br_target_pred: 0x%8h" , _top._core._ifu.IFIFO_enq_data.br_target_pred);
            $display();
            $display("FETCH: enq_ready %1b", _top._core._ifu.IFIFO_enq_ready); // output - can fifo receive data?
            $display("FETCH: enq_valid %1b", _top._core._ifu.icache_hit);      // input - enqueue if icache hit
        end
        $display();
    endtask
    task fetch_posedge_dump(int cycle);
        $display("FETCH: deq_ready %1b", _top._core._ifu.ififo_dispatch_ready);  // input - interface from dispatch
        $display("FETCH: deq_valid %1b", _top._core._ifu.ififo_dispatch_valid);     // output - interface to dispatch
        $display("FETCH: deq_data 0x%8h", _top._core._ifu.ififo_dispatch_data); // output - dispatched instr
        $display("IFIFO STALL %1b ICACHE MISS %1b", _top._core._ifu.IFIFO_stall, _top._core._ifu.icache_miss);
        // $display("tag_array_hit %1b", _top._core._ifu.icache.tag_array_hit);
        // $display("pipeline_req_valid_latched %1b", _top._core._ifu.icache.pipeline_req_valid_latched);
        $display("LATCHED PC 0x%8h", _top._core._ifu.PC_wire);
        $display("LATCHED SRAM ADDR index %6b", _top._core._ifu.icache.pipeline_req_addr_index_latched);
        // $display("fetch_redirect_valid %1b, stall_gate_ZN %1b", _top._core._ifu.fetch_redirect_valid, _top._core._ifu.stall_gate.ZN);
        // $display("pipeline_resp_rd_data 0x%8h", _top._core._ifu.icache.pipeline_resp_rd_data);
        $display();
    endtask

    task dispatch_negedge_dump(int cycle);
    endtask
    task dispatch_posedge_dump(int cycle);
        if(_top._core._ifu.ififo_dispatch_valid) begin
            $display("DISPATCH: IFIFO DISPATCH DATA 0x%8h", _top._core._dispatch.ififo_dispatch_data);
            $display("DISPATCH: IFIFO DISPATCH READY %1b", _top._core._dispatch.ififo_dispatch_ready);
            $display("DISPATCH: Ready ins: (ififo_dis_v: %1b rob_v: %1b (enq_ctr: %6b deq_ctr: %6b) iiq_ok: %1b lsq_ok: %1b)",
                _top._core._ifu.ififo_dispatch_valid,
                _top._core._dispatch.rob_dispatch_ready,
                _top._core._dispatch._rob.rob_mem.enq_ctr_r,
                _top._core._dispatch._rob.rob_mem.deq_ctr_r,
                _top._core._dispatch.iiq_dispatch_ok,
                _top._core._dispatch.lsq_dispatch_ok
            );

            $display("DISPATCH: IIQ DISP V: %1b", _top._core._dispatch.iiq_dispatch_valid);
            $display("DECODE INSTR: %8h", _top._core._dispatch.instr);
            $display("DISPATCH: IIQ DISP ENTRY:\n \nsrc1_valid: %1b\nsrc1_rob_id: %1d\nsrc1_ready: %1b\nsrc1_data: %d\nsrc2_valid: %1b\nsrc2_rob_id: %1d\nsrc2_ready: %1b\nsrc2_data: %d\ndst_valid: %1b\ninstr_rob_id: %1d\nimm: %d\npc: %8h\nfunct3: %3b\nis_r_type: %1b\nis_i_type: %1b\nis_u_type: %1b\nis_b_type: %1b\nis_j_type: %1b\nis_sub: %1b\nis_sra_srai: %1b\nis_lui: %1b\nis_jalr: %1b\nbr_dir_pred: %1b\nbr_target_pred: %8h",
                _top._core._dispatch.iiq_dispatch_data.src1_valid,
                _top._core._dispatch.iiq_dispatch_data.src1_rob_id,
                _top._core._dispatch.iiq_dispatch_data.src1_ready,
                _top._core._dispatch.iiq_dispatch_data.src1_data,
                _top._core._dispatch.iiq_dispatch_data.src2_valid,
                _top._core._dispatch.iiq_dispatch_data.src2_rob_id,
                _top._core._dispatch.iiq_dispatch_data.src2_ready,
                _top._core._dispatch.iiq_dispatch_data.src2_data,
                _top._core._dispatch.iiq_dispatch_data.dst_valid,
                _top._core._dispatch.iiq_dispatch_data.instr_rob_id,
                _top._core._dispatch.iiq_dispatch_data.imm,
                _top._core._dispatch.iiq_dispatch_data.pc,
                _top._core._dispatch.iiq_dispatch_data.funct3,
                _top._core._dispatch.iiq_dispatch_data.is_r_type,
                _top._core._dispatch.iiq_dispatch_data.is_i_type,
                _top._core._dispatch.iiq_dispatch_data.is_u_type,
                _top._core._dispatch.iiq_dispatch_data.is_b_type,
                _top._core._dispatch.iiq_dispatch_data.is_j_type,
                _top._core._dispatch.iiq_dispatch_data.is_sub,
                _top._core._dispatch.iiq_dispatch_data.is_sra_srai,
                _top._core._dispatch.iiq_dispatch_data.is_lui,
                _top._core._dispatch.iiq_dispatch_data.is_jalr,
                _top._core._dispatch.iiq_dispatch_data.br_dir_pred,
                _top._core._dispatch.iiq_dispatch_data.br_target_pred
            );

        end
        $display();
    endtask

    task IIQ_posedge_dump(int cycle);
        $display();
    endtask

    task check_stage(int s_i, int stage);
        case(stage)
            IFU_STAGE: begin
                if(_top._core._ifu.ififo_dispatch_valid) begin
                    num_directed_tests[s_i][IFU_STAGE]++;
                    if(_top._core._ifu.ififo_dispatch_valid && _top._core._ifu.ififo_dispatch_data == test_ifu_outs[s_i].ifu_out[prev_PC]) begin
                        num_directed_tests_passed[s_i][IFU_STAGE]++;
                        $display("FETCH: PASSED CASE ON DISPATCH OUT 0x%8h:", prev_PC);
                    end
                    else begin  // need prev_PC because next_PC gets latched into PC right before checking
                        $display("FETCH: FAILED CASE ON DISPATCH OUT 0x%8h:", prev_PC);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_valid %1b", _top._core._ifu.ififo_dispatch_valid);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.instr 0x%8h EXPECTED: 0x%8h", _top._core._ifu.ififo_dispatch_data[97:66], test_ifu_outs[s_i].ifu_out[prev_PC][97:66]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.pc 0x%8h EXPECTED: 0x%8h", _top._core._ifu.ififo_dispatch_data[65:34], test_ifu_outs[s_i].ifu_out[prev_PC][65:34]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.is_cond_br %1b EXPECTED: %1b", _top._core._ifu.ififo_dispatch_data[33], test_ifu_outs[s_i].ifu_out[prev_PC][33]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.br_dir_pred %1b EXPECTED: %1b", _top._core._ifu.ififo_dispatch_data[32], test_ifu_outs[s_i].ifu_out[prev_PC][32]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.br_target_pred 0x%8h EXPECTED: 0x%8h", _top._core._ifu.ififo_dispatch_data[31:0], test_ifu_outs[s_i].ifu_out[prev_PC][31:0]);
                    end
                end
            end
            DISPATCH_STAGE: begin
            end
            INTEGER_STAGE: begin
            end
            LSU_STAGE: begin
            end
        endcase
    endtask

    bit skip = 0;
    main_mem_block_addr_t block_addr;
    main_mem_block_offset_t block_offset;
    task fill_main_mem_and_start_read(int s_i);
        // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        $display("Filling main_mem with instructions:");
        // init_main_mem_state = 0;
        for(int i=0; i<test_programs[s_i].num_instrs; i=i+1) begin

            {block_addr, block_offset} = test_programs[s_i].prog_addrs[i];
            if (8*block_offset + `INSTR_WIDTH <= `BLOCK_DATA_WIDTH) begin
                init_main_mem_state[block_addr][8*block_offset+:`INSTR_WIDTH] = test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]];
                // $display("FILL MAIN MEM: mem[0x%8h] %d, INSTR: 0x%8h", block_addr, 8*block_offset, test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]]);
            end
            else begin
                $error("FILL MAIN MEM: INSTRUCTION NOT ALIGNED");
            end
        end
        // init main mem
        #1;
        $display("INIT HAPPENING AT TIME %5d", $time);
        init = 1;
        #1;
        init = 0;
        #1;

    endtask

    task dump_arf(int cycle);
        $display("ARF OUT AT CYCLE %5d AT TIME %5d===================", cycle, $time);
        for(int i = 0; i < `ARF_N_ENTRIES; i++) begin
            $display("ARF[%0d]: 0x%8h", i, arf_out_data[i]);
        end
        $display("END ARF OUT =======================================");
        $display();
    endtask

    task dump_main_mem(int cycle, addr_t start_addr, addr_t end_addr);
        addr_t addr;
        main_mem_block_addr_t block_addr;
        main_mem_block_offset_t block_offset;
        assign {block_addr, block_offset} = addr;
        $display("MAIN MEM OUT AT CYCLE %5d AT TIME %5d===================", cycle, $time);
        for (addr = start_addr; addr < end_addr; addr += 4) begin
            $display("MAIN_MEM[0x%8h]: 0x%8h", addr, main_mem_out_data[block_addr][8*block_offset+:32]);
        end
        $display("END MAIN MEM OUT =======================================");
        $display();
    endtask

    // task dump_mem_test(main_mem_block_addr_t block_addr);
    //     $display("MAIN_MEM[0x%8h]: 0x%8h", {i, j}, main_mem_out_data[i][8*j+:32]);
    // endtask

    task run_directed_testcases(int s_i);

        // reset, wait, then start testing
        // rst_aL = 0;
        // @(posedge clk);
        // #1
        // rst_aL = 1;
        // @(posedge clk);
        // #1;

        // MAIN LOOP
        // Cycles:
        // Fetch
        // Dispatch
        // Queues (IIQ, LSQ)
        // AGEX/ALU
        // D-cache/ALU wakeup/writeback ?

        $display("STARTING TEST SET %0d time: %6d", s_i, $time);
        fill_main_mem_and_start_read(s_i);

        // loop comes in clk is high
        cycle = 0;
        prev_PC = 0;
        curr_PC = test_programs[s_i].start_PC;
        while(test_programs[s_i].prog.exists(curr_PC)) begin

            // full cycle neg edge to pos edge with print dumps
            @(negedge clk);
            $display("*****| AT %5dns NEGEDGE |*****", $time);
            #1;
            if(FETCH_VERBOSE) fetch_negedge_dump(cycle);
            if(DISP_VERBOSE) dispatch_negedge_dump(cycle);


            @(posedge clk);
            $display("\n------| Cycle start: %4d |--------------------------------------------\n",cycle+1);
            $display("*****| AT %5dns POSEDGE |*****", $time);
            #1;
            if(_top._core._dispatch.retire) begin
                dump_arf(cycle);
            end
            if(FETCH_VERBOSE) fetch_posedge_dump(cycle);
            if(DISP_VERBOSE) dispatch_posedge_dump(cycle);


            // check outputs of all stages
            for(int stage = IFU_STAGE; stage < NUM_STAGES; stage++) begin
                // check_stage(s_i, stage);
            end

            prev_PC = curr_PC;
            curr_PC = _top._core._ifu.PC_wire;  // PC will have already been latched with the PC for next cycle
            cycle=cycle+1;
        end

        #1500; // let last instruction finish

    endtask

    // Task to display test results
    task display_test_results(int s_i, int stage);
        if (num_directed_tests_passed[s_i][stage] == num_directed_tests[s_i][stage]) begin
            $display("ALL %0d DIRECTED TESTS PASSED", num_directed_tests[s_i][stage]);
        end else begin
            // if (test_programs[s_i].num_instrs != num_directed_tests[s_i][stage])
            //     $display("NOT ENOUGH CASES TESTED (not all instructions reached): %0d<%0d", num_directed_tests[s_i][stage], test_programs[s_i].num_instrs);
            $display("SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed[s_i][stage], num_directed_tests[s_i][stage]);
        end
    endtask

    task directed_testsets();
        for(int i = 0; i < `NUM_SETS; i++) begin
            if(i != 1) begin  // skip test cases in this conditional
                build_testcases(i);
                $display("STARTING TEST SET BEFORE FUNCTION %0d", i);
                run_directed_testcases(i);
                for(int stage = 0; stage < 1/*NUM_STAGES*/; stage++) begin
                    display_test_results(i, stage);
                end
            end
        end
    endtask

    // Initial block to run testcases
    initial begin
        // repeat (1000) begin
        //     random_testcase();
        // end
        $display("STARTING TESTBENCH time: %6d", $time);
        $display("------| Cycle start: 0 |--------------------------------------------\n");
        // $monitor("%4t rob_enq_ctr: %6b rob_deq_ctr: %6b  next_enq_ctr: %6b next_deq_ctr: %6b\n",
        //     $time,
        //     _top._core._dispatch._rob.rob_mem.enq_ctr_r,
        //     _top._core._dispatch._rob.rob_mem.deq_ctr_r,
        //     _top._core._dispatch._rob.rob_mem.next_enq_ctr,
        //     _top._core._dispatch._rob.rob_mem.next_deq_ctr,
        // );

        // $monitor("%4t mem_ctrl_resp_valid: %b mem_ctrl_resp_block_data: %b\n",
        //     $time,
        //     _top._core._ifu.mem_ctrl_resp_valid,
        //     _top._core._ifu.mem_ctrl_resp_block_data
        // );
        directed_testsets();
        dump_arf(cycle);
        dump_main_mem(cycle, 32'h1018c - 64, 32'h1018c + 64);
        // [0x203400000004]
        // [0x203000000004]
        $finish;
    end


    initial begin
        // $monitor("%3t fetch_redirect_valid %b icache_miss: %b ififo_stall: %b PC_wire: %8h | pipeline_req_addr_offset_latched:%8h instr: %8h next_PC: %8h PC_mux_out: %8h\npipeline_req_valid: %b \nmem_ctrl_resp_valid: %b mem_ctrl_resp_block_data: %b\n",
        // $monitor("%3t retire: %1b (dst_v: %1b (alu_brcast_v: %1b  (iss_v: %1b)) is_exec: %1b not_br_mispred: %1b)retire_id: %1d retire_data: 0x%8h rob_ent_data: 0x%8h (exec_v: %1b alu_br_v: %1b alu_out: 0x%8h)
        // sel_main_adder_sum: %1b main_adder_sum: 0x%8h main_adder_op1: 0x%8h (is_r:%1b is_i:%1b src1:0x%8h is_lui:%1b ) main_adder_op2: 0x%8h (imm: 0x%8h is_sub:%1b src2: 0x%8h)
        // ififo_dispatch_data.instr: 0x%8h
        // rs1_retired: %b
        // arf_reg_data_src1: 0x%8h
        // disp_ready: %1b disp_valid: %1b
        // disp_data: %p
        // integer_issue.entries_ready: %b
        // integer_issue.scheduled_entry_idx_onehot: %b
        // integer_issue.ld_broadcast_rob_id: %b
        // integer_issue.alu_broadcast_rob_id: %b
        // integer_issue.scheduled_entry.src1_rob_id: %b
        // integer_issue.entries[1].src1_rob_id: %b
        // integer_issue.entries[0].src1_rob_id: %b
        // entries_src1_iiq_wakeup_ok: %b
        // entries_src1_alu_capture_ok: %b
        // entries_src1_ld_capture_ok: %b
        // integer_issue.entries_wr_en: %b
        // integer_issue.entries[1]: %p
        // integer_issue.entries[0]: %p
        // scheduled_entry: %p
        // iibuff_din: %p
        // sel_sll_out: %1b
        // sel_srl_out: %1b
        // sel_sra_out: %1b
        // sel_unsigned_cmp_lt: %1b
        // sel_signed_cmp_lt: %1b
        // sel_and_out: %1b
        // sel_or_out: %1b
        // sel_xor_out: %1b
        // sel_pc_plus_4: %1b
        // _rob.alu_wb_reg_data: 0x%8h
        // _rob.rob_mem.fifo_r[0].reg_data: %p

        // lsq_entries[0]: %p
        // lsu.enq_ctr: %b
        // lsu.deq_ctr: %b

        // lsu.actual_base_addr: %h

        // lsu.dcache.pipeline_req_valid: %b
        // lsu.dcache.pipeline_req_type: %s
        // lsu.dcache.pipeline_req_width: %s
        // lsu.dcache.pipeline_req_addr: %h
        // lsu.dcache.pipeline_req_wr_data: %h

        // lsu.dcache.data_array.csb0_reg: %b
        // lsu.dcache.data_array.web0_reg: %b
        // lsu.dcache.data_array.wmask_reg: %b
        // lsu.dcache.data_array.addr_reg: %h
        // lsu.dcache.data_array.din_reg: %h

        // lsu.dcache.mem_ctrl_req_valid: %b
        // lsu.dcache.mem_ctrl_req_type: %s
        // lsu.dcache.mem_ctrl_req_block_addr: %d
        // lsu.dcache.mem_ctrl_req_block_data: %h
        // lsu.dcache.mem_ctrl_req_ready: %b

        // _main_mem.req_pipeline: %p

        // \nmem_ctrl_resp_valid: %b mem_ctrl_resp_block_data: %b\n",
        //     $time,
        //     // _top._core._ifu.fetch_redirect_valid,
        //     // _top._core._ifu.icache_miss,
        //     // _top._core._ifu.IFIFO_stall,
        //     // _top._core._ifu.PC_wire,
        //     // _top._core._ifu.icache.pipeline_req_addr_offset_latched,
        //     // _top._core._ifu.pred_NPC.instr,
        //     // _top._core._ifu.next_PC,
        //     // _top._core._ifu.PC_mux_out,
        //     // _top._core._ifu.icache.pipeline_req_valid,
        //     _top._core._dispatch.retire,
        //     _top._core._dispatch._rob.retire_entry_data.dst_valid,
        //     _top._core.alu_broadcast_valid,
        //     _top._core._integer_issue.issue_valid,
        //     _top._core._dispatch._rob.retire_entry_data.is_executed,
        //     _top._core._dispatch._rob.not_br_mispred,
        //     _top._core._dispatch.retire_arf_id,
        //     _top._core._dispatch.retire_reg_data,
        //     _top._core._dispatch._rob.rob_mem.fifo_r[0][31:0],
        //     _top._core._integer_execute.execute_valid,
        //     _top._core._integer_execute.alu_broadcast_valid,
        //     _top._core._integer_execute.dst,

        //     _top._core._integer_execute.sel_main_adder_sum,
        //     _top._core._integer_execute.main_adder_sum,
        //     _top._core._integer_execute.main_adder_op1,
        //     _top._core._integer_execute.is_r_type,
        //     _top._core._integer_execute.is_i_type,
        //     _top._core._integer_execute.src1,
        //     _top._core._integer_execute.is_lui,
        //     _top._core._integer_execute.main_adder_op2,
        //     _top._core._integer_execute.imm,
        //     _top._core._integer_execute.is_sub,
        //     _top._core._integer_execute.src2,

        //     _top._core._dispatch.ififo_dispatch_data.instr,

        //     _top._core._dispatch.rs1_retired,
        //     _top._core._dispatch.arf_reg_data_src1,

        //     _top._core._integer_issue.dispatch_ready,
        //     _top._core._integer_issue.dispatch_valid,
        //     _top._core._integer_issue.dispatch_data,

        //     _top._core._integer_issue.entries_ready,
        //     _top._core._integer_issue.scheduled_entry_idx_onehot,

        //     _top._core._integer_issue.ld_broadcast_rob_id,
        //     _top._core._integer_issue.alu_broadcast_rob_id,
        //     _top._core._integer_issue.scheduled_entry.src1_rob_id,
        //     _top._core._integer_issue.entries[1].src1_rob_id,
        //     _top._core._integer_issue.entries[0].src1_rob_id,

        //     _top._core._integer_issue.entries_src1_iiq_wakeup_ok,
        //     _top._core._integer_issue.entries_src1_alu_capture_ok,
        //     _top._core._integer_issue.entries_src1_ld_capture_ok,
        //     _top._core._integer_issue.entries_wr_en,
        //     _top._core._integer_issue.entries[1],
        //     _top._core._integer_issue.entries[0],

        //     _top._core._integer_issue.scheduled_entry,
        //     _top._core._integer_issue.integer_issue_buffer.din,

        //     _top._core._integer_execute.sel_sll_out,
        //     _top._core._integer_execute.sel_srl_out,
        //     _top._core._integer_execute.sel_sra_out,
        //     _top._core._integer_execute.sel_unsigned_cmp_lt,
        //     _top._core._integer_execute.sel_signed_cmp_lt,
        //     _top._core._integer_execute.sel_and_out,
        //     _top._core._integer_execute.sel_or_out,
        //     _top._core._integer_execute.sel_xor_out,
        //     _top._core._integer_execute.sel_pc_plus_4,

        //     _top._core._dispatch._rob.alu_wb_reg_data,
        //     (rob_entry_t'(_top._core._dispatch._rob.rob_mem.fifo_r[0])),

        //     _top._core.lsu.lsq_entries[0],
        //     _top._core.lsu.enq_ctr,
        //     _top._core.lsu._lsq_simple.deq_ctr,

        //     _top._core.lsu.actual_base_addr,

        //     _top._core.lsu.dcache.pipeline_req_valid,
        //     _top._core.lsu.dcache.pipeline_req_type.name,
        //     _top._core.lsu.dcache.pipeline_req_width.name,
        //     _top._core.lsu.dcache.pipeline_req_addr,
        //     _top._core.lsu.dcache.pipeline_req_wr_data,

        //     _top._core.lsu.dcache.data_array.data_array.csb0_reg,
        //     _top._core.lsu.dcache.data_array.data_array.web0_reg,
        //     _top._core.lsu.dcache.data_array.data_array.wmask0_reg,
        //     _top._core.lsu.dcache.data_array.data_array.addr0_reg,
        //     _top._core.lsu.dcache.data_array.data_array.din0_reg,

        //     _top._core.lsu.dcache.mem_ctrl_req_valid,
        //     _top._core.lsu.dcache.mem_ctrl_req_type,
        //     _top._core.lsu.dcache.mem_ctrl_req_block_addr,
        //     _top._core.lsu.dcache.mem_ctrl_req_block_data,
        //     _top._core.lsu.dcache.mem_ctrl_req_ready,

        //     _top._main_mem.req_pipeline,

        //     _top._core._ifu.mem_ctrl_resp_valid,
        //     _top._core._ifu.mem_ctrl_resp_block_data
        // );
        // #400;
        // $finish;
    end

    always @(negedge clk) begin #1 $display();
        $display("%0t lsu.dcache.pipeline_req_valid: %b", $time, _top._core.lsu._dcache.pipeline_req_valid);
        $display("%0t lsu.dcache.pipeline_req_type: %s", $time, _top._core.lsu._dcache.pipeline_req_type.name);
        $display("%0t lsu.dcache.pipeline_req_width: %s", $time, _top._core.lsu._dcache.pipeline_req_width.name);
        $display("%0t lsu.dcache.pipeline_req_addr: %h", $time, _top._core.lsu._dcache.pipeline_req_addr);
        $display("%0t lsu.dcache.pipeline_req_wr_data: %h\n", $time, _top._core.lsu._dcache.pipeline_req_wr_data);

        $display("%0t lsu.dcache.pipeline_resp_valid: %h\n", $time, _top._core.lsu._dcache.pipeline_resp_valid);

        $display("%0t lsu.dcache.pipeline_req_valid: %h", $time, _top._core.lsu._dcache.pipeline_req_valid);
        $display("%0t lsu.dcache.tag_array_hit: %h", $time, _top._core.lsu._dcache.tag_array_hit);

        // $display("%0t lsu.dcache.mem_ctrl_req_valid: %b", $time, _top._core.lsu.dcache.mem_ctrl_req_valid);
        // $display("%0t lsu.dcache.mem_ctrl_req_type: %s", $time, _top._core.lsu.dcache.mem_ctrl_req_type.name);
        // $display("%0t lsu.dcache.mem_ctrl_req_block_addr: %h", $time, _top._core.lsu.dcache.mem_ctrl_req_block_addr);
        // $display("%0t lsu.dcache.data_array_dout: %p", $time, _top._core.lsu.dcache.data_array_dout);
        // $display("%0t lsu.dcache.mem_ctrl_req_block_data: %h", $time, _top._core.lsu.dcache.mem_ctrl_req_block_data);
        // $display("%0t lsu.dcache.mem_ctrl_req_ready: %b\n", $time, _top._core.lsu.dcache.mem_ctrl_req_ready);

        // $display("%0t req_pipeline: %p\n", $time, _top._main_mem.req_pipeline);

        // $display("%0t lsu.dcache.mem_ctrl_resp_valid: %b", $time, _top._core.lsu.dcache.mem_ctrl_resp_valid);
        // $display("%0t lsu.dcache.mem_ctrl_resp_block_data: %h\n", $time, _top._core.lsu.dcache.mem_ctrl_resp_block_data);

        $display("%0t lsu.dcache.pipeline_resp_valid: %b", $time, _top._core.lsu._dcache.pipeline_resp_valid);
        $display("%0t lsu.dcache.pipeline_resp_rd_data: %h\n", $time, _top._core.lsu._dcache.pipeline_resp_rd_data);

        $display("%0t rob_entries[2:0]: %p", $time, _top._core._dispatch._rob.rob_state[2:0]);
        $display("%0t rob_ptr: %b", $time, _top._core._dispatch._rob.retire_rob_id);
        $display("%0t lsq_entries[1:0]: %p", $time, _top._core.lsu.lsq_entries[1:0]);
        $display("%0t lsq_enq_ctr: %b", $time, _top._core.lsu._lsq_simple.enq_ctr);
        $display("%0t lsq_deq_ctr: %b", $time, _top._core.lsu._lsq_simple.deq_ctr);
        $display("%0t ld_broadcast_reg_data: %h", $time, _top._core._dispatch.ld_broadcast_reg_data);
    end
    always @(negedge clk) begin #1 $display();
        // $display("%0t rob_entries[2:0]: %p", $time, _top._core._dispatch._rob.rob_state[2:0]);
        // $display("%0t rob_ptr: %b", $time, _top._core._dispatch._rob.retire_rob_id);
        // $display("%0t lsq_entries[1:0]: %p", $time, _top._core.lsu.lsq_entries[1:0]);
        // $display("%0t lsq_enq_ctr: %b", $time, _top._core.lsu._lsq_simple.enq_ctr);
        // $display("%0t lsq_deq_ctr: %b", $time, _top._core.lsu._lsq_simple.deq_ctr);
        // $display("%0t ld_broadcast_reg_data: %b", $time, _top._core._dispatch.ld_broadcast_reg_data);
    end

    always @(posedge clk) begin #1 $display();

    end

    always @(posedge clk) begin #4 $display();

    end

    always @(negedge clk) begin #4 $display();

    end


endmodule

// pipeline write addr:         0001 0000 0001 1010 0100
// main mem write block addr:      1 0000 0001 1010 0