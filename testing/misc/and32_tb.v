`timescale 1ns / 1ps

module and32_tb;

logic [31:0] a;
logic y;
integer num_tests_passed = 0;
integer num_tests = 0;

// Instantiate the Unit Under Test (UUT)
and32 uut (
    .a(a), 
    .y(y)
);

// Procedure to display final test result
task display_final_result();
    if (num_tests_passed == num_tests) $display("ALL TESTS PASSED");
    else $display("SOME TESTS FAILED: %0d/%0d passed", num_tests_passed, num_tests);
    $finish;
endtask

initial begin
    // Test Case 1: All bits of 'a' are 1
    a = 32'hFFFFFFFF; num_tests++;
    #10;
    assert (y == 1) else $error("Test Case 1 failed: 'a' is all 1s, but 'y' is not 1.");

    // Test Case 2: One bit of 'a' is 0
    a = 32'hFFFFFFFE; num_tests++;
    #10;
    assert (y == 0) else $error("Test Case 2 failed: One bit of 'a' is 0, but 'y' is not 0.");

    // Test Case 3: All bits of 'a' are 0
    a = 32'h00000000; num_tests++;
    #10;
    assert (y == 0) else $error("Test Case 3 failed: 'a' is all 0s, but 'y' is not 0.");

    // Test Case 4: Random test case, not all bits of 'a' are 1
    a = 32'hA5A5A5A5; num_tests++;
    #10;
    assert (y == 0) else $error("Test Case 4 failed: Not all bits of 'a' are 1, but 'y' is not 0.");

    // If no errors have been thrown, all tests passed
    num_tests_passed = num_tests;
    display_final_result();
end

endmodule
