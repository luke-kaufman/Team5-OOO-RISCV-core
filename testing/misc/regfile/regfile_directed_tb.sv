`include "golden/misc/regfile_golden.sv"
`include "misc/regfile.sv"

module regfile_directed_tb #(
    parameter DEBUG = 1,
    parameter N_MAX_TESTCASES = 10000,
    parameter N_ENTRIES = 4,
    parameter ENTRY_WIDTH = 4,
	parameter N_READ_PORTS = 2,
	parameter N_WRITE_PORTS = 2,
    localparam PTR_WIDTH = $clog2(N_ENTRIES)
);
    typedef struct packed {
        reg [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] regfile;
    } state_t;
    typedef struct packed {
		reg [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr;

		reg [N_WRITE_PORTS-1:0] wr_en;
		reg [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr;
		reg [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data;
    } input_t;
    typedef struct packed {
		reg [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data;
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
        // testcase 1: read from different entries, write to different entries
        test_vectors[1] = '{
            init_state: '{
                regfile: 16'hd_c_b_a
            },
            input_stimuli: '{
				rd_addr: 4'b01_00,
				wr_en: 2'b1_1,
				wr_addr: 4'b11_10,
				wr_data: 8'hf_e
            },
            expected_output: '{
                rd_data: 8'hb_a
            },
            expected_next_state: '{
                regfile: 16'hf_e_b_a
            }
        };

        // testcase 2: read from the same entry being written to
        test_vectors[2] = '{
            init_state: '{
                regfile: 16'hd_c_b_a
            },
            input_stimuli: '{
				rd_addr: 4'b01_00,
				wr_en: 2'b1_1,
				wr_addr: 4'b01_00,
				wr_data: 8'hf_e
            },
            expected_output: '{
                rd_data: 8'hb_a
            },
            expected_next_state: '{
                regfile: 16'hd_c_f_e
            }
        };

        // testcase 3: write to same entries (SHOULD THROW ERROR)
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

    regfile #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_READ_PORTS(N_READ_PORTS),
        .N_WRITE_PORTS(N_WRITE_PORTS)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),

        // input stimuli
		.rd_addr(test_vector.input_stimuli.rd_addr),

		.wr_en(test_vector.input_stimuli.wr_en),
		.wr_addr(test_vector.input_stimuli.wr_addr),
		.wr_data(test_vector.input_stimuli.wr_data),

        // observed output
		.rd_data(observed_output.rd_data),

        // initial state
        .init(init),
        .init_regfile_state(test_vector.init_state.regfile),

        // observed next state
        .current_regfile_state(observed_next_state.regfile)
    );

    function void check_output(int i);
        if ((observed_output !== test_vector.expected_output) || DEBUG) begin
            $display(
                "Testcase %0d observed output is %0s:\n\
                init_state (regfile = %h)\n\
                inputs (rd_addr = %h, wr_en = %b, wr_addr = %h, wr_data = %h)\n\
                expected_outputs (rd_data = %h)\n\
                observed_outputs (rd_data = %h)\n",
                i, (observed_output !== test_vector.expected_output) ? "wrong" : "correct",
                test_vector.init_state.regfile,
                test_vector.input_stimuli.rd_addr, test_vector.input_stimuli.wr_en, test_vector.input_stimuli.wr_addr, test_vector.input_stimuli.wr_data,
                test_vector.expected_output.rd_data,
                observed_output.rd_data
            );
        end
        if (observed_output !== test_vector.expected_output) begin
            testcases_passed[i] = 0;
        end
    endfunction

    function void check_next_state(int i);
        if ((observed_next_state !== test_vector.expected_next_state) || DEBUG) begin
            $display(
                "Testcase %0d observed next state is %0s:\n\
                init_state (regfile = %h)\n\
                inputs: (rd_addr = %h, wr_en = %b, wr_addr = %h, wr_data = %h)\n\
                expected_next_state (regfile = %h)\n\
                observed_next_state (regfile = %h)\n",
                i, (observed_next_state !== test_vector.expected_next_state) ? "wrong" : "correct",
                test_vector.init_state.regfile,
                test_vector.input_stimuli.rd_addr, test_vector.input_stimuli.wr_en, test_vector.input_stimuli.wr_addr, test_vector.input_stimuli.wr_data,
                test_vector.expected_next_state.regfile,
                observed_next_state.regfile
            );
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
