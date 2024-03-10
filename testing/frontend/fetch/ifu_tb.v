`include "frontend/fetch/ifu.v"

module #(
    parameter N_RANDOM_TESTS = 100
) ifu_tb;

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

    // design under test
    ifu dut (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(we),
        .d(d),
        .q(q_dut)
    );

    // golden model
    ifu_golden golden (
        .clk(clk),
        .rst_aL(rst_aL),
        .we(we),
        .d(d),
        .q(q_golden)
    );

    int num_random_tests_passed = 0;
    int num_random_tests = 0;

    initial begin
        $dumpfile("ifu_tb.vcd");
        $dumpvars(0, ifu_tb);
        $monitor($time, " clk = %b, rst_aL = %b, we = %b, d = %b, q_dut = %b, q_golden = %b", clk, rst_aL, we, d, q_dut, q_golden);
        // reset the design
        @(negedge clk);
        rst_aL = 0;
        we = 0;
        d = 1;
        @(negedge clk);
        rst_aL = 1;
        // random testcases
        repeat (N_RANDOM_TESTS) begin
            // assign random values to inputs
            @(negedge clk);
            we = $urandom();
            d = $urandom();
            // check the output
            @(negedge clk);
            num_random_tests = num_random_tests + 1;
            if (q_dut === q_golden) begin
                num_random_tests_passed = num_random_tests_passed + 1;
            end
        end
        $display("Random tests passed: %d/%d", num_random_tests_passed, num_random_tests);
        $finish;
    end
)