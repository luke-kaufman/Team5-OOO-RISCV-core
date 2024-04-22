`include "misc/global_defs.svh"
`include "top/top.sv"

`define NUM_SETS 2  // number of test sets

module top_tb #(
    parameter N_RANDOM_TESTS = 100
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

    bit VERBOSE = 1;
    int cycle;
    int curr_PC;
    int num_directed_tests[`NUM_SETS][NUM_STAGES];
    int num_directed_tests_passed[`NUM_SETS][NUM_STAGES];
    ProgramWrapper test_programs[`NUM_SETS];
    IFUOutWrapper test_ifu_outs[`NUM_SETS];

    /*input*/ bit clk=1;
    /*input*/ reg rst_aL=1;
    /*input*/ bit csb0_in=1;
    /*input*/ bit init=0;

    bit testing = 1;
    bit test_icache_fill_valid = 0;
    addr_t test_icache_fill_PC = 0;
    block_data_t test_icache_fill_block = 0;

    // clock generation & other external core inputs
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        forever #HALF_PERIOD clk = ~clk;
    end

    block_data_t main_mem_init [`MAIN_MEM_N_BLOCKS];
    // ARF OUT from core
    wire [`ARF_N_ENTRIES-1:0][`REG_DATA_WIDTH-1:0] arf_out_data;

    // TOP INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    top _top(
        .clk(clk),
        .rst_aL(rst_aL),
        .init(init),
        .testing(testing),  //input wire 
        .test_icache_fill_valid(test_icache_fill_valid),  //input wire 
        .test_icache_fill_PC(test_icache_fill_PC),  //input addr_t 
        .test_icache_fill_block(test_icache_fill_block),  //input block_data_t 

        .init_main_mem_state(main_mem_init),  // input block_data_t [`MAIN_MEM_N_BLOCKS]
        .ARF_OUT(arf_out_data) // output [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] 
    );
    // END TOP INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    task build_testcases(int s_i);
        case (s_i)
            0 : begin // TEST SET 1: just instructions
                // ififo_dispatch_ready = 1;
                test_programs[s_i] = new();
                test_programs[s_i].num_instrs=22;
                test_programs[s_i].start_PC=32'h1018c;
                test_programs[s_i].prog[32'h1018c]=32'hfe010113; // add sp,sp,-32        
                test_programs[s_i].prog[32'h10190]=32'h00812e23; // sw s0,28(sp)        
                test_programs[s_i].prog[32'h10194]=32'h00912c23; // sw s1,24(sp)        
                test_programs[s_i].prog[32'h10198]=32'h02010413; // add s0,sp,32        
                test_programs[s_i].prog[32'h1019c]=32'hfea42623; // sw a0,-20(s0)        
                test_programs[s_i].prog[32'h101a0]=32'hfeb42423; // sw a1,-24(s0)        
                test_programs[s_i].prog[32'h101a4]=32'h00f00493; // li s1,15        
                test_programs[s_i].prog[32'h101a8]=32'h01348493; // add s1,s1,19        
                test_programs[s_i].prog[32'h101ac]=32'hffc48493; // add s1,s1,-4        
                test_programs[s_i].prog[32'h101b0]=32'h00048713; // mv a4,s1        
                test_programs[s_i].prog[32'h101b4]=32'h800007b7; // lui a5,0x80000        
                test_programs[s_i].prog[32'h101b8]=32'h00f747b3; // xor a5,a4,a5        
                test_programs[s_i].prog[32'h101bc]=32'h00078493; // mv s1,a5        
                test_programs[s_i].prog[32'h101c0]=32'h800007b7; // lui a5,0x80000        
                test_programs[s_i].prog[32'h101c4]=32'hfff78793; // add a5,a5,-1 # 7fffffff <__BSS_END__+0x7ffed77f>     
                test_programs[s_i].prog[32'h101c8]=32'h00f4f4b3; // and s1,s1,a5        
                test_programs[s_i].prog[32'h101cc]=32'h00048793; // mv a5,s1        
                test_programs[s_i].prog[32'h101d0]=32'h00078513; // mv a0,a5        
                test_programs[s_i].prog[32'h101d4]=32'h01c12403; // lw s0,28(sp)        
                test_programs[s_i].prog[32'h101d8]=32'h01812483; // lw s1,24(sp)        
                test_programs[s_i].prog[32'h101dc]=32'h02010113; // add sp,sp,32        
                test_programs[s_i].prog[32'h101e0]=32'h00008067; // ret 
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
            1 : begin // TEST SET 2: BREAKS BECASUE DYNAM FOR LOOP - Correctly predicted branches 
                // ififo_dispatch_ready = 1;
                test_programs[s_i] = new();
                test_programs[s_i].num_instrs=27;
                test_programs[s_i].start_PC=32'h1018c;
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
        $display("\nFETCH: -| Cycle: %4d |--------------------------------------------\n",cycle);
        $display("FETCH: *****| AT %5dns NEGEDGE |*****", $time);
        $display("FETCH: FIFO ENTRY FOR THIS INSTRUCTION:");
        $display("FETCH: Set accessed: %6b", _top._core._ifu.icache.tag_array.addr0_reg);
        $display("FETCH: IFIFO_enq_data.instr: 0x%8h", _top._core._ifu.IFIFO_enq_data.instr);
        $display("FETCH: IFIFO_enq_data.pc: 0x%8h", _top._core._ifu.IFIFO_enq_data.pc);
        $display("FETCH: IFIFO_enq_data.is_cond_br: %1b" , _top._core._ifu.IFIFO_enq_data.is_cond_br);
        $display("FETCH: IFIFO_enq_data.br_dir_pred: %1b" , _top._core._ifu.IFIFO_enq_data.br_dir_pred);
        $display("FETCH: IFIFO_enq_data.br_target_pred: 0x%8h" , _top._core._ifu.IFIFO_enq_data.br_target_pred);
        $display();
        $display("FETCH: enq_ready %1b", _top._core._ifu.IFIFO_enq_ready); // output - can fifo receive data?
        $display("FETCH: enq_valid %1b", _top._core._ifu.icache_hit);      // input - enqueue if icache hit
        $display("FETCH: deq_ready %1b", _top._core._ifu.ififo_dispatch_ready);  // input - interface from dispatch
        $display("FETCH: deq_valid %1b", _top._core._ifu.ififo_dispatch_valid);     // output - interface to dispatch
        $display("FETCH: deq_data 0x%8h", _top._core._ifu.ififo_dispatch_data); // output - dispatched instr
    endtask
    task fetch_posedge_dump(int cycle);
        $display();
        $display("*****| AT %5dns POSEDGE |*****", $time);
        $display("IFIFO STALL %1b ICACHE MISS %1b", _top._core._ifu.IFIFO_stall, _top._core._ifu.icache_miss);
        $display("CURR_PC 0x%8h", curr_PC);
        $display("LATCHED SRAM ADDR 0x%8h at time %6d", _top._core._ifu.PC_mux.out,$time);
        $display("fetch_redirect_valid %1b, stall_gate_ZN %1b", _top._core._ifu.fetch_redirect_valid, _top._core._ifu.stall_gate.ZN);    
    endtask

    task check_stage(int s_i, int stage);
        case(stage)
            IFU_STAGE: begin
                if(_top._core._ifu.ififo_dispatch_valid) begin
                    num_directed_tests[s_i][IFU_STAGE]++;
                    if(_top._core._ifu.ififo_dispatch_valid && _top._core._ifu.ififo_dispatch_data == test_ifu_outs[s_i].ifu_out[curr_PC]) begin
                        num_directed_tests_passed[s_i][IFU_STAGE]++;
                    end
                    else begin
                        $display("FETCH: FAILED CASE:");
                        $display("FETCH: _top._core._ifu.ififo_dispatch_valid %1b", _top._core._ifu.ififo_dispatch_valid);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.instr 0x%8h EXPECTED: 0x%8h", _top._core._ifu.ififo_dispatch_data[97:66], test_ifu_outs[s_i].ifu_out[curr_PC][97:66]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.pc 0x%8h EXPECTED: 0x%8h", _top._core._ifu.ififo_dispatch_data[65:34], test_ifu_outs[s_i].ifu_out[curr_PC][65:34]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.is_cond_br %1b EXPECTED: %1b", _top._core._ifu.ififo_dispatch_data[33], test_ifu_outs[s_i].ifu_out[curr_PC][33]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.br_dir_pred %1b EXPECTED: %1b", _top._core._ifu.ififo_dispatch_data[32], test_ifu_outs[s_i].ifu_out[curr_PC][32]);
                        $display("FETCH: _top._core._ifu.ififo_dispatch_data.br_target_pred 0x%8h EXPECTED: 0x%8h", _top._core._ifu.ififo_dispatch_data[31:0], test_ifu_outs[s_i].ifu_out[curr_PC][31:0]);       
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
    task fill_icache_and_start_read(int s_i);
        // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        $display("Filling icache with instructions:");
        for(int i=0; i<test_programs[s_i].num_instrs; i=i+1) begin
            // force PC to instruction location thru recovery PC logic
            if(i==0 && (test_programs[s_i].prog_addrs[i] & 32'h00000004)) begin
                test_icache_fill_block = {
                    test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]], 
                    32'h00000000
                };
            end
            else begin
                if (i == test_programs[s_i].num_instrs-1) begin
                    test_icache_fill_block = {
                        32'h00000000,
                        test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]]
                    };
                end
                else begin
                    test_icache_fill_block = {
                        test_programs[s_i].prog[test_programs[s_i].prog_addrs[i+1]],
                        test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]]
                    };
                end
                skip = 1;
            end

            // latch and write instructions
            $display("PC=0x%32b (%8h)", test_programs[s_i].prog_addrs[i], test_programs[s_i].prog_addrs[i]);
            test_icache_fill_PC = test_programs[s_i].prog_addrs[i];
            test_icache_fill_valid = 1;
            #1;
            $display("_top._core._ifu.icache.mem_ctrl_resp_valid: %1b", _top._core._ifu.icache.mem_ctrl_resp_valid);
            $display("_top._core._ifu.icache.mem_ctrl_resp_block_data: 0x%8h", _top._core._ifu.icache.mem_ctrl_resp_block_data);
            $display("_top._core._ifu.icache.mem_ctrl_req_ready: %1b", _top._core._ifu.icache.mem_ctrl_req_ready);
            $display("PC_mux_out 0x%8h", _top._core._ifu.PC_mux_out);
            $display("LATCHED SRAM ADDR 0x%8h at time %6d", _top._core._ifu.PC_mux.out,$time);
            $display("fetch_redirect_valid %1b, stall_gate_ZN %1b", _top._core._ifu.fetch_redirect_valid, _top._core._ifu.stall_gate.ZN);
            $display("icache miss: %1b, Ififo stall: %1b", _top._core._ifu.icache_miss, _top._core._ifu.IFIFO_stall);
            $display("pipeline_resp_valid: pipeline_req_valid_latched: %1b, ~pipeline_resp_was_valid: %1b, tag_array_hit: %1b", _top._core._ifu.icache.pipeline_req_valid_latched, _top._core._ifu.icache.pipeline_resp_was_valid, _top._core._ifu.icache.tag_array_hit);
            $display("tag_array_dout.way0_valid: %1b, tag_array_dout.way0_tag: 0x%4h, pipeline_req_addr_tag_latched: 0x%4h", _top._core._ifu.icache.tag_array_dout.way0_valid, _top._core._ifu.icache.tag_array_dout.way0_tag, _top._core._ifu.icache.pipeline_req_addr_tag_latched);
            $display("pipeline_resp_was_valid: %1b, pipeline_resp_valid: %1b", _top._core._ifu.icache.pipeline_resp_was_valid, _top._core._ifu.icache.pipeline_resp_valid);
            // csb0_in = 0;  // turn on icache
            @(posedge clk);  // latch into sram and PC

            @(negedge clk);  // write at negedge1
            #1;
            $display("\n");
            test_icache_fill_valid = 1;  // turn off we
            // csb0_in = 1;  // turn off icache
            
            if (skip) begin
                skip = 0;
                i = i + 1;  // so we skip next iteration
            end
        end

        // force PC to instruction location thru recovery PC logic
        test_icache_fill_PC = test_programs[s_i].start_PC;
        test_icache_fill_valid = 1;
        csb0_in = 0;
        @(posedge clk); // pc latched into PC reg and SRAM latches
        $display("START READING INSRUCTIONS FROM ICACHE TIME: %6d", $time);
        #1;
        test_icache_fill_valid = 1;
        // dispatch ready handled in testset build_testcases
    endtask
    
    task run_directed_testcases(int s_i);
        
        // reset, wait, then start testing
        rst_aL = 0;
        @(posedge clk);
        #1
        rst_aL = 1;
        init = 1;
        @(posedge clk);
        #1;
        init = 0;
        
        $display("STARTING TEST SET %0d time: %6d", s_i, $time);
        fill_icache_and_start_read(s_i);

        // MAIN LOOP
        // Cycles:
        // Fetch
        // Dispatch
        // Queues (IIQ, LSQ)
        // AGEX/ALU
        // D-cache/ALU wakeup/writeback ?

        // loop comes in clk is high
        cycle = 0;
        curr_PC = test_programs[s_i].start_PC;
        while(test_programs[s_i].prog.exists(curr_PC)) begin
            
            // full cycle neg edge to pos edge with print dumps
            @(negedge clk); 
            #1;
            if(VERBOSE) begin
                fetch_negedge_dump(cycle);
            end
            @(posedge clk);
            #1;
            if(VERBOSE) begin
                fetch_posedge_dump(cycle);
            end

            // check outputs of all stages
            for(int stage = IFU_STAGE; stage < NUM_STAGES; stage++) begin
                check_stage(s_i, stage);
            end
            
            curr_PC = _top._core._ifu.PC_wire;  // PC will have already been latched with the PC for next cycle
            cycle=cycle+1;
        end
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
        $finish;
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
        directed_testsets();
    end
endmodule