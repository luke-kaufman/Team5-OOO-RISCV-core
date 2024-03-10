`include "misc/cache.v"
`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.vh"

// Things to test:
// 1. Read from cache (correct way and instruction)
// 2. Write to cache (DRAM response)
// 3. Cache miss signal 
// 4. Cache replacement policy

module icache_tb;
    // clk and reset
    reg clk;
    reg reset_aL;

    // icache signals
    reg [31:0] icache_addr;
    reg [63:0] dram_response_data;
    reg dram_response_valid;

    // dut outputs
    wire [63:0] icache_data_way_out;
    wire icache_hit;

    // golden outputs?? if i decide to do that

    // clock generation 
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
        forever #HALF_PERIOD clk = ~clk;
    end

    // instantiate the icache (DUT)
    cache #(    
        .BLOCK_SIZE_BITS(`ICACHE_DATA_BLOCK_SIZE),
        .NUM_SETS(`ICACHE_NUM_SETS),
        .NUM_WAYS(`ICACHE_NUM_WAYS),
        .NUM_TAG_CTRL_BITS(`ICACHE_NUM_TAG_CTRL_BITS),
        .WRITE_SIZE_BITS(`ICACHE_WRITE_SIZE_BITS)
    ) dut (
        .clk(clk),
        .rst_aL(reset_aL),
        .addr(icache_addr),
        .write_data(dram_response_data),
        .d_cache_is_ST(1'b0),
        .we_aL(!dram_response_valid),
        .selected_data_way(icache_data_way_out),
        .cache_hit(icache_hit)
    );

    // instantiate golden model?? if i decide to do that
    
    // testbench logic
    int num_random_tests_passed = 0;
    int num_random_tests = 0;
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;
    longint actual_output;
    longint expected_output;

    task directed_testcases();
        
        // reset, wait, then start testing
        reset_aL = 0;
        @(negedge clk);
        @(negedge clk);
        reset_aL = 1;

        // TEST READING A PREVIOUS WRITE FROM THE CACHE ------------------------------------------------------------------
        
        icache_addr = 32'hFEDCB00C;
        dram_response_data = 64'hFEDCBA9876543210;
        dram_response_valid = 1; 
        expected_output = dram_response_data;
        $display("ICACHE WE_MASK: %2b", dut.we_mask);
        @(negedge clk);
        
        // now read
        dram_response_valid = 0; 
        @(negedge clk);
        #4  // account for read delay on neg edge (3)
        
        $display("1 ICACHE DATAOUT: %0h", dut.data_out);
        
        num_directed_tests++;
        if (icache_data_way_out == expected_output) begin
            $display("Test 1.1 PASS: expected 0x%0h, got 0x%0h", expected_output, icache_data_way_out);
            num_directed_tests_passed++;
        end else begin
            $display("Test 1.1 FAIL: expected 0x%0h, got 0x%0h", expected_output, icache_data_way_out);
        end

        num_directed_tests++;
        if (icache_hit == 1) begin
            $display("Test 1.2 PASS: expected 1 got %0d", icache_hit);
            num_directed_tests_passed++;
        end else begin
            $display("Test 1.2 FAIL: expected 1 got %0d", icache_hit);
        end

        // TEST CACHE MISS WITHIN THE SAME SET ----------------------------------------------------------------------------
        
        icache_addr = 32'hF0DCB00C;  // E changed to 0 to change tag
        @(negedge clk);
        #4  // account for read delay on neg edge (3)

        num_directed_tests++;
        if (icache_hit == 0) begin
            $display("Test 2 PASS: expected miss got %0d, data %0h", icache_hit, icache_data_way_out);
            num_directed_tests_passed++;
        end else begin
            $display("Test 2 FAIL: expected miss got %0d, data %0h", icache_hit, icache_data_way_out);
        end

        // TEST WRITING TO OTHER WAY IN CACHE SET AND READING FROM IT --------------------------------------------------
       
        // write: Should write to other way in set 1
        icache_addr = 32'hF0DCB00C;  // different tag to initial write
        dram_response_data = 64'hDEADBEEFDEADBEEF;
        dram_response_valid = 1; 
        expected_output = dram_response_data;
        // $display("3 ICACHE WAY0_V: %1b", dut.we_);
        // $display("3 ICACHE WAY0_tag_match: %1b", dut.we_);
        // $display("3 ICACHE WAY1_V: %1b", dut.we_);
        // $display("3 ICACHE WAY1_tag_match: %1b", dut.we_);
        $display("3 ICACHE WE_MASK: %2b", dut.we_mask);
        @(negedge clk);
        
        // TEST WRITING TO CACHE SET WITH 1 WAY VALID AND THE SAME TAG AS THAT WAY ----------------------------------------

        // write: should already have data here - should overwrite it with new data
        icache_addr = 32'hFEDCB00C;
        dram_response_data = 64'h0123456789ABCDEF;
        dram_response_valid = 1; 
        expected_output = dram_response_data;
        $display("4 ICACHE WE_MASK: %2b", dut.we_mask);
        @(negedge clk);

        // now read
        dram_response_valid = 0; 
        @(negedge clk);
        #4  // account for read delay on neg edge (3)
        
        $display("ICACHE DATAOUT: %0h", dut.data_out);
        
        num_directed_tests++;
        if (icache_data_way_out == expected_output) begin
            $display("Test 4.1 PASS: expected 0x%0h, got 0x%0h", expected_output, icache_data_way_out);
            num_directed_tests_passed++;
        end else begin
            $display("Test 4.1 FAIL: expected 0x%0h, got 0x%0h", expected_output, icache_data_way_out);
        end

        num_directed_tests++;
        if (icache_hit == 1) begin
            $display("Test 4.2 PASS: expected 1 got %0d", icache_hit);
            num_directed_tests_passed++;
        end else begin
            $display("Test 4.2 FAIL: expected 1 got %0d", icache_hit);
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
endmodule