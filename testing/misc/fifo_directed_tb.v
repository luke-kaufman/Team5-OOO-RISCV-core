`include "golden/misc/fifo_golden.sv"
`include "misc/fifo.v"

// directed testbench for fifo modules
module fifo_directed_tb #(
    parameter N_RANDOM_TESTS = 10,
    parameter ENTRY_WIDTH = 32,
    parameter N_ENTRIES = 8,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1
);
    // clock and reset
    reg clk;
    reg rst_aL;

    // inputs
    reg deq_ready;
    reg enq_valid;
    reg [ENTRY_WIDTH-1:0] enq_data;

    // outputs
    wire enq_ready;
    wire deq_valid;
    wire [ENTRY_WIDTH-1:0] deq_data;
    wire [PTR_WIDTH-1:0] count; // for debugging

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial begin
        clk = 0;
        forever #HALF_PERIOD clk = ~clk;
    end

    // design under test (dut)
    fifo #(
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_ENTRIES(N_ENTRIES)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),

        .deq_ready(deq_ready),
        .enq_valid(enq_valid),
        .enq_data(enq_data),
        
        .enq_ready(enq_ready),
        .deq_valid(deq_valid),
        .deq_data(deq_data),

        .count(count) // for debugging
    );
    
    int num_directed_tests_passed = 0;
    int num_directed_tests = 0;

    initial begin
        $dumpfile("fifo_directed_tb.vcd");
        $dumpvars(0, fifo_directed_tb);
        $monitor($time, " clk = %b, rst_aL = %b, deq_ready = %b, enq_valid = %b, enq_data = %h, enq_ready = %b, deq_valid = %b, deq_data = %h", clk, rst_aL, deq_ready, enq_valid, enq_data, enq_ready, deq_valid, deq_data);
        // reset the design
        @(negedge clk);
        rst_aL = 0;
        enq_valid = 0;
        deq_ready = 0;
        enq_data = 0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst_aL = 1;
        
        // directed testcase 1: enqueue entry to empty fifo, don't try to dequeue
        @(negedge clk);
        enq_valid = 1;
        deq_ready = 0;
        enq_data = 32'h12345678;
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and output data should be the data just enqueued,
        // - and the count should be 1
        if ({enq_ready, deq_valid, deq_data} === {1'b1, 1'b1, 32'h12345678} && count == 1) begin
            $display("Directed test 1 PASSED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 1);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 1 FAILED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 1);
        end
        num_directed_tests++;
        // clear up the inputs
        enq_valid = 0;
        deq_ready = 0;
        enq_data = 0;
        
        // directed testcase 2: enqueue entry to fifo with one entry, don't try to dequeue
        @(negedge clk);
        enq_valid = 1;
        deq_ready = 0;
        enq_data = 32'h87654321;
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and output data should be the data enqueued in testcase 1,
        // - and the count should be 2
        if ({enq_ready, deq_valid, deq_data} === {1'b1, 1'b1, 32'h12345678} && count == 2) begin
            $display("Directed test 2 PASSED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 2);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 2 FAILED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 2);
        end
        num_directed_tests++;
        // clear up the inputs
        enq_valid = 0;
        deq_ready = 0;
        enq_data = 0;

        // directed testcase 3: enqueue entry to fifo with two entries, don't try to dequeue
        @(negedge clk);
        enq_valid = 1;
        deq_ready = 0;
        enq_data = 32'habcdef01;
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and output data should be the data enqueued in testcase 1,
        // - and the count should be 3
        if ({enq_ready, deq_valid, deq_data} === {1'b1, 1'b1, 32'h12345678} && count == 3) begin
            $display("Directed test 3 PASSED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 3);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 3 FAILED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 3);
        end
        num_directed_tests++;
        // clear up the inputs
        enq_valid = 0;
        deq_ready = 0;
        enq_data = 0;

        // directed testcase 4: don't try to enqueue, dequeue entry from fifo with three entries
        @(negedge clk);
        enq_valid = 0;
        deq_ready = 1;
        enq_data = 32'h12345678;
        if (deq_data !== 32'h12345678 || count != 3) begin
            $display("Directed test 4 FAILED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h12345678, 3);
        end
        @(negedge clk);
        // check the output:
        // - fifo should be ready to enqueue and valid to dequeue,
        // - and dequeued data should be the data enqueued in testcase 1,
        // - and the count should be 2
        if ({enq_ready, deq_valid, deq_data} === {1'b1, 1'b1, 32'h87654321} && count == 2) begin
            $display("Directed test 4 PASSED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h87654321, 2);
            num_directed_tests_passed++;
        end else begin
            $display("Directed test 4 FAILED at time %0t: actual (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d), expected (enq_ready = %b, deq_valid = %b, deq_data = %h, count = %0d)", $time, enq_ready, deq_valid, deq_data, count, 1'b1, 1'b1, 32'h87654321, 2);
        end
        num_directed_tests++;
        // clear up the inputs
        enq_valid = 0;
        deq_ready = 0;
        enq_data = 0;

        // directed testcase 5: don't try to enqueue, dequeue entry from fifo with two entries
        @(negedge clk);
        enq_valid = 0;
        deq_ready = 1;
        enq_data = 32'h12345678;
        

        if (num_directed_tests_passed == num_directed_tests) begin
            $display("ALL %0d DIRECTED TESTS PASSED", num_directed_tests);
        end else begin
            $display("SOME DIRECTED TESTS FAILED: %0d/%0d passed", num_directed_tests_passed, num_directed_tests);
        end
        $finish;
    end
endmodule
