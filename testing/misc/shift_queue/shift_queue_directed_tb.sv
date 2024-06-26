`include "golden/misc/shift_queue_golden.sv"
`include "misc/shift_queue.v"

module shift_queue_directed_tb #(
    parameter DEBUG = 0,
    parameter N_TESTCASES = 100,
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
        state_t init_state;
        input_t inputs;
        output_t expected_outputs;
        state_t expected_next_state;
    } test_vector_t;

    int num_testcases = 0;
    int num_testcases_passed = 0;
    test_vector_t test_vectors[1:N_TESTCASES];
    bit testcases_passed[1:N_TESTCASES];
    initial begin
        // init_state (entry_reg = bd17, enq_up_down_counter = 100)
        // inputs     (enq_valid = 1, enq_data = f, deq_ready = 1, deq_sel_onehot = 0010, wr_en = 1111, wr_data = 7cb7)
        // next_state (entry_reg = f7c7, enq_up_down_counter = 100)
        test_vectors[1] = '{
            init_state: '{
                entry_reg: 16'hb_d_1_7,
                enq_up_down_counter: 3'b100
            },
            inputs: '{
                enq_valid: 1'b1,
                enq_data: 4'hf,
                deq_ready: 1'b1,
                deq_sel_onehot: 4'b0010,
                wr_en: 4'b1111,
                wr_data: 16'h7cb7
            },
            expected_outputs: '{

            },
            expected_next_state: '{
                entry_reg: 16'hf_7_c_7,
                enq_up_down_counter: 3'b100
            }
        };
        // init_state (entry_reg = 5425, enq_up_down_counter = 100)
        // inputs     (enq_valid = 1, enq_data = b, deq_ready = 1, deq_sel_onehot = 1000, wr_en = 0101, wr_data = d813)
        // next_state (entry_reg = b823, enq_up_down_counter = 100)
        test_vectors[2] = '{
            init_state: '{
                entry_reg: 16'h5_4_2_5,
                enq_up_down_counter: 3'b100
            },
            inputs: '{
                enq_valid: 1'b1,
                enq_data: 4'hb,
                deq_ready: 1'b1,
                deq_sel_onehot: 4'b1000,
                wr_en: 4'b0101,
                wr_data: 16'hd813
            },
            expected_outputs: '{

            },
            expected_next_state: '{
                entry_reg: 16'hb_8_2_3,
                enq_up_down_counter: 3'b100
            }
        };
    end

    // dut i/o
    bit rst_aL = 1;
    bit init = 0;
    test_vector_t tv;
    input_t inputs;
    wire output_t observed_outputs;
    wire output_t expected_outputs;
    wire state_t observed_next_state;
    wire state_t expected_next_state;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    bit clk = 1; // posedge at t = 0 (mod 10) (except t = 0), negedge at t = 5 (mod 10)
    initial forever #HALF_PERIOD clk = ~clk;

    shift_queue #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),
        // init state
        .init(init),
        .init_entry_reg_state(tv.init_state.entry_reg),
        .init_enq_up_down_counter_state(tv.init_state.enq_up_down_counter),
        // inputs
        .enq_valid(tv.inputs.enq_valid),
        .enq_data(tv.inputs.enq_data),
        .deq_ready(tv.inputs.deq_ready),
        .deq_sel_onehot(tv.inputs.deq_sel_onehot),
        .wr_en(tv.inputs.wr_en),
        .wr_data(tv.inputs.wr_data),
        // dut outputs
        .enq_ready(dut_outputs.enq_ready),
        .deq_valid(dut_outputs.deq_valid),
        .deq_data(dut_outputs.deq_data),
        .entry_douts(dut_outputs.entry_douts),
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
        // init state
        .init(init),
        .init_entry_reg_state(tv.init_state.entry_reg),
        .init_enq_up_down_counter_state(tv.init_state.enq_up_down_counter),
        // inputs
        .enq_valid(tv.inputs.enq_valid),
        .enq_data(tv.inputs.enq_data),
        .deq_ready(tv.inputs.deq_ready),
        .deq_sel_onehot(tv.inputs.deq_sel_onehot),
        .wr_en(tv.inputs.wr_en),
        .wr_data(tv.inputs.wr_data),
        // golden outputs
        .enq_ready(golden_outputs.enq_ready),
        .deq_valid(golden_outputs.deq_valid),
        .deq_data(golden_outputs.deq_data),
        .entry_douts(golden_outputs.entry_douts),
        // golden state
        .current_entry_reg_state(golden_state.entry_reg),
        .current_enq_up_down_counter_state(golden_state.enq_up_down_counter)
    );

    function void check_output(int i);
        if ((dut_outputs !== golden_outputs) || DEBUG) begin
            $display("Testcase %0d dut_outputs is %0s:\n\
                    init_state     (entry_reg = %h, enq_up_down_counter = %b)\n\
                    inputs         (enq_valid = %b, enq_data = %h, deq_ready = %b, deq_sel_onehot = %b, wr_en = %b, wr_data = %h)\n\
                    golden_outputs (enq_ready = %b, deq_valid = %b, deq_data = %h, entry_douts = %h)\n\
                    dut_outputs    (enq_ready = %b, deq_valid = %b, deq_data = %h, entry_douts = %h)",
                    i, (dut_outputs !== golden_outputs) ? "wrong" : "correct",
                    tv.init_state.entry_reg, tv.init_state.enq_up_down_counter,
                    tv.inputs.enq_valid, tv.inputs.enq_data, tv.inputs.deq_ready, tv.inputs.deq_sel_onehot, tv.inputs.wr_en, tv.inputs.wr_data,
                    golden_outputs.enq_ready, golden_outputs.deq_valid, golden_outputs.deq_data, golden_outputs.entry_douts,
                    dut_outputs.enq_ready, dut_outputs.deq_valid, dut_outputs.deq_data, dut_outputs.entry_douts);
        end
        if (dut_outputs !== golden_outputs) begin
            testcases_passed[i] = 0;
        end
    endfunction

    function void check_next_state(int i);
        if ((dut_state !== golden_state) || DEBUG) begin
            $display("Testcase %0d dut_next_state is %0s:\n\
                    init_state        (entry_reg = %h, enq_up_down_counter = %b)\n\
                    inputs            (enq_valid = %b, enq_data = %h, deq_ready = %b, deq_sel_onehot = %b, wr_en = %b, wr_data = %h)\n\
                    golden_next_state (entry_reg = %h, enq_up_down_counter = %b)\n\
                    dut_next_state    (entry_reg = %h, enq_up_down_counter = %b)",
                    i, (dut_state !== golden_state) ? "wrong" : "correct",
                    tv.init_state.entry_reg, tv.init_state.enq_up_down_counter,
                    tv.inputs.enq_valid, tv.inputs.enq_data, tv.inputs.deq_ready, tv.inputs.deq_sel_onehot, tv.inputs.wr_en, tv.inputs.wr_data,
                    golden_state.entry_reg, golden_state.enq_up_down_counter,
                    dut_state.entry_reg, dut_state.enq_up_down_counter);
        end
        if (dut_state !== golden_state) begin
            testcases_passed[i] = 0;
        end
    endfunction

    initial begin
        // main test loop
        for (int i = 1; i <= N_TESTCASES; i++) begin
            num_testcases++;
            testcases_passed[i] = 1;
            @(negedge clk);
            tv.init_state = test_vectors[i].init_state;
            init = 1; // initialize state at t = 5 (mod 10)
            #1;
            init = 0;
            tv.inputs = test_vectors[i].inputs; // drive input at t = 6 (mod 10)
            #1;
            check_output(i); // check output at t = 7 (mod 10)
            @(posedge clk);
            #1;
            check_next_state(i); // check state at t = 11 (mod 10)
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

    initial begin
        // $monitor("deq_data = %h\
        //           deq_sel_onehot = %b\
        //           entry_douts = %h",
        //           dut.deq_data,
        //           dut.deq_sel_onehot,
        //           dut.entry_douts);
    end
endmodule
