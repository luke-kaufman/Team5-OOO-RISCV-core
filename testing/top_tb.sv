`include "misc/global_defs.svh"
`include "top/core.sv"
`include "top/main_mem.sv"
module top_tb #(
    parameter N_RANDOM_TESTS = 100
);
    enum { 
        IFU_STAGE,
        DISPATCH_STAGE,
        INTEGER_STAGE,
        LSU_STAGE,
        NUM_STAGES 
    } STAGE
    `define NUM_SETS 2  // number of test sets
    
    // classes for wrapping test data
    class ProgramWrapper;
        int prog[int];  // actual map/dict of program
        int start_PC;
        int num_instrs;
        int prog_addrs[500]; // 100 aribtrary max number of instructions
    endclass
    class CoreOutWrapper;
        // something else here ?
        IFUOutWrapper ifu_out;
        DispatchOutWrapper dispatch_out;
        // IntegerOutWrapper integer_out;
        // LSUOutWrapper lsu_out;
    endclass  
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

    bit VERBOSE = 0;
    int cycle;
    int curr_PC;
    int num_directed_tests[`NUM_SETS][NUM_STAGES];
    int num_directed_tests_passed[`NUM_SETS][NUM_STAGES];
    ProgramWrapper test_programs[`NUM_SETS];
    IFUOutWrapper test_ifu_outs[`NUM_SETS];

    // clock generation & other external core inputs
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        forever #HALF_PERIOD clk = ~clk;
    end
    /*input*/ bit clk=1;
    /*input*/ reg rst_aL=1;
    /*input*/ bit csb0_in=1;

    // ARF OUT from core
    wire [ARF_N_ENTRIES-1:0][REG_DATA_WIDTH-1:0] arf_out_data;

    // RESPONSE FROM MAIN MEMORY TO CORE
    wire                               mem2core_valid;
    wire                               mem2core_lsu_aL_ifu_aH;
    wire [`ADDR_WIDTH-1:0]             mem2core_addr;
    wire [2:0]                         mem2core_data_size;
    wire [`ICACHE_DATA_BLOCK_SIZE-1:0] mem2core_data;
    
    // REQUEST FROM CORE TO MAIN MEMORY
    wire                   core2mem_valid;
    wire [`ADDR_WIDTH-1:0] core2mem_addr;
    wire [2:0]             core2mem_data_size; // {Word, Halfword, Byte}
    wire [`WORD_WIDTH-1:0] core2mem_data;

    // CORE INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    core core_dut (
        .clk(clk), // input wire 
        .rst_aL(rst_aL), // input wire 
        .csb0_in(csb0_in), // input wire 
        // Main memory interaction for both LOADS and ICACHE (rd only)
        .recv_main_mem_valid(mem2core_valid), // input wire 
        .recv_main_mem_lsu_aL_ifu_aH(mem2core_lsu_aL_ifu_aH),  // if main mem data is meant for LSU or IFU
        .recv_main_mem_addr(mem2core_addr), // input wire
        .recv_size_main_mem(mem2core_data_size), // {Word, Halfword, Byte} 
        .recv_main_mem_data(mem2core_data), // input wire 
        // Main memory interaction only for STORES (wr only)
        .send_en_main_mem(core2mem_valid), // output wire 
        .send_main_mem_addr(core2mem_addr), // output wire 
        .send_size_main_mem(core2mem_data_size), // output wire 
        .send_main_mem_data(core2mem_data) // output wire 

        // ARF OUT to check architectural state

    );
    // END CORE INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    // MEMORY INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    main_mem main_mem_dut (
        .clk(clk), // input wire 
        .rst_aL(rst_aL), // input wire 
        // FROM CORE TO MAIN MEM (RECEIVE)
        .recv_core_valid(core2mem_valid), // input wire 
        .recv_core_addr(core2mem_addr), // input wire
        .recv_size_core(core2mem_data_size), // {$block, Word, Halfword, Byte} 
        .recv_core_data(core2mem_data), // input wire 
        // FROM MAIN MEM TO CORE (SEND)
        .send_en_core(mem2core_valid), // output wire 
        .send_core_lsu_aL_ifu_aH(mem2core_lsu_aL_ifu_aH), // output wire 
        .send_core_addr(mem2core_addr),  // if main mem data is meant for LSU or IFU
        .send_size_core(mem2core_data_size), // output wire 
        .send_core_data(mem2core_data) // output wire 
    );
    // END MEMORY INSTANTIATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    task build_testcases(int s_i);
        case (s_i)
            0 : begin // TEST SET 1: just instructions
                ififo_dispatch_ready = 1;
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
                ififo_dispatch_ready = 1;
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
        $display("FETCH: Set accessed: %6b", ifu_dut.icache.tag_arr.addr0_reg);
        $display("FETCH: IFIFO_enq_data.instr: 0x%8h", ifu_dut.IFIFO_enq_data.instr);
        $display("FETCH: IFIFO_enq_data.pc: 0x%8h", ifu_dut.IFIFO_enq_data.pc);
        $display("FETCH: IFIFO_enq_data.is_cond_br: %1b" , ifu_dut.IFIFO_enq_data.is_cond_br);
        $display("FETCH: IFIFO_enq_data.br_dir_pred: %1b" , ifu_dut.IFIFO_enq_data.br_dir_pred);
        $display("FETCH: IFIFO_enq_data.br_target_pred: 0x%8h" , ifu_dut.IFIFO_enq_data.br_target_pred);
        $display();
        $display("FETCH: enq_ready %1b", ifu_dut.IFIFO_enq_ready); // output - can fifo receive data?
        $display("FETCH: enq_valid %1b", ifu_dut.icache_hit);      // input - enqueue if icache hit
        $display("FETCH: deq_ready %1b", ifu_dut.ififo_dispatch_ready);  // input - interface from dispatch
        $display("FETCH: deq_valid %1b", ifu_dut.ififo_dispatch_valid);     // output - interface to dispatch
        $display("FETCH: deq_data 0x%8h", ifu_dut.ififo_dispatch_data); // output - dispatched instr
    endtask
    task fetch_posedge_dump(int cycle);
        $display();
        $display("*****| AT %5dns POSEDGE |*****", $time);
        $display("IFIFO STALL %1b ICACHE MISS %1b", ifu_dut.IFIFO_stall, ifu_dut.icache_miss);
        $display("CURR_PC 0x%8h", curr_PC);
        $display("LATCHED SRAM ADDR 0x%8h at time %6d", ifu_dut.PC_mux.out,$time);
        $display("recovery_PC_valid %1b, stall_gate_ZN %1b", ifu_dut.recovery_PC_valid, ifu_dut.stall_gate.ZN);
    endtask

    task check_stage(int stage);
        case(stage)
            IFU_STAGE: begin
                if(ifu_dut.ififo_dispatch_valid) begin
                    num_directed_tests[s_i][IFU_STAGE]++;
                    if(ifu_dut.ififo_dispatch_valid && ifu_dut.ififo_dispatch_data == test_ifu_outs[s_i].ifu_out[curr_PC]) begin
                        num_directed_tests_passed[s_i][IFU_STAGE]++;
                    end
                    else begin
                        $display("FETCH: FAILED CASE:");
                        $display("FETCH: ifu_dut.ififo_dispatch_valid %1b", ifu_dut.ififo_dispatch_valid);
                        $display("FETCH: ifu_dut.ififo_dispatch_data.instr 0x%8h EXPECTED: 0x%8h", ifu_dut.ififo_dispatch_data[97:66], test_ifu_outs[s_i].ifu_out[curr_PC][97:66]);
                        $display("FETCH: ifu_dut.ififo_dispatch_data.pc 0x%8h EXPECTED: 0x%8h", ifu_dut.ififo_dispatch_data[65:34], test_ifu_outs[s_i].ifu_out[curr_PC][65:34]);
                        $display("FETCH: ifu_dut.ififo_dispatch_data.is_cond_br %1b EXPECTED: %1b", ifu_dut.ififo_dispatch_data[33], test_ifu_outs[s_i].ifu_out[curr_PC][33]);
                        $display("FETCH: ifu_dut.ififo_dispatch_data.br_dir_pred %1b EXPECTED: %1b", ifu_dut.ififo_dispatch_data[32], test_ifu_outs[s_i].ifu_out[curr_PC][32]);
                        $display("FETCH: ifu_dut.ififo_dispatch_data.br_target_pred 0x%8h EXPECTED: 0x%8h", ifu_dut.ififo_dispatch_data[31:0], test_ifu_outs[s_i].ifu_out[curr_PC][31:0]);       
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
    task fill_icache_and_start_read();
        // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        $display("Filling icache with instructions:");
        for(int i=0; i<test_programs[s_i].num_instrs; i=i+1) begin
            // force PC to instruction location thru recovery PC logic
            if(i==0 && (test_programs[s_i].prog_addrs[i] & 32'h00000004)) begin
                recv_main_mem_data = {
                    test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]], 
                    32'h00000000
                };
            end
            else begin
                if (i == test_programs[s_i].num_instrs-1) begin
                    recv_main_mem_data = {
                        32'h00000000,
                        test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]]
                    };
                end
                else begin
                    recv_main_mem_data = {
                        test_programs[s_i].prog[test_programs[s_i].prog_addrs[i+1]],
                        test_programs[s_i].prog[test_programs[s_i].prog_addrs[i]]
                    };
                end
                skip = 1;
            end

            // latch and write instructions
            $display("PC=0x%32b (%8h)", test_programs[s_i].prog_addrs[i], test_programs[s_i].prog_addrs[i]);
            recovery_PC = test_programs[s_i].prog_addrs[i];
            recovery_PC_valid = 1;
            recv_main_mem_valid = 1;
            csb0_in = 0;  // turn on icache
            @(posedge clk);  // latch into sram and PC

            @(negedge clk);  // write at negedge1
            #1;
            $display("\n");
            recv_main_mem_valid = 0;  // turn off we
            csb0_in = 1;  // turn off icache
            
            if (skip) begin
                skip = 0;
                i = i + 1;  // so we skip next iteration
            end
        end

        // force PC to instruction location thru recovery PC logic
        recovery_PC = test_programs[s_i].start_PC;
        recovery_PC_valid = 1;
        csb0_in = 0;
        @(posedge clk); // pc latched into PC reg and SRAM latches
        $display("START READING INSRUCTIONS FROM ICACHE TIME: %6d", $time);
        #1;
        recovery_PC_valid = 0;
        recv_main_mem_valid = 0;  // stop writing to icache
        // dispatch ready handled in testset build_testcases
    endtask
    
    task run_directed_testcases(int s_i);
        
        // reset, wait, then start testing
        rst_aL = 0;
        @(posedge clk);
        rst_aL = 1;
        @(posedge clk);
        @(negedge clk);
        #1;

        fill_icache_and_start_read();


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
                check_stage(stage);
            end
            
            curr_PC = ifu_dut.PC_wire;  // PC will have already been latched with the PC for next cycle
            cycle=cycle+1;
        end
    endtask
   
    // Task to display test results
    task display_test_results(int s_i, STAGE stage);
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
            if(i != 0) begin  // skip test cases in this conditional
                build_testcases(i);
                run_directed_testcases(i);
                for(int stage = 0; stage < NUM_STAGES; stage++) begin
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
        directed_testsets();
    end
endmodule