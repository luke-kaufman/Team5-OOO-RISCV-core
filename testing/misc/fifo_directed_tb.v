`include "golden/misc/fifo_golden.sv"
`include "misc/fifo.v"

// directed testbench for fifo modules
module fifo_directed_tb #(
    parameter N_RANDOM_TESTS = 10,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8,
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH),
    localparam CTR_WIDTH = PTR_WIDTH + 1
);
    // clock and reset
    reg clk;
    reg rst_aL;

    // inputs
    reg ready_deq;
    reg valid_enq;
    reg [DATA_WIDTH-1:0] data_enq;

    // outputs
    wire ready_enq;
    wire valid_deq;
    wire [DATA_WIDTH-1:0] data_deq;
    wire [PTR_WIDTH-1:0] count; // for debugging

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
        forever #HALF_PERIOD clk = ~clk;
    end

    // design under test (dut)
    fifo_golden #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),

        .ready_deq(ready_deq),
        .valid_enq(valid_enq),
        .data_enq(data_enq),
        
        .ready_enq(ready_enq),
        .valid_deq(valid_deq),
        .data_deq(data_deq),

        .count(count) // for debugging
    );
    
    integer num_directed_tests_passed = 0;
    integer num_directed_tests = 0;

    initial begin
        $dumpfile("fifo_directed_tb.vcd");
        $dumpvars(0, fifo_directed_tb);
        $monitor($time, " clk = %b, rst_aL = %b, ready_deq = %b, valid_enq = %b, data_enq = %h, ready_enq = %b, valid_deq = %b, data_deq = %h", clk, rst_aL, ready_deq, valid_enq, data_enq, ready_enq, valid_deq, data_deq);
        // reset the design
        @(negedge clk);
        rst_aL = 0;
        valid_enq = 0;
        ready_deq = 0;
        data_enq = 0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst_aL = 1;
        
        // directed testcase 1: enqueue entry to empty fifo, don't try to dequeue
        @(negedge clk);
        valid_enq = 1;
        ready_deq = 0;
        data_enq = 32'h12345678;
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and output data should be the data just enqueued,
        // - and the count should be 1
        if ({ready_enq, valid_deq, data_deq} === {1'b1, 1'b1, 32'h12345678} && count == 1) begin
            $display("Directed test 1 PASSED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 1);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 1 FAILED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 1);
        end
        num_directed_tests++;
        // clear up the inputs
        valid_enq = 0;
        ready_deq = 0;
        data_enq = 0;
        
        // directed testcase 2: enqueue entry to fifo with one entry, don't try to dequeue
        @(negedge clk);
        valid_enq = 1;
        ready_deq = 0;
        data_enq = 32'h87654321;
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and output data should be the data enqueued in testcase 1,
        // - and the count should be 2
        if ({ready_enq, valid_deq, data_deq} === {1'b1, 1'b1, 32'h12345678} && count == 2) begin
            $display("Directed test 2 PASSED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 2);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 2 FAILED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 2);
        end
        num_directed_tests++;
        // clear up the inputs
        valid_enq = 0;
        ready_deq = 0;
        data_enq = 0;

        // directed testcase 3: enqueue entry to fifo with two entries, don't try to dequeue
        @(negedge clk);
        valid_enq = 1;
        ready_deq = 0;
        data_enq = 32'habcdef01;
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and output data should be the data enqueued in testcase 1,
        // - and the count should be 3
        if ({ready_enq, valid_deq, data_deq} === {1'b1, 1'b1, 32'h12345678} && count == 3) begin
            $display("Directed test 3 PASSED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 3);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 3 FAILED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 3);
        end
        num_directed_tests++;
        // clear up the inputs
        valid_enq = 0;
        ready_deq = 0;
        data_enq = 0;

        // directed testcase 4: don't try to enqueue, dequeue entry from fifo with three entries
        @(negedge clk);
        valid_enq = 0;
        ready_deq = 1;
        data_enq = 32'h12345678;
        if (data_deq !== 32'h12345678 || count == 3) begin
            $display("Directed test 4 FAILED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h12345678, 3);
        end
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and dequeued data should be the data enqueued in testcase 1,
        // - and the count should be 2
        if ({ready_enq, valid_deq, data_deq} === {1'b1, 1'b1, 32'h87654321} && count == 2) begin
            $display("Directed test 4 PASSED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h87654321, 2);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 4 FAILED at time %0t: actual (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d), expected (ready_enq = %b, valid_deq = %b, data_deq = %h, count = %0d)", $time, ready_enq, valid_deq, data_deq, count, 1'b1, 1'b1, 32'h87654321, 2);
        end
        num_directed_tests++;
        // clear up the inputs
        valid_enq = 0;
        ready_deq = 0;
        data_enq = 0;

        if (num_directed_tests_passed == num_directed_tests) begin
            $display("ALL %0d DIRECTED TESTS PASSED", num_directed_tests);
        end else begin
            $display("SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed, num_directed_tests);
        end
        $finish;
    end
endmodule
