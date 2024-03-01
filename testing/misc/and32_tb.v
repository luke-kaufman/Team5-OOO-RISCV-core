`include "and32.v"

// Constrained random and directed testbench for and32 module

module and32_tb;
    // Inputs and outputs
    reg [31:0] a;
    wire y;

    // Instantiate the Design Under Test (DUT)
    and32 dut (
        .a(a),
        .y(y)
    );

    integer num_random_tests_passed = 0;
    integer num_random_tests = 0;
    integer num_directed_tests_passed = 0;
    integer num_directed_tests = 0;
    integer actual_output;
    integer expected_output;

    // Task to check random testcase
    task random_testcase();
        num_random_tests++;
        a = $urandom();
        #10;
        actual_output = y;
        expected_output = &a;
        if (actual_output == expected_output) begin
            num_random_tests_passed++;
            // $display("Random test case passed: a = %0d, actual_output = %0d, expected_output = %0d", a, actual_output, expected_output);
        end else begin
            $display("Random test case failed: a = %0d, actual_output = %0d, expected_output = %0d", a, actual_output, expected_output);
        end
    endtask

    // Task to check directed testcases
    task directed_testcases();
        num_directed_tests++;
        a = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        #10;
        actual_output = y;
        expected_output = &a;
        if (actual_output == expected_output) begin
            num_directed_tests_passed++;
            $display("Directed test case passed: a = %0d, actual_output = %0d, expected_output = %0d", a, actual_output, expected_output);
        end else begin
            $display("Directed test case failed: a = %0d, actual_output = %0d, expected_output = %0d", a, actual_output, expected_output);
        end
    endtask

    // Task to display test results
    task display_test_results();
        if (num_random_tests_passed == num_random_tests) $display("ALL %0d RANDOM TESTS PASSED", num_random_tests);
        else $display("SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
        if (num_directed_tests_passed == num_directed_tests) $display("ALL %0d DIRECTED TESTS PASSED", num_directed_tests);
        else $display("SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed, num_directed_tests);
        $finish;
    endtask

    // Initial block to run testcases
    initial begin
        repeat (1000) begin
            random_testcase();
        end
        directed_testcases();
        display_test_results();
    end
endmodule
