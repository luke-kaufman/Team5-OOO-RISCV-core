`include "misc/mux/mux_.v"
`include "golden/misc/mux_golden.v"

module mux_tb #(
    parameter N_RANDOM_TESTS = 10,
    parameter N_INS = 64,
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
    mux_ #(
        .WIDTH(WIDTH),
        .N_INS(N_INS)
    ) dut (
        .ins(a),
        .sel(sel),
        .out(y_dut)
    );

    // instantiate the golden model
    mux_golden #(
        .N_INS(N_INS),
        .WIDTH(WIDTH)
    ) golden (
        .inputs(a),
        .select(sel),
        .out(y_golden)
    );

    int num_random_tests_passed = 0;
    int num_random_tests = 0;
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    initial begin

        // small directed case
        for (int i = 0; i < N_INS; i = i + 1) begin
            a[i] = i*2;
        end
        for (int i = 0; i < N_INS; i = i + 1) begin
            num_directed_tests++;
            sel = i;
            #15;
            if (y_dut == y_golden) begin
                num_directed_tests_passed++;
                $display("Directed test case passed: sel=%2d\ny_dut    = %64b\ny_golden = %64b", sel, y_dut, y_golden);
            end else begin
                $display("Directed test case failed: sel=%2d\ny_dut    = %64b\ny_golden = %64b", sel, y_dut, y_golden);
            end
        end
        
        
        for (int i = 0; i < N_RANDOM_TESTS; i = i + 1) begin
            num_random_tests++;
            
            // assign random values to inputs
            for (int j = 0; j < N_INS; j = j + 1) begin
                a[j] = $urandom();
            end
            sel = $urandom() % N_INS;
            // check the output
            #15;
            if (y_dut == y_golden) begin
                num_random_tests_passed++;
                $display("Random test case passed: sel=%2d\ny_dut    = %64b\ny_golden = %64b", sel, y_dut, y_golden);

            end else begin
                $display("Random test case failed: sel=%2d\ny_dut    = %64b\ny_golden = %64b", sel, y_dut, y_golden);
            end
        end

        // display random test results
        if (num_random_tests_passed == num_random_tests) begin
            $display("(mux_tb) ALL %0d RANDOM TESTS PASSED", num_random_tests);
        end else begin
            $display("(mux_tb) SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
        end
        // display directed test results
        if (num_directed_tests_passed == num_directed_tests) begin
            $display("(mux_tb) ALL %0d DIRECTED TESTS PASSED", num_directed_tests);
        end else begin
            $display("(mux_tb) SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed, num_directed_tests);
        end
        $finish;
    end
endmodule