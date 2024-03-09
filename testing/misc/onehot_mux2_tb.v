`timescale 1ns / 1ps

module onehot_mux2_tb;

logic [1:0] s;
logic [31:0] d1, d0;
logic [31:0] y;
int num_tests = 0;
int num_tests_passed = 0;

// Instantiate the Unit Under Test (UUT)
onehot_mux2 #(32) uut (
    .d0(d0),
    .d1(d1),
    .s(s),
    .y(y)
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
    // Test Case 1: s = 2'b01 selects d0
    d1 = 0; d0 = 32'h000000FF; s = 2'b01;
    #10; // Wait for the mux to update
    // check assertion, if true, increment num_tests_passed, else print error message
    assert (y == 32'h000000FF) else begin
        $error("Test Case 1 failed: s = 2'b01, but y is not d0.");
    end

    // Assume each test starts as passed
    num_tests++; num_tests_passed++; 
    // Test Case 2: s = 2'b10 selects d1
    d1 = 32'h0000FF00; d0 = 0; s = 2'b10;
    #10; // Wait for the mux to update
    assert (y == 32'h0000FF00) else begin
        $error("Test Case 2 failed: s = 2'b10, but y is not d1.");
    end

    display_final_result();
end

// Monitor changes
initial begin
    $monitor("At time %t, s=%b | d0=%b d1=%b => y=%b", $time, s, d0, d1, y);
end

endmodule