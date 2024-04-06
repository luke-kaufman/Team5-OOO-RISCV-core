`include "frontend/fetch/ifu.v"
`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"

module #(
    parameter N_RANDOM_TESTS = 100
) ifu_tb;

    /*input*/ reg clk,
    /*input*/ reg rst_aL,
    /*input*/ reg [ADDR_WIDTH-1:0] recovery_PC,
    /*input*/ reg recovery_PC_valid,
    /*input*/ reg backend_stall, 
    /*input*/ reg [I$_BLOCK_SIZE-1:0] dram_response,
    /*input*/ reg dram_response_valid,
    
    // INTERFACE TO RENAME
    /*input*/ reg dispatch_ready,
    /*output*/ reg instr_valid,
    /*output*/ reg [INSTR_WIDTH-1:0] instr_data

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
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
        .instr_valid(instr_valid),
        .instr_data(instr_data)
    );

    // // golden model
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
    int instr_locs[NUM_INSTRS];
    int instr_data[NUM_INSTRS];
    instr_locs[0]=32'h1018c;
    instr_locs[1]=32'h10190;
    instr_locs[2]=32'h10194;
    instr_locs[3]=32'h10198;
    instr_locs[4]=32'h1019c;
    instr_locs[5]=32'h101a0;
    instr_locs[6]=32'h101a4;
    instr_locs[7]=32'h101a8;
    instr_locs[8]=32'h101ac;
    instr_locs[9]=32'h101b0;
    instr_locs[10]=32'h101b4;
    instr_locs[11]=32'h101b8;
    instr_locs[12]=32'h101bc;
    instr_data[0]=32'hfe010113; // add sp,sp,-32        
    instr_data[1]=32'h00112e23; // sw ra,28(sp)        
    instr_data[2]=32'h00812c23; // sw s0,24(sp)        
    instr_data[3]=32'h02010413; // add s0,sp,32        
    instr_data[4]=32'hfea42623; // sw a0,-20(s0)        
    instr_data[5]=32'hfeb42423; // sw a1,-24(s0)        
    instr_data[6]=32'h01c000ef; // jal 101c0 <hello>       
    instr_data[7]=32'h00050793; // mv a5,a0        
    instr_data[8]=32'h00078513; // mv a0,a5        
    instr_data[9]=32'h01c12083; // lw ra,28(sp)        
    instr_data[10]=32'h01812403; // lw s0,24(sp)        
    instr_data[11]=32'h02010113; // add sp,sp,32        
    instr_data[12]=32'h00008067; // ret  
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

     task directed_testcases();
        
        // reset, wait, then start testing
        reset_aL = 0;
        @(negedge clk);
        @(negedge clk);
        reset_aL = 1;
        
        recovery_PC = 32'hDEADBEEF;
        recovery_PC_valid = 0;
        
        backend_stall = 0;

        dram_response = 64'hBBBBBBBBAAAAAAAA;  // first instruction to insert
        dram_response_valid = 1;

        dispatch_ready = 0;
        
        // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        for(int i=0 i<NUM_INSTRS; i=i+1) begin
            // force PC to instruction location thru recovery PC logic
            recovery_PC = instr_locs[i];
            recovery_PC_valid = 1;
            // instruction data as dram response
            dram_response = instr_data[i];
            dram_response_valid = 1;
            @(negedge clk);
        end

        // NOW START TESTING - get each instr from icache (no icache miss so far)
        // then watch the instructions flow to end of IFU, check data at the exit
        // of the IFIFO, also check branch metadata

        // force PC to instruction location thru recovery PC logic
        recovery_PC = instr_locs[i];
        recovery_PC_valid = 1;
        @(negedge clk);
        recovery_PC_valid = 0;
        for(int i=0 i<NUM_INSTRS; i=i+1) begin
            
            // instruction data as dram response
            dram_response = instr_data[i];
            dram_response_valid = 1;
            
            // wait for dispatch ready
            @(negedge clk);
            // while(!dispatch_ready) begin
            //     @(negedge clk);
            // end
            
            // check instr_valid and instr_data
            if(instr_valid && instr_data == instr_data[i]) begin
                num_directed_tests_passed = num_directed_tests_passed + 1;
            end
            num_directed_tests = num_directed_tests + 1;
        end

    endtask

        // Task to display test results
    task display_test_results();
        if (num_random_tests_passed == num_random_tests) begin
            $display("ALL %0d RANDOM TESTS PASSED", num_random_tests);
        end else begin
            $display("SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
        end
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
endmodule;