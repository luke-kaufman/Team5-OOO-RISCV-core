`include "misc/and/and_.v"
`include "golden/misc/and_golden.v"

module xnor_tb #(
    parameter N_RANDOM_TESTS = 100,
    parameter N_INS = 2
);
    // inputs
    reg [N_INS-1:0] a;
    // dut outputs
    wire y_dut;
    // golden outputs
    wire y_golden;

    // instantiate the design under test (DUT)
    and_ #(
        .N_INS(N_INS)
    ) dut (
        .a(a),
        .y(y_dut)
    );
    // instantiate the golden model
    xnor_golden #(
        .N_INS(N_INS)
    ) golden (
        .a(a),
        .y(y_golden)
    );

    int num_random_tests_passed = 0;
    int num_random_tests = 0;
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    initial begin
        for (int i = 0; i < N_RANDOM_TESTS; i = i + 1) begin
            num_random_tests++;
            // assign random values to inputs
            a = $urandom();
            // check the output
            #10;
            if (y_dut == y_golden) begin
                num_random_tests_passed++;
            end else begin
                $display("Random test case failed: a = %0d, y_dut = %0d, y_golden = %0d", a, y_dut, y_golden);
            end
        end

        // directed testcases
        // testcase 1
        num_directed_tests++;
        // inputs
        a = {N_INS{1'b1}};
        // check the output
        #10;
        if (y_dut == y_golden) begin
            num_directed_tests_passed++;
            $display("Directed test case passed: a = %0d, y_dut = %0d, y_golden = %0d", a, y_dut, y_golden);
        end else begin
            $display("Directed test case failed: a = %0d, y_dut = %0d, y_golden = %0d", a, y_dut, y_golden);
        end

        // testcase 2
        num_directed_tests++;
        // inputs
        a = {N_INS{1'b0}};
        // check the output
        #10;
        if (y_dut == y_golden) begin
            num_directed_tests_passed++;
        end else begin
            $display("Directed test case failed: a = %0d, y_dut = %0d, y_golden = %0d", a, y_dut, y_golden);
        end

        // testcase 3
        num_directed_tests++;
        // inputs
        a = {{N_INS/2{1'b1}}, {N_INS/2{1'b0}}};
        // check the output
        #10;
        if (y_dut == y_golden) begin
            num_directed_tests_passed++;
        end else begin
            $display("Directed test case failed: a = %0d, y_dut = %0d, y_golden = %0d", a, y_dut, y_golden);
        end

        // testcase 4
        num_directed_tests++;
        // inputs
        a = {{N_INS/2{1'b0}}, {N_INS/2{1'b1}}};
        // check the output
        #10;
        if (y_dut == y_golden) begin
            num_directed_tests_passed++;
        end else begin
            $display("Directed test case failed: a = %0d, y_dut = %0d, y_golden = %0d", a, y_dut, y_golden);
        end

        // display random test results
        if (num_random_tests_passed == num_random_tests) begin
            $display("(and_tb) ALL %0d RANDOM TESTS PASSED", num_random_tests);
        end else begin
            $display("(and_tb) SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
        end
        // display directed test results
        if (num_directed_tests_passed == num_directed_tests) begin
            $display("(and_tb) ALL %0d DIRECTED TESTS PASSED", num_directed_tests);
        end else begin
            $display("(and_tb) SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed, num_directed_tests);
        end
        $finish;
    end
endmodule