`include "golden/misc/fifo_golden.sv"
`include "misc/fifo.v"

module fifo_directed_tb #(
    parameter DEBUG = 0,
    parameter N_MAX_TESTCASES = 10000,
    parameter N_ENTRIES = 4,
    parameter ENTRY_WIDTH = 4,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1
);
    typedef struct packed {
        reg [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_reg;
        reg [CTR_WIDTH-1:0] enq_up_counter;
        reg [CTR_WIDTH-1:0] deq_up_counter;
    } state_t;
    typedef struct packed {
        reg enq_valid;
        reg [ENTRY_WIDTH-1:0] enq_data;
        reg deq_ready;
    } input_t;
    typedef struct packed {
        reg enq_ready;
        reg deq_valid;
        reg [ENTRY_WIDTH-1:0] deq_data;
    } output_t;
    typedef struct packed {
        state_t init_state;
        input_t input_stimuli;
        output_t expected_output;
        state_t expected_next_state;
    } test_vector_t;

    int num_testcases = 0;
    int num_testcases_passed = 0;
    test_vector_t test_vectors[1:N_MAX_TESTCASES];
    bit testcases_passed[1:N_MAX_TESTCASES];
    // directed testcases
    initial begin
        // testcase 1: enqueue entry to empty fifo, don't try to dequeue
        test_vectors[1] = '{
            init_state: '{
                entry_reg: 16'h0_0_0_0,
                enq_up_counter: 3'b000,
                deq_up_counter: 3'b000
            },
            input_stimuli: '{
                enq_valid: 1'b1,
                enq_data: 4'h1,
                deq_ready: 1'b0
            },
            expected_output: '{
                enq_ready: 1'b1,
                deq_valid: 1'b0,
                deq_data: 4'h0
            },
            expected_next_state: '{
                entry_reg: 16'h0_0_0_1,
                enq_up_counter: 3'b001,
                deq_up_counter: 3'b000
            }
        };
        // testcase 2: enqueue entry to fifo with one entry, don't try to dequeue
        test_vectors[2] = '{
            init_state: '{
                entry_reg: 16'h0_0_0_f,
                enq_up_counter: 3'b001,
                deq_up_counter: 3'b000
            },
            input_stimuli: '{
                enq_valid: 1'b1,
                enq_data: 4'h2,
                deq_ready: 1'b0
            },
            expected_output: '{
                enq_ready: 1'b1,
                deq_valid: 1'b1,
                deq_data: 4'hf
            },
            expected_next_state: '{
                entry_reg: 16'h0_0_2_f,
                enq_up_counter: 3'b010,
                deq_up_counter: 3'b000
            }
        };
        // testcase 3: enqueue entry to fifo with two entries, don't try to dequeue
        test_vectors[3] = '{
            init_state: '{
                entry_reg: 16'h0_0_0_f,
                enq_up_counter: 3'b010,
                deq_up_counter: 3'b000
            },
            input_stimuli: '{
                enq_valid: 1'b1,
                enq_data: 4'h3,
                deq_ready: 1'b0
            },
            expected_output: '{
                enq_ready: 1'b1,
                deq_valid: 1'b1,
                deq_data: 4'hf
            },
            expected_next_state: '{
                entry_reg: 16'h0_3_0_f,
                enq_up_counter: 3'b011,
                deq_up_counter: 3'b000
            }
        };
        // testcase 4: enqueue entry to fifo with three entries, don't try to dequeue
        test_vectors[4] = '{
            init_state: '{
                entry_reg: 16'h0_e_0_f,
                enq_up_counter: 3'b011,
                deq_up_counter: 3'b000
            },
            input_stimuli: '{
                enq_valid: 1'b1,
                enq_data: 4'h4,
                deq_ready: 1'b0
            },
            expected_output: '{
                enq_ready: 1'b1,
                deq_valid: 1'b1,
                deq_data: 4'hf
            },
            expected_next_state: '{
                entry_reg: 16'h4_e_0_f,
                enq_up_counter: 3'b100,
                deq_up_counter: 3'b000
            }
        };
    end

    // dut i/o
    bit clk = 1;
    reg rst_aL;
    reg init;
    test_vector_t test_vector;
    wire output_t observed_output;
    wire state_t observed_next_state;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial forever #HALF_PERIOD clk = ~clk;

    fifo #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),
        // input stimuli
        .enq_valid(test_vector.input_stimuli.enq_valid),
        .enq_data(test_vector.input_stimuli.enq_data),
        .deq_ready(test_vector.input_stimuli.deq_ready),
        // observed output
        .enq_ready(observed_output.enq_ready),
        .deq_valid(observed_output.deq_valid),
        .deq_data(observed_output.deq_data),
        // initial state
        .init(init),
        .init_entry_reg_state(test_vector.init_state.entry_reg),
        .init_enq_up_counter_state(test_vector.init_state.enq_up_counter),
        .init_deq_up_counter_state(test_vector.init_state.deq_up_counter),
        // observed next state
        .current_entry_reg_state(observed_next_state.entry_reg),
        .current_enq_up_counter_state(observed_next_state.enq_up_counter),
        .current_deq_up_counter_state(observed_next_state.deq_up_counter)
    );

    function void check_output(int i);
        if ((observed_output !== test_vector.expected_output) || DEBUG) begin
            $display("Testcase %0d observed output is %s:
                    observed (enq_ready = %b, deq_valid = %b, deq_data = %h),
                    expected (enq_ready = %b, deq_valid = %b, deq_data = %h)",
                    i, (observed_output !== test_vector.expected_output) ? "wrong" : "correct",
                    observed_output.enq_ready, observed_output.deq_valid, observed_output.deq_data,
                    test_vector.expected_output.enq_ready, test_vector.expected_output.deq_valid, test_vector.expected_output.deq_data);
        end
        if (observed_output !== test_vector.expected_output) begin
            testcases_passed[i] = 0;
        end
    endfunction

    function void check_next_state(int i);
        if ((observed_next_state !== test_vector.expected_next_state) || DEBUG) begin
            $display("Testcase %0d observed next state is %s:
                    observed (entry_reg = %h, enq_up_counter = %b, deq_up_counter = %b),
                    expected (entry_reg = %h, enq_up_counter = %b, deq_up_counter = %b)",
                    i, (observed_next_state !== test_vector.expected_next_state) ? "wrong" : "correct",
                    observed_next_state.entry_reg, observed_next_state.enq_up_counter, observed_next_state.deq_up_counter,
                    test_vector.expected_next_state.entry_reg, test_vector.expected_next_state.enq_up_counter, test_vector.expected_next_state.deq_up_counter);
        end
        if (observed_next_state !== test_vector.expected_next_state) begin
            testcases_passed[i] = 0;
        end
    endfunction

    initial begin
        // main test loop
        for (int i = 1; i <= N_MAX_TESTCASES; i++) begin
            if (test_vectors[i] === 'x) break;
            num_testcases++;
            testcases_passed[i] = 1;
            @(negedge clk);
            test_vector.init_state = test_vectors[i].init_state;
            init = 1; // initialize state at t = 5 (mod 10)
            #1;
            init = 0;
            test_vector.input_stimuli = test_vectors[i].input_stimuli; // drive input at t = 6 (mod 10)
            #1;
            test_vector.expected_output = test_vectors[i].expected_output;
            check_output(i); // check output at t = 7 (mod 10)
            @(posedge clk);
            #1;
            test_vector.expected_next_state = test_vectors[i].expected_next_state;
            check_next_state(i); // check next state at t = 11 (mod 10)
        end
        // display results
        for (int i = 1; i <= N_MAX_TESTCASES; i++) begin
            if (test_vectors[i] === 'x) break;
            if (testcases_passed[i] === 0) begin
                $display("Testcase %0d failed", i);
            end else begin
                num_testcases_passed++;
            end
        end
        $display("%0d/%0d directed testcases passed", num_testcases_passed, num_testcases);
        $finish;
    end
endmodule
