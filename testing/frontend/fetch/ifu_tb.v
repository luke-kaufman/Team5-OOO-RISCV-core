`include "frontend/fetch/ifu.v"
`include "freepdk-45nm/stdcells.v"
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

    // // golden model - no golden model rn
    // ifu_golden golden (
    //     .clk(clk),
    //     .rst_aL(rst_aL),
    //     .we(we),
    //     .d(d),
    //     .q(q_golden)
    // );

    // int num_random_tests_passed = 0;
    // int num_random_tests = 0;
    int NUM_INSTRS=13;
    int instr_locs[13];
    int instr_data[13];
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    task directed_testcases();

        // program to load
        instr_locs[0]=32'h1018c;  instr_data[0]=32'hfe010113; // add sp,sp,-32        
        instr_locs[1]=32'h10190;  instr_data[1]=32'h00112e23; // sw ra,28(sp)        
        instr_locs[2]=32'h10194;  instr_data[2]=32'h00812c23; // sw s0,24(sp)        
        instr_locs[3]=32'h10198;  instr_data[3]=32'h02010413; // add s0,sp,32        
        instr_locs[4]=32'h1019c;  instr_data[4]=32'hfea42623; // sw a0,-20(s0)        
        instr_locs[5]=32'h101a0;  instr_data[5]=32'hfeb42423; // sw a1,-24(s0)        
        instr_locs[6]=32'h101a4;  instr_data[6]=32'h01c000ef; // jal 101c0 <hello>       
        instr_locs[7]=32'h101a8;  instr_data[7]=32'h00050793; // mv a5,a0        
        instr_locs[8]=32'h101ac;  instr_data[8]=32'h00078513; // mv a0,a5        
        instr_locs[9]=32'h101b0;  instr_data[9]=32'h01c12083; // lw ra,28(sp)        
        instr_locs[10]=32'h101b4; instr_data[10]=32'h01812403; // lw s0,24(sp)        
        instr_locs[11]=32'h101b8; instr_data[11]=32'h02010113; // add sp,sp,32        
        instr_locs[12]=32'h101bc; instr_data[12]=32'h00008067; // ret  
        // end of program to load
        
        // reset, wait, then start testing
        rst_aL = 0;
        #1;
        @(posedge clk);

        rst_aL = 1;
        #1;
        @(posedge clk);
        @(negedge clk);
        #1;

        // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        $display("Filling icache with instructions:");
        for(int i=0; i<NUM_INSTRS; i=i+1) begin
            $display("PC=0x%32b (%8h)", instr_locs[i], instr_locs[i]);
           
            // force PC to instruction location thru recovery PC logic
            recovery_PC = instr_locs[i];
            recovery_PC_valid = 1;

            if(i==0 && (instr_locs[0] & 32'h00000004)) begin
                dram_response = {instr_data[i], 32'h00000000};
            end
            else begin            
                dram_response = {instr_data[i+1],instr_data[i]};
                i = i + 1;
            end
            
            dram_response_valid = 1;
            csb0_in = 0;  // turn on icache
            @(posedge clk);  // latch into sram and PC

            @(negedge clk);  // write at negedge1
            #1;
            $display("\n");
            dram_response_valid = 0;  // turn off we
            csb0_in = 1;  // turn off icache
            
        end

        dram_response_valid = 0;  // stop writing to icache
        $display("DONE Filling icache with instructions:---------------------------------------------\n\n");

        // NOW START TESTING - get each instr from icache (no icache miss so far)
        // then watch the instructions flow to end of IFU, check data at the exit
        // of the IFIFO, also check branch metadata

        $display("Force first PC thru recovery PC logic");
        // force PC to instruction location thru recovery PC logic
        recovery_PC = instr_locs[0];
        recovery_PC_valid = 1;
        csb0_in = 0;
        @(posedge clk); // pc latched into PC reg and SRAM latches
        $display("START READING INSRUCTIONS FROM ICACHE TIME: %6d", $time);
        #1;
        recovery_PC_valid = 0;
        $display("DONE Force first PC thru recovery PC logic\n\n");

        // now run for NUM_INSTRS cycles with prepopulated icache
        // starting at first PC 
        dispatch_ready = 1;  // so that we can get IFU output
        // loop comes in clk is high

        for(int i=0; i<NUM_INSTRS; i=i+1) begin
            
            // // read from icache
            // @(negedge clk);
            // #1;
            // $display("%c[1;31m",27);
            // $display("%c[0m",27);
            // csb0_in = 0;
            // @(posedge clk);  // latch into SRAM here
            
            @(negedge clk);  // read actually happens here
            $display("Reading instruction %3d from icache at %6d PC=0x%8h", i, $time, dut.PC.dout);
            $display("Set accessed: %6b", dut.icache.tag_arr.addr0_reg);
            #1;
            // recovery_PC_valid = 0;
            $display("READ, THEN TO IFIFO AT TIME: %6d", $time);
            $display("selected data way from Icache: 0x%16h", dut.icache.selected_data_way);
            $display("FIFO ENTRY FOR THIS INSTRUCTION:");
            $display("%c[1;31m",27);
            $display("IFIFO_enq_data.instr: 0x%8h" , dut.IFIFO_enq_data.instr);
            $display("IFIFO_enq_data.pc: 0x%8h" , dut.IFIFO_enq_data.pc);
            $display("%c[0m",27);
            $display("IFIFO_enq_data.is_cond_br: %1b" , dut.IFIFO_enq_data.is_cond_br);
            $display("IFIFO_enq_data.br_dir_pred: %1b" , dut.IFIFO_enq_data.br_dir_pred);
            $display("IFIFO_enq_data.br_target_pred: 0x%8h" , dut.IFIFO_enq_data.br_target_pred);
            $display();
            $display();
            @(posedge clk);  // let everything get latched in (IFIFO, nextPC into PC and SRAM latches)
            #1
            // $display("LATCHED SRAM ADDR 0x%8h at time %6d", dut.PC_mux.out,$time);
            // $display("recovery_PC_valid %1b, stall_gate.ZN %1b", dut.recovery_PC_valid, dut.stall_gate.ZN);
            // $display("IFIFO STALL %1b ICACHE MISS %1b", dut.IFIFO_full_stall, dut.icache_miss);
            // $display("TAG VALID %1b TAG MATCH %1b", dut.icache.way0_v, dut.icache.way0_tag_match);
            // TO MAKE THIS WORK: no longer feeding PC directly into cache
            // now PC mux will go to both PC reg and the latches in the SRAM Module
            // with the PC reg serving as an external mirror of whats latched into the
            // SRAM module. Having to go thru the PC go directly into the cache adds an
            // (unneccessary?) cycle.
            // ^^ doing this actually causes infinite loop(?) when reading thru stall-gate
            // and probably cache hit which stall depends on
            // whyyyyyyyyyy

            // check instr_valid and instr_data
            if(dut.instr_valid && dut.instr_to_dispatch == instr_data[i]) begin
                num_directed_tests_passed++;
            end
            num_directed_tests++;
        end
        $display("DONE reading instructions from icache:\n\n");
    endtask

        // Task to display test results
    task display_test_results();
        // if (num_random_tests_passed == num_random_tests) begin
        //     $display("ALL %0d RANDOM TESTS PASSED", num_random_tests);
        // end else begin
        //     $display("SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
        // end
        if (num_directed_tests_passed == num_directed_tests) begin
            $display("ALL %0d DIRECTED TESTS PASSED", num_directed_tests);
        end else begin
            $display("SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed, num_directed_tests);
        end
        $finish;
    endtask

    // Initial block to run testcases
    initial begin
        // repeat (1000) begin
        //     random_testcase();
        // end
        directed_testcases();
        display_test_results();
    end
endmodule