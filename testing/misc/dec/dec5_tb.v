`include "misc/dec/dec5.v"
`include "golden/misc/decoder_golden.v"

module dec5_tb #(
    parameter WIDTH = 5
);
    // inputs
    reg [WIDTH-1:0] in;
    // dut outputs
    wire[2**WIDTH-1:0] out_dut;
    // golden outputs
    wire[2**WIDTH-1:0] out_golden;

    // instantiate the design under test (DUT)
    dec5 dut (
        .in(in),
        .out(out_dut)
    );

    // instantiate the golden model
    decoder_golden #(
        .WIDTH(WIDTH)
    ) golden (
        .in(in),
        .out(out_golden)
    );

    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    initial begin

        // Comprehensive Testing
        for (int i = 0; i < 2**WIDTH; i = i + 1) begin
            num_directed_tests++;
            in = i;
            #15;
            if (out_dut == out_golden) begin
                num_directed_tests_passed++;
                $display("Directed test case passed: in=%2d\nout_dut    = %64b\nout_golden = %64b", in, out_dut, out_golden);
            end else begin
                $display("Directed test case failed: in=%2d\nout_dut    = %64b\nout_golden = %64b", in, out_dut, out_golden);
            end
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