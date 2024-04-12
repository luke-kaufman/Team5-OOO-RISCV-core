`include "frontend/fetch/ifu.v"
// `include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"

module ifu_tb #(
    parameter N_RANDOM_TESTS = 100
);
    /*input*/ bit clk=1;
    /*input*/ reg rst_aL=1;
    /*input*/ reg [`ADDR_WIDTH-1:0] recovery_PC=0;
    /*input*/ reg recovery_PC_valid=0;
    /*input*/ reg backend_stall=0;
    /*input*/ reg [`ICACHE_DATA_BLOCK_SIZE-1:0] dram_response=0;
    /*input*/ reg dram_response_valid=0;

    /*input*/ bit csb0_in=1;

    // INTERFACE TO RENAME
    /*input*/ reg dispatch_ready=0;
    // /*output*/ reg instr_valid;
    // /*output*/ reg [INSTR_WIDTH-1:0] instr_data;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        forever #HALF_PERIOD clk = ~clk;
    end

    // design under test
    ifu dut (
        .clk(clk),
        .rst_aL(rst_aL),
        .recovery_PC(recovery_PC),
        .recovery_PC_valid(recovery_PC_valid),
        .backend_stall(backend_stall),
        .dram_response(dram_response),
        .dram_response_valid(dram_response_valid),
        .dispatch_ready(dispatch_ready),
        .csb0_in(csb0_in)
    );

    // int num_random_tests_passed = 0;
    // int num_random_tests = 0;
    `define NUM_SETS 1  // number of test sets
    int NUM_INSTRS[`NUM_SETS];
    // 22-6 is max # of instrs for tests set
    initial begin
        for (int i = 0; i < `NUM_SETS; i = i + 1) begin
            NUM_INSTRS[i] = 22 - 6;
        end
    end
    int instr_locs[`NUM_SETS][22-6];
    int instr_data[`NUM_SETS][22-6];
    ififo_entry_t instr_out[`NUM_SETS][22-6];
    int num_directed_tests[`NUM_SETS];
    int num_directed_tests_passed[`NUM_SETS];

    task build_testcases(int s_i);
        case (s_i)
            0 : begin // TEST SET 1
                // program to load ****
                instr_locs[s_i][0]=32'h1018c; instr_data[s_i][0]=32'hfe010113; // add sp,sp,-32        
                instr_locs[s_i][1]=32'h10190; instr_data[s_i][1]=32'h02010413; // add s0,sp,32v
                instr_locs[s_i][2]=32'h10194; instr_data[s_i][2]=32'h00f00493; // li s1,15        
                instr_locs[s_i][3]=32'h10198; instr_data[s_i][3]=32'h01348493; // add s1,s1,19                
                instr_locs[s_i][4]=32'h1019c; instr_data[s_i][4]=32'hffc48493; // add s1,s1,-4        
                instr_locs[s_i][5]=32'h101a0; instr_data[s_i][5]=32'h00048713; // mv a4,s1        
                instr_locs[s_i][6]=32'h101a4;  instr_data[s_i][6]=32'h800007b7; // lui a5,0x80000        
                instr_locs[s_i][7]=32'h101a8;  instr_data[s_i][7]=32'h00f747b3; // xor a5,a4,a5        
                instr_locs[s_i][8]=32'h101ac;  instr_data[s_i][8]=32'h00078493; // mv s1,a5        
                instr_locs[s_i][9]=32'h101b0;  instr_data[s_i][9]=32'h800007b7; // lui a5,0x80000        
                instr_locs[s_i][10]=32'h101b4; instr_data[s_i][10]=32'hfff78793; // add a5,a5,-1 # 7fffffff <__BSS_END__+0x7ffed77f>     
                instr_locs[s_i][11]=32'h101b8; instr_data[s_i][11]=32'h00f4f4b3; // and s1,s1,a5        
                instr_locs[s_i][12]=32'h101bc; instr_data[s_i][12]=32'h00048793; // mv a5,s1        
                instr_locs[s_i][13]=32'h101c0; instr_data[s_i][13]=32'h00078513; // mv a0,a5        
                instr_locs[s_i][14]=32'h101c4; instr_data[s_i][14]=32'h02010113; // add sp,sp,32        
                instr_locs[s_i][15]=32'h101c8; instr_data[s_i][15]=32'h00008067; // ret           

                // construct output to check against
                for(int i = 0; i < NUM_INSTRS[s_i]; i++) begin
                    instr_out[s_i][i].instr = instr_data[s_i][i];
                    instr_out[s_i][i].pc = instr_locs[s_i][i];
                    instr_out[s_i][i].is_cond_br = 0;
                    instr_out[s_i][i].br_dir_pred = 0;
                    instr_out[s_i][i].br_target_pred = instr_locs[s_i][i] + 4;
                end
            end 
            // default: 
        endcase 
    endtask

    task run_directed_testcases(int s_i);
        
        // reset, wait, then start testing
        rst_aL = 0;
        @(posedge clk);
        rst_aL = 1;
        @(posedge clk);
        @(negedge clk);
        #1;

         // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        $display("Filling icache with instructions:");
        for(int i=0; i<NUM_INSTRS[s_i]; i=i+1) begin
            // force PC to instruction location thru recovery PC logic
            // and put program into icache
            if(i==0 && (instr_locs[s_i][0] & 32'h00000004)) begin
                dram_response = {instr_data[s_i][i], 32'h00000000};
            end
            else begin
                dram_response = {instr_data[s_i][i+1],instr_data[s_i][i]};
                i = i + 1;
            end
            $display("PC=0x%32b (%8h)", instr_locs[s_i][i], instr_locs[s_i][i]);
            recovery_PC = instr_locs[s_i][i];
            recovery_PC_valid = 1;
            dram_response_valid = 1;
            csb0_in = 0;  // turn on icache
            @(posedge clk);  // latch into sram and PC

            @(negedge clk);  // write at negedge1
            #1;
            $display("\n");
            dram_response_valid = 0;  // turn off we
            csb0_in = 1;  // turn off icache
        end

        // force PC to instruction location thru recovery PC logic
        recovery_PC = instr_locs[s_i][0];
        recovery_PC_valid = 1;
        csb0_in = 0;
        @(posedge clk); // pc latched into PC reg and SRAM latches
        $display("START READING INSRUCTIONS FROM ICACHE TIME: %6d", $time);
        #1;
        recovery_PC_valid = 0;
        dispatch_ready = 1;  // so that we can get IFU output
        dram_response_valid = 0;  // stop writing to icache

        // loop comes in clk is high
        for(int i=0; i<NUM_INSTRS[s_i]+(1); i=i+1) begin

            @(negedge clk);  // read actually happens here
            $display("\n-| Cycle: %4d |--------------------------------------------\n",i);
            $display("*****| AT %5dns NEGEDGE |*****", $time);
            #1;
            $display("FIFO ENTRY FOR THIS INSTRUCTION:");
            $display("Set accessed: %6b", dut.icache.tag_arr.addr0_reg);
            $display("IFIFO_enq_data.instr: 0x%8h", dut.IFIFO_enq_data.instr);
            $display("IFIFO_enq_data.pc: 0x%8h", dut.IFIFO_enq_data.pc);
            $display("IFIFO_enq_data.is_cond_br: %1b" , dut.IFIFO_enq_data.is_cond_br);
            $display("IFIFO_enq_data.br_dir_pred: %1b" , dut.IFIFO_enq_data.br_dir_pred);
            $display("IFIFO_enq_data.br_target_pred: 0x%8h" , dut.IFIFO_enq_data.br_target_pred);
            $display();
            $display("enq_ready %1b", dut.IFIFO_enq_ready); // output - can fifo receive data?
            $display("enq_valid %1b", dut.icache_hit);      // input - enqueue if icache hit
            $display("deq_ready %1b", dut.dispatch_ready);  // input - interface from dispatch
            $display("deq_valid %1b", dut.instr_valid);     // output - interface to dispatch
            $display("deq_data 0x%8h", dut.instr_to_dispatch); // output - dispatched instr
            @(posedge clk);  // let everything get latched in (IFIFO, nextPC into PC and SRAM latches)
            $display();
            $display("*****| AT %5dns POSEDGE |*****", $time);
            #1
            $display("LATCHED SRAM ADDR 0x%8h at time %6d", dut.PC_mux.out,$time);
            $display("recovery_PC_valid %1b, stall_gate_ZN %1b", dut.recovery_PC_valid, dut.stall_gate.ZN);
            $display("IFIFO STALL %1b ICACHE MISS %1b", dut.IFIFO_stall, dut.icache_miss);

            // check instr_valid and instr_data
            if(dut.instr_valid) begin
                num_directed_tests[s_i]++;
                if(dut.instr_valid && dut.instr_to_dispatch == instr_out[s_i][i]) begin
                    num_directed_tests_passed[s_i]++;
                end
                else begin
                    $display("FAILED CASE:");
                    
                end
            end
        end
    endtask
   
    // Task to display test results
    task display_test_results(int s_i);
        if (num_directed_tests_passed[s_i] == num_directed_tests[s_i]) begin
            $display("ALL %0d DIRECTED TESTS PASSED", num_directed_tests[s_i]);
        end else begin
            $display("SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed[s_i], num_directed_tests[s_i]);
        end
        $finish;
    endtask

    task directed_testsets();
        for(int i = 0; i < `NUM_SETS; i++) begin
            build_testcases(i);
            run_directed_testcases(i);
            display_test_results(i);
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