`include "misc/dec/dec4.v"
`include "golden/misc/decoder_golden.v"

module dec4_tb #(
    parameter WIDTH = 4,
);
    // inputs
    reg [WIDTH-1:0] in;
    // dut outputs
    wire[2**WIDTH-1:0] out_dut;
    // golden outputs
    wire[2**WIDTH-1:0] out_golden;

    // instantiate the design under test (DUT)
    dec3 dut (
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

    int num_random_tests_passed = 0;
    int num_random_tests = 0;
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    initial begin

        // Comprehensive Testing
        for (int i = 0; i < WIDTH; i = i + 1) begin
            num_directed_tests++;
            in = i;
            #15;
            if (y_dut == y_golden) begin
                num_directed_tests_passed++;
                $display("Directed test case passed: in=%2d\nout_dut    = %64b\nout_golden = %64b", in, out_dut, out_golden);
            end else begin
                $display("Directed test case failed: in=%2d\nout_dut    = %64b\nout_golden = %64b", in, out_dut, out_golden);
            end
        end
        $finish;
    end
endmodule