`include "misc/fifo.v"
`include "golden/misc/fifo_golden.sv"

// random testbench for fifo module
module fifo_tb;
    // parameters
    localparam DATA_WIDTH = 32;
    localparam FIFO_DEPTH = 8;

    // clock and reset
    reg clk;
    reg rst_aL;

    // inputs
    reg valid_enq;
    reg ready_deq;
    reg [DATA_WIDTH-1:0] data_enq;

    // dut outputs
    wire ready_enq_dut;
    wire valid_deq_dut;
    wire [DATA_WIDTH-1:0] data_deq_dut;

    // golden outputs
    wire ready_enq_golden;
    wire valid_deq_golden;
    wire [DATA_WIDTH-1:0] data_deq_golden;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
        forever #HALF_PERIOD clk = ~clk;
    end

    // design under test
    fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) dut (
        .clk(clk),
        .rst_aL(rst_aL),
        .valid_enq(valid_enq),
        .ready_deq(ready_deq),
        .data_enq(data_enq),
        .ready_enq(ready_enq_dut),
        .valid_deq(valid_deq_dut),
        .data_deq(data_deq_dut)
    );

    // golden model
    fifo_golden #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) golden (
        .clk(clk),
        .rst_aL(rst_aL),
        .valid_enq(valid_enq),
        .ready_deq(ready_deq),
        .data_enq(data_enq),
        .ready_enq(ready_enq_golden),
        .valid_deq(valid_deq_golden),
        .data_deq(data_deq_golden)
    );

    integer num_random_tests_passed = 0;
    integer num_random_tests = 0;
    integer num_directed_tests_passed = 0;
    integer num_directed_tests = 0;

    // task to check random testcase
    task random_testcase();
        num_random_tests++;
        // assign random values to inputs
        valid_enq = $urandom();
        ready_deq = $urandom();
        data_enq = $urandom();
        // check if dut output matches golden output
        #CLOCK_PERIOD;
        if ({ready_enq_dut, valid_deq_dut, data_deq_dut} === {ready_enq_golden, valid_deq_golden, data_deq_golden}) begin
            num_random_tests_passed++;
            $display("Test case passed: valid_enq = %0d, ready_deq = %0d, data_enq = %0d, ready_enq_dut = %0d, valid_deq_dut = %0d, data_deq_dut = %0d, ready_enq_golden = %0d, valid_deq_golden = %0d, data_deq_golden = %0d", valid_enq, ready_deq, data_enq, ready_enq_dut, valid_deq_dut, data_deq_dut, ready_enq_golden, valid_deq_golden, data_deq_golden);
        end else begin
            $display("Test case failed: valid_enq = %0d, ready_deq = %0d, data_enq = %0d, ready_enq_dut = %0d, valid_deq_dut = %0d, data_deq_dut = %0d, ready_enq_golden = %0d, valid_deq_golden = %0d, data_deq_golden = %0d", valid_enq, ready_deq, data_enq, ready_enq_dut, valid_deq_dut, data_deq_dut, ready_enq_golden, valid_deq_golden, data_deq_golden);
        end
    endtask

    // task to display test results
    task display_test_results();
        if (num_random_tests_passed == num_random_tests) begin
            $display("ALL %0d RANDOM TESTS PASSED", num_random_tests);
        end else begin
            $display("SOME RANDOM TESTS FAILED: %0d/%0d passed", num_random_tests_passed, num_random_tests);
        end
    endtask

    // initial block to run tests
    initial begin
        @(negedge clk);
        rst_aL = 0;
        @(negedge clk);

        repeat (10) begin
            random_testcase();
        end
        display_test_results();
        $finish;
    end
endmodule