`include "misc/cmp/cmp32.v"

// random and directed testbench for cmp32 module
module cmp32_tb;
    // Inputs and outputs
    reg [31:0] a;
    reg [31:0] b;
    wire y;

    // Instantiate the Design Under Test (DUT)
    cmp32 dut (
        .a(a),
        .b(b),
        .y(y)
    );

    int num_random_tests_passed = 0;
    int num_random_tests = 0;
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;
    int actual_output;
    int expected_output;

    // Task to check random testcase
    task random_testcase();
        num_random_tests++;
        a = $urandom();
        b = $urandom();
        #10;
        actual_output = y;
        expected_output = a == b;
        if (actual_output == expected_output) begin
            num_random_tests_passed++;
        end else begin
            $display("Test case failed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end
    endtask

    // Task to check directed testcases
    task directed_testcases();
        num_directed_tests++;
        a = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        b = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        #10;
        actual_output = y;
        expected_output = (a == b);
        if (actual_output == expected_output) begin
            num_directed_tests_passed++;
            $display("Test case passed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end else begin
            $display("Test case failed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end

        num_directed_tests++;
        a = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        b = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        #10;
        actual_output = y;
        expected_output = (a == b);
        if (actual_output == expected_output) begin
            num_directed_tests_passed++;
            $display("Test case passed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end else begin
            $display("Test case failed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end

        num_directed_tests++;
        a = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        b = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        #10;
        actual_output = y;
        expected_output = (a == b);
        if (actual_output == expected_output) begin
            num_directed_tests_passed++;
            $display("Test case passed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end else begin
            $display("Test case failed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end

        num_directed_tests++;
        a = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        b = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        #10;
        actual_output = y;
        expected_output = (a == b);
        if (actual_output == expected_output) begin
            num_directed_tests_passed++;
            $display("Test case passed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end else begin
            $display("Test case failed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
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
        repeat (1000) begin
            random_testcase();
        end
        directed_testcases();
        display_test_results();
    end
endmodule
