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
    reg enq_valid;
    reg deq_ready;
    reg [DATA_WIDTH-1:0] enq_data;

    // dut outputs
    wire enq_ready_dut;
    wire deq_valid_dut;
    wire [DATA_WIDTH-1:0] deq_data_dut;

    // golden outputs
    wire enq_ready_golden;
    wire deq_valid_golden;
    wire [DATA_WIDTH-1:0] deq_data_golden;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
        forever #HALF_PERIOD clk = ~clk;
    end

    // design under test
    fifo #(.ENTRY_WIDTH(DATA_WIDTH), .N_ENTRIES(FIFO_DEPTH)) dut (
        .clk(clk),
        .rst_aL(rst_aL),
        .enq_valid(enq_valid),
        .deq_ready(deq_ready),
        .enq_data(enq_data),
        .enq_ready(enq_ready_dut),
        .deq_valid(deq_valid_dut),
        .deq_data(deq_data_dut)
    );

    // golden model
    fifo_golden #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) golden (
        .clk(clk),
        .rst_aL(rst_aL),
        .enq_valid(enq_valid),
        .deq_ready(deq_ready),
        .enq_data(enq_data),
        .enq_ready(enq_ready_golden),
        .deq_valid(deq_valid_golden),
        .deq_data(deq_data_golden)
    );

    int num_random_tests_passed = 0;
    int num_random_tests = 0;
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    // task to check random testcase
    task random_testcase();
        num_random_tests++;
        // assign random values to inputs
        enq_valid = $urandom();
        deq_ready = $urandom();
        enq_data = $urandom();
        // check if dut output matches golden output
        #CLOCK_PERIOD;
        if ({enq_ready_dut, deq_valid_dut, deq_data_dut} === {enq_ready_golden, deq_valid_golden, deq_data_golden}) begin
            num_random_tests_passed++;
            $display("Test case passed: enq_valid = %0d, deq_ready = %0d, enq_data = %0d, enq_ready_dut = %0d, deq_valid_dut = %0d, deq_data_dut = %0d, enq_ready_golden = %0d, deq_valid_golden = %0d, deq_data_golden = %0d", enq_valid, deq_ready, enq_data, enq_ready_dut, deq_valid_dut, deq_data_dut, enq_ready_golden, deq_valid_golden, deq_data_golden);
        end else begin
            $display("Test case failed: enq_valid = %0d, deq_ready = %0d, enq_data = %0d, enq_ready_dut = %0d, deq_valid_dut = %0d, deq_data_dut = %0d, enq_ready_golden = %0d, deq_valid_golden = %0d, deq_data_golden = %0d", enq_valid, deq_ready, enq_data, enq_ready_dut, deq_valid_dut, deq_data_dut, enq_ready_golden, deq_valid_golden, deq_data_golden);
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