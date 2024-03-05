`include "misc/mux/mux32.v"
`include "golden/misc/mux_golden.v"

module mux32_tb #(
    parameter N_RANDOM_TESTS = 100,
    parameter N_INS = 32,
    parameter WIDTH = 32,
    localparam SEL_WIDTH = $clog2(N_INS)
);
    // inputs
    reg [N_INS-1:0][WIDTH-1:0] a;
    reg [SEL_WIDTH-1:0] sel;
    // dut outputs
    wire[WIDTH-1:0] y_dut;
    // golden outputs
    wire[WIDTH-1:0] y_golden;

    // instantiate the design under test (DUT)
    mux32 #(
        .WIDTH(WIDTH)
    ) dut (
        .ins(a),
        .sel(sel),
        .out(y_dut)
    );

    // instantiate the golden model
    mux_golden #(
        .N(N_INS),
        .WIDTH(WIDTH)
    ) golden (
        .inputs(a),
        .select(sel),
        .out(y_golden)
    );

    integer num_random_tests_passed = 0;
    integer num_random_tests = 0;
    integer num_directed_tests_passed = 0;
    integer num_directed_tests = 0;

    initial begin

        // small directed case mainly to check if golden is working
        for (integer i = 0; i < N_INS; i = i + 1) begin
            a[i] = i*2;
        end
        for (integer i = 0; i < N_INS; i = i + 1) begin
            num_directed_tests++;
            sel = i;
            #15;
            if (y_dut == y_golden) begin
                num_directed_tests_passed++;
            end else begin
                $display("Random test case failed: sel=%2d, y_dut = %32b, y_golden = %32b", sel, y_dut, y_golden);
            end
        end
        
        
        for (integer i = 0; i < N_RANDOM_TESTS; i = i + 1) begin
            num_random_tests++;
            
            // assign random values to inputs
            for (integer j = 0; j < N_INS; j = j + 1) begin
                a[j] = $urandom();
            end
            sel = $urandom() % N_INS;
            // check the output
            #15;
            if (y_dut == y_golden) begin
                num_random_tests_passed++;
            end else begin
                $display("Random test case failed: sel=%2d, y_dut = %32b, y_golden = %32b", sel, y_dut, y_golden);
            end
        end

        // display random test results
        if (num_random_tests_passed == num_random_tests) begin
            $display("(mux32_tb) ALL %0d RANDOM TESTS PASSED", num_random_tests);
        end else begin
            $display("(mux32_tb) SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
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