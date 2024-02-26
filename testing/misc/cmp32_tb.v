`timescale 1ns / 1ps

module cmp32_tb;

logic [31:0] a, b;
logic y;
integer num_tests_passed = 0;
integer num_tests = 0;

// Instantiate the Unit Under Test (UUT)
cmp32 uut (
    .a(a), 
    .b(b), 
    .y(y)
);

// Procedure to display final test result
task display_final_result();
    if (num_tests_passed == num_tests) $display("ALL TESTS PASSED");
    else $display("SOME TESTS FAILED: %0d/%0d passed", num_tests_passed, num_tests);
    $finish;
endtask

initial begin
    // Test Case 1: a == b
    a = 32'hAAAA_AAAA; b = 32'hAAAA_AAAA; num_tests++;
    #10; // Wait for the comparator to update
    assert (y == 1) else $error("Test Case 1 (a == b) failed.");

    // Test Case 2: a != b
    a = 32'hAAAA_AAAA; b = 32'hBBBB_BBBB; num_tests++;
    #10; // Wait for the comparator to update
    assert (y == 0) else $error("Test Case 2 (a != b) failed.");
    
    // If no errors have been thrown, all tests passed
    num_tests_passed = num_tests;
    display_final_result();
end

// Assertion-based error handling
always @(posedge y or negedge y) begin
    if (y == 1 && a !== b) $error("Mismatch error: a !== b, but result is high.");
    else if (y == 0 && a === b) $error("Mismatch error: a === b, but result is low.");
    else num_tests_passed++;
end

endmodule
