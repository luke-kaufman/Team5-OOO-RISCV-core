// Random and directed testbench for adder module
// `timescale 1ns / 1ps
module or32;
    // Inputs and outputs
    input wire [31:0] a;
    input wire [31:0] b;
    output wire [31:0] y;

    // Instantiate the Design Under Test (DUT)
    or32 dut (
        .a(a), 
        .b(b), 
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
        b = $urandom();
        #10;
        actual_output = y;
        expected_output = (a | b);
        if (actual_output == expected_output) begin
            num_random_tests_passed++;
            $display("Test case passed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
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
        expected_output = (a | b);
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
        expected_output = (a | b);
        if (actual_output == expected_output) begin
            num_directed_tests_passed++;
            $display("Test case passed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end else begin
            $display("Test case failed: a = %0d, b = %0d, actual_output = %0d, expected_output = %0d", a, b, actual_output, expected_output);
        end
    endtask

    initial begin
        // Random testcases
        for (integer i = 0; i < 10; i = i + 1) begin
            random_testcase();
        end

        // Directed testcases
        directed_testcases();

        // Display the test results
        $display("Random testcases: %0d passed out of %0d", num_random_tests_passed, num_random_tests);
        $display("Directed testcases: %0d passed out of %0d", num_directed_tests_passed, num_directed_tests);
    end
endmodule