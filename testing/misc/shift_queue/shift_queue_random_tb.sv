`include "golden/misc/shift_queue_golden.sv"
`include "misc/shift_queue.v"

module shift_queue_random_tb #(
    parameter DEBUG = 0,
    parameter N_TESTCASES = 10000,
    parameter N_ENTRIES = 4,
    parameter ENTRY_WIDTH = 4,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1
);
    typedef struct packed {
        reg [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_reg;
        reg [CTR_WIDTH-1:0] enq_up_down_counter;
    } state_t;
    typedef struct packed {
        reg enq_valid;
        reg [ENTRY_WIDTH-1:0] enq_data;
        reg deq_ready;
        reg [N_ENTRIES-1:0] deq_sel_onehot;
        reg [N_ENTRIES-1:0] wr_en;
        reg [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] wr_data;
    } input_t;
    typedef struct packed {
        reg enq_ready;
        reg deq_valid;
        reg [ENTRY_WIDTH-1:0] deq_data;
        reg [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts;
    } output_t;
    typedef struct packed {
        input_t input_stimuli;
    } test_vector_t;

    int num_testcases = 0;
    int num_testcases_passed = 0;
    test_vector_t test_vectors[1:N_TESTCASES];
    bit testcases_passed[1:N_TESTCASES];
    bit [N_ENTRIES-1:0] temp_one_hot;
    int temp_one_hot_decimal;
    initial begin
        for (int i = 1; i <= N_TESTCASES; i++) begin
            for (int j = 0; j < $bits(test_vector_t); j += 32) begin
                test_vectors[i][j+:32] = $urandom();
            end

            temp_one_hot_decimal = $urandom_range(0, N_ENTRIES-1);
            temp_one_hot = 1 << temp_one_hot_decimal;
            test_vectors[i].input_stimuli.deq_sel_onehot = temp_one_hot;
        end
    end

    // dut i/o
    bit clk = 1;
    reg rst_aL;
    // reg init;
    test_vector_t test_vector;
    wire output_t dut_output;
    wire output_t golden_output;
    wire state_t dut_state;
    wire state_t golden_state;
    state_t dut_prev_state;
    state_t golden_prev_state;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    initial forever #HALF_PERIOD clk = ~clk;

    shift_queue #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),
        // input stimuli
        .enq_valid(test_vector.input_stimuli.enq_valid),
        .enq_data(test_vector.input_stimuli.enq_data),
        .deq_ready(test_vector.input_stimuli.deq_ready),
        .deq_sel_onehot(test_vector.input_stimuli.deq_sel_onehot),
        .wr_en(test_vector.input_stimuli.wr_en),
        .wr_data(test_vector.input_stimuli.wr_data),
        // dut output
        .enq_ready(dut_output.enq_ready),
        .deq_valid(dut_output.deq_valid),
        .deq_data(dut_output.deq_data),
        .entry_douts(dut_output.entry_douts),
        // dut state
        .current_entry_reg_state(dut_state.entry_reg),
        .current_enq_up_down_counter_state(dut_state.enq_up_down_counter)
    );
    shift_queue_golden #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH)
    ) golden (
        .clk(clk),
        .rst_aL(rst_aL),
        // input stimuli
        .enq_valid(test_vector.input_stimuli.enq_valid),
        .enq_data(test_vector.input_stimuli.enq_data),
        .deq_ready(test_vector.input_stimuli.deq_ready),
        .deq_sel_onehot(test_vector.input_stimuli.deq_sel_onehot),
        .wr_en(test_vector.input_stimuli.wr_en),
        .wr_data(test_vector.input_stimuli.wr_data),
        // golden output
        .enq_ready(golden_output.enq_ready),
        .deq_valid(golden_output.deq_valid),
        .deq_data(golden_output.deq_data),
        .entry_douts(golden_output.entry_douts),
        // golden state
        .current_entry_reg_state(golden_state.entry_reg),
        .current_enq_up_down_counter_state(golden_state.enq_up_down_counter)
    );

    function void check_output(int i);
        if ((dut_output !== golden_output) || DEBUG) begin
            // $display("Testcase %0d dut_output is %s:
            //         golden_state      (entry_reg = %h, enq_up_down_counter = %b)
            //         dut_state         (entry_reg = %h, enq_up_down_counter = %b)
            //         input_stimuli     (enq_valid = %b, enq_data = %h, deq_ready = %b, deq_sel_onehot = %b, wr_en = %b, wr_data = %h)
            //         golden_output     (enq_ready = %b, deq_valid = %b, deq_data = %h, entry_douts = %h)
            //         dut_output        (enq_ready = %b, deq_valid = %b, deq_data = %h, entry_douts = %h)",
            //         i, (dut_output !== golden_output) ? "wrong" : "correct",
            //         golden_state.entry_reg, golden_state.enq_up_down_counter,
            //         dut_state.entry_reg, dut_state.enq_up_down_counter,
            //         test_vector.input_stimuli.enq_valid, test_vector.input_stimuli.enq_data, test_vector.input_stimuli.deq_ready, test_vector.input_stimuli.deq_sel_onehot, test_vector.input_stimuli.wr_en, test_vector.input_stimuli.wr_data,
            //         golden_output.enq_ready, golden_output.deq_valid, golden_output.deq_data, golden_output.entry_douts,
            //         dut_output.enq_ready, dut_output.deq_valid, dut_output.deq_data, dut_output.entry_douts);
            $display("wrong");
        end
        if (dut_output !== golden_output) begin
            testcases_passed[i] = 0;
        end
    endfunction

    function void check_state(int i);
        if ((dut_state !== golden_state) || DEBUG) begin
            // $display("Testcase %0d dut_next_state is %s:
            //         golden_state      (entry_reg = %h, enq_up_down_counter = %b)
            //         dut_state         (entry_reg = %h, enq_up_down_counter = %b)
            //         input_stimuli     (enq_valid = %b, enq_data = %h, deq_ready = %b, deq_sel_onehot = %b, wr_en = %b, wr_data = %h)
            //         golden_output     (enq_ready = %b, deq_valid = %b, deq_data = %h, entry_douts = %h)
            //         dut_output        (enq_ready = %b, deq_valid = %b, deq_data = %h, entry_douts = %h)",
            //         i, (dut_state !== golden_state) ? "wrong" : "correct",
            //         golden_state.entry_reg, golden_state.enq_up_down_counter,
            //         dut_state.entry_reg, dut_state.enq_up_down_counter,
            //         test_vector.input_stimuli.enq_valid, test_vector.input_stimuli.enq_data, test_vector.input_stimuli.deq_ready, test_vector.input_stimuli.deq_sel_onehot, test_vector.input_stimuli.wr_en, test_vector.input_stimuli.wr_data,
            //         golden_output.enq_ready, golden_output.deq_valid, golden_output.deq_data, golden_output.entry_douts,
            //         dut_output.enq_ready, dut_output.deq_valid, dut_output.deq_data, dut_output.entry_douts);
            $display("wrong");
        end
        if (dut_state !== golden_state) begin
            testcases_passed[i] = 0;
        end
    endfunction

    initial begin
        rst_aL = 0;
        #1;
        rst_aL = 1;
        // main test loop
        for (int i = 1; i <= N_TESTCASES; i++) begin
            num_testcases++;
            testcases_passed[i] = 1;
            @(negedge clk);
            test_vector.input_stimuli = test_vectors[i].input_stimuli; // drive input at t = 5 (mod 10)
            #1;
            check_output(i); // check output at t = 6 (mod 10)
            dut_prev_state = dut_state;
            golden_prev_state = golden_state;
            @(posedge clk);
            #1;
            check_state(i); // check state at t = 11 (mod 10)
        end
        // display results
        for (int i = 1; i <= N_TESTCASES; i++) begin
            if (testcases_passed[i] === 0) begin
                $display("Testcase %0d failed", i);
            end else begin
                num_testcases_passed++;
            end
        end
        $display("%0d/%0d random testcases passed", num_testcases_passed, num_testcases);
        $finish;
    end
endmodule
