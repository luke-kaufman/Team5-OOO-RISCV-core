`include "frontend/fetch/ifu.v"
`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"

module ifu_tb #(
    parameter N_RANDOM_TESTS = 100
); 
    /*input*/ reg clk;
    /*input*/ reg rst_aL;
    /*input*/ reg [`ADDR_WIDTH-1:0] recovery_PC;
    /*input*/ reg recovery_PC_valid;
    /*input*/ reg backend_stall; 
    /*input*/ reg [`ICACHE_DATA_BLOCK_SIZE-1:0] dram_response;
    /*input*/ reg dram_response_valid;
    
    // INTERFACE TO RENAME
    /*input*/ reg dispatch_ready;
    // /*output*/ reg instr_valid;
    // /*output*/ reg [INSTR_WIDTH-1:0] instr_data;

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
        .dispatch_ready(dispatch_ready)
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
    int instr_locs[13];
    int instr_data[13];
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    task directed_testcases();
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
        
        // reset, wait, then start testing
        rst_aL = 0;
        @(negedge clk);
        @(negedge clk);
        rst_aL = 1;

        backend_stall = 0;
        dispatch_ready = 0;
        @(negedge clk);
        
        // FIRST NEED TO FILL THE ICACHE WITH CERTAIN INSTRUCTIONS
        $display("Filling icache with instructions:");
        for(int i=0; i<NUM_INSTRS; i=i+2) begin
            // force PC to instruction location thru recovery PC logic
            $display("PC=0x%8h", instr_locs[i]);
            $display("To Set in Icache: %d", dut.icache.tag_arr.addr0);
            recovery_PC = instr_locs[i];
            recovery_PC_valid = 1;
            // instruction data as dram response
            dram_response = {instr_data[i+1],instr_data[i]};
            dram_response_valid = 1;
            @(negedge clk);
            // #4;
        end
        dram_response_valid = 0;  // stop writing to icache
        $display("DONE Filling icache with instructions:\n\n");
        // NOW START TESTING - get each instr from icache (no icache miss so far)
        // then watch the instructions flow to end of IFU, check data at the exit
        // of the IFIFO, also check branch metadata

        $display("Force first PC thru recovery PC logic");
        // force PC to instruction location thru recovery PC logic
        recovery_PC = instr_locs[0];
        recovery_PC_valid = 1;
        @(negedge clk);
        recovery_PC_valid = 0;
        $display("DONE Force first PC thru recovery PC logic\n\n");

        // now run for NUM_INSTRS cycles with prepopulated icache
        // starting at first PC 
        $display("Starting to read instructions from icache:");
        dispatch_ready = 1;  // so that we can get IFU output
        for(int i=0; i<NUM_INSTRS; i=i+1) begin
            
            // read from icache
            $display("Reading from icache at PC=0x%8h", dut.PC.dout);
            @(negedge clk);
            #4; // delay for reading from icache
            $display("Set from Icache: 0x%8h", dut.icache.selected_data_way);
            $display("Instr from Icache: 0x%8h", dut.selected_instr);

            // check instr_valid and instr_data
            if(dut.instr_valid && dut.instr_to_dispatch == instr_data[i]) begin
                num_directed_tests_passed++;
            end
            num_directed_tests++;
        end
        $display("DONE Starting to read instructions from icache:\n\n");
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
endmodule;