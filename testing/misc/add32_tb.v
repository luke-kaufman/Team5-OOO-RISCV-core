`timescale 1ns / 1ps

module add32_tb;

// Testbench signals
reg [31:0] a, b;
wire [31:0] y;
wire cout;
integer num_tests = 0;
integer num_tests_passed = 0;

// Instantiate the Unit Under Test (UUT)
add32 uut (
    .a(a), 
    .b(b), 
    .y(y),
    .cout(cout)
);

// Procedure to display final test result
task display_final_result();
    if (num_tests_passed == num_tests) $display("ALL %0d TESTS PASSED", num_tests);
    else $display("SOME TESTS FAILED: %0d/%0d passed", num_tests_passed, num_tests);
    $finish;
endtask

initial begin
    // Assume each test starts as passed

    num_tests++; num_tests_passed++;
    // Test Case 1: a = 32'h00000001, b = 32'h00000001
    a = 32'h00000001; b = 32'h00000001;
    #10; // Wait for the adder to update
    // check assertion, if true, increment num_tests_passed, else print error message
    assert (y == 32'h00000002) else begin
        $error("Test Case 1 failed: a = 32'h00000001, b = 32'h00000001, but y is not 32'h00000002.");
        num_tests_passed--;
    end

    num_tests++; num_tests_passed++;
    // Test Case 2: a = 32'h80000000, b = 32'h80000000
    a = 32'h80000000; b = 32'h80000000;
    #10; // Wait for the adder to update
    assert (y == 32'h00000000) else begin
        $error("Test Case 2 failed: a = 32'h80000000, b = 32'h80000000, but y is not 32'h00000000.");
        num_tests_passed--;
    end

    num_tests++; num_tests_passed++;
    // Test Case 3: a = 32'h7FFFFFFF, b = 32'h7FFFFFFF
    a = 32'h7FFFFFFF; b = 32'h7FFFFFFF;
    #10; // Wait for the adder to update
    assert (y == 32'hFFFFFFFE) else begin
        $error("Test Case 3 failed: a = 32'h7FFFFFFF, b = 32'h7FFFFFFF, but y is not 32'hFFFFFFFE.");
        num_tests_passed--;
    end

    num_tests++; num_tests_passed++;
    // Test Case 4: a = 32'h80000000, b = 32'h7FFFFFFF
    a = 32'h80000000; b = 32'h7FFFFFFF;
    #10; // Wait for the adder to update
    assert (y == 32'hFFFFFFFF) else begin
        $error("Test Case 4 failed: a = 32'h80000000, b = 32'h7FFFFFFF, but y is not 32'hFFFFFFFE.");
        num_tests_passed--;
    end

    num_tests++; num_tests_passed++;
    // Test Case 5: a = 32'h7FFFFFFF, b = 32'h80000000
    a = 32'h7FFFFFFF; b = 32'h80000000;
    #10; // Wait for the adder to update
    assert (y == 32'hFFFFFFFF) else begin
        $error("Test Case 5 failed: a = 32'h7FFFFFFF, b = 32'h80000000, but y is not 32'hFFFFFFFE.");
        num_tests_passed--;
    end

    num_tests++; num_tests_passed++;
    // Test Case 6: a = 32'h80000000, b = 32'h00000001
    a = 32'h80000000; b = 32'h00000001;
    #10; // Wait for the adder to update
    assert (y == 32'h80000001) else begin
        $error("Test Case 6 failed: a = 32'h80000000, b = 32'h00000001, but y is not 32'h80000001.");
        num_tests_passed--;
    end

    // $display_final_result();
end

// Monitor changes
initial begin
    $monitor("At time %t, a=%b b=%b => y=%b", $time, a, b, y);
end


endmodule
