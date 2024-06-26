`include "misc/dff_we.v"
`include "golden/misc/dff_we_golden.sv"

module dff_we_tb #(
    parameter N_RANDOM_TESTS = 100
);
    // clock and reset
    reg clk;
    reg rst_aL;

    // inputs
    reg we;
    reg d;

    // dut outputs
    wire q_dut;

    // golden outputs
    wire q_golden;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
        forever #HALF_PERIOD clk = ~clk;
    end

    // design under test (dut)
    dff_we dut (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(we),
        .d(d),
        .q(q_dut)
    );

    // golden model
    dff_we_golden golden (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(we),
        .d(d),
        .q(q_golden)
    );

    int num_random_tests_passed = 0;
    int num_random_tests = 0;

    initial begin
        $dumpfile("dff_we_tb.vcd");
        $dumpvars(0, dff_we_tb);
        $monitor($time, " clk = %b, rst_aL = %b, we = %b, d = %b, q_dut = %b, q_golden = %b", clk, rst_aL, we, d, q_dut, q_golden);
        // reset the design
        @(negedge clk);
        rst_aL = 0;
        we = 0;
        d = 1;
        @(negedge clk);
        rst_aL = 1;
        // random testcases
        for (int i = 0; i < N_RANDOM_TESTS; i++) begin
            num_random_tests++;
            // assign random values to inputs
            @(negedge clk);
            we = $urandom();
            d = $urandom();
            // check the output
            @(negedge clk);
            if (q_dut == q_golden) begin
                num_random_tests_passed++;
                // $display("Random test case passed at time %0t: we = %0d, d = %0d, q_dut = %0d, q_golden = %0d", $time, we, d, q_dut, q_golden);
            end else begin
                $display("Random test case failed at time %0t: we = %0d, d = %0d, q_dut = %0d, q_golden = %0d", $time, we, d, q_dut, q_golden);
            end
        end
        @(negedge clk);
        $display("Random tests passed: %0d/%0d", num_random_tests_passed, num_random_tests);
        $finish;
    end
endmodule
