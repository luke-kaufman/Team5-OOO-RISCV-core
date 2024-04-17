`include "golden/misc/fifo_ram_golden.sv"
`include "misc/fifo_ram.v"

module fifo_ram_tb #(
    parameter  int unsigned N_TESTCASES = 10000,
    parameter  int unsigned N_ENTRIES = 4,
    parameter  int unsigned ENTRY_WIDTH = 4,
    parameter  int unsigned N_READ_PORTS = 2,
	parameter  int unsigned N_WRITE_PORTS = 2,
    localparam int unsigned PTR_WIDTH = $clog2(N_ENTRIES),
    localparam int unsigned CTR_WIDTH = PTR_WIDTH + 1
);
    typedef struct packed {
        logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_reg;
        logic [CTR_WIDTH-1:0] enq_up_counter;
        logic [CTR_WIDTH-1:0] deq_up_counter;
    } state_t;
    typedef struct packed {
        logic enq_valid;
        logic [ENTRY_WIDTH-1:0] enq_data;
        logic deq_ready;
        logic [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr;
        logic [N_WRITE_PORTS-1:0] wr_en;
        logic [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr;
        logic [N_ENTRIES-1:0] [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data;
    } input_t;
    typedef struct packed {
        logic enq_ready;
        logic [PTR_WIDTH-1:0] enq_addr;
        logic deq_valid;
        logic [ENTRY_WIDTH-1:0] deq_data;
        logic [PTR_WIDTH-1:0] deq_addr;
        logic [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data;
        logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts;
    } output_t;
    typedef struct packed {
        state_t init_state;
        input_t in;
    } test_vector_t;

    int num_testcases = 0;
    int num_testcases_passed = 0;
    test_vector_t tv_arr[1:N_TESTCASES];
    bit testcases_passed[1:N_TESTCASES];

    initial begin
        automatic bit [PTR_WIDTH-1:0] n_curr_entries;
        automatic bit [CTR_WIDTH-1:0] enq_ctr;
        automatic bit [CTR_WIDTH-1:0] deq_ctr;
        automatic bit [PTR_WIDTH-1:0] enq_ptr;
        automatic bit [PTR_WIDTH-1:0] deq_ptr;
        automatic bit fifo_empty;
        automatic bit fifo_full;
        automatic bit [N_ENTRIES-1:0] valid_entries;
        automatic bit same_addr;
        for (int i = 1; i <= N_TESTCASES; i++) begin
            n_curr_entries = $urandom_range(0, N_ENTRIES);
            tv_arr[i].init_state.entry_reg = $urandom();
            tv_arr[i].init_state.deq_up_counter = $urandom();
            tv_arr[i].init_state.enq_up_counter = tv_arr[i].init_state.deq_up_counter + n_curr_entries;

            enq_ctr = tv_arr[i].init_state.enq_up_counter[CTR_WIDTH-1:0];
            deq_ctr = tv_arr[i].init_state.deq_up_counter[CTR_WIDTH-1:0];
            enq_ptr = enq_ctr[PTR_WIDTH-1:0];
            deq_ptr = deq_ctr[PTR_WIDTH-1:0];
            fifo_empty = enq_ctr == deq_ctr;
            fifo_full = (enq_ctr[PTR_WIDTH] != deq_ctr[PTR_WIDTH]) && (enq_ctr[PTR_WIDTH-1:0] == deq_ctr[PTR_WIDTH-1:0]);

            valid_entries = 0;
            if (deq_ctr <= enq_ctr) begin
                for (int j = deq_ctr; j < enq_ctr; j++) begin
                    valid_entries[j[PTR_WIDTH-1:0]] = 1;
                end
            end else begin
                for (int j = deq_ctr; j < 2*N_ENTRIES; j++) begin
                    valid_entries[j[PTR_WIDTH-1:0]] = 1;
                end
                for (int j = 0; j < enq_ctr; j++) begin
                    valid_entries[j[PTR_WIDTH-1:0]] = 1;
                end
            end

            tv_arr[i].in.enq_valid = $urandom();
            tv_arr[i].in.enq_data = $urandom();
            tv_arr[i].in.deq_ready = $urandom();

            for (int j = 0; j < N_READ_PORTS; j++) begin
                while (1) begin
                    tv_arr[i].in.rd_addr[j] = $urandom_range(0, N_ENTRIES-1);
                    if (fifo_empty || valid_entries[tv_arr[i].in.rd_addr[j]]) break;
                end
            end

            if (!fifo_empty) begin
                while (1) begin
                    for (int j = 0; j < N_WRITE_PORTS; j++) begin
                        while (1) begin
                            tv_arr[i].in.wr_en[j] = $urandom();
                            tv_arr[i].in.wr_addr[j] = $urandom_range(0, N_ENTRIES-1);
                            if (!tv_arr[i].in.wr_en[j] || valid_entries[tv_arr[i].in.wr_addr[j]]) break;
                        end
                    end
                    same_addr = 0;
                    for (int j = 0; j < N_WRITE_PORTS; j++) begin
                        for (int k = j + 1; k < N_WRITE_PORTS; k++) begin
                            if (tv_arr[i].in.wr_en[j] &&
                                tv_arr[i].in.wr_en[k] &&
                                (tv_arr[i].in.wr_addr[j] == tv_arr[i].in.wr_addr[k]))
                            begin
                                same_addr = 1;
                            end
                        end
                    end
                    if (!same_addr) break;
                end
            end else begin
                tv_arr[i].in.wr_en = 0;
                tv_arr[i].in.wr_addr = $urandom_range(0, N_ENTRIES-1);
            end

            rng#($bits(tv_arr[i].in.wr_data))::rng(tv_arr[i].in.wr_data);
        end
    end

    // dut i/o
    bit rst_aL = 1;
    bit init = 0;
    test_vector_t tv;
    input_t in;
    wire output_t dut_out;
    wire output_t gold_out;
    wire state_t dut_state;
    wire state_t gold_state;

    // clock generation
    localparam CLOCK_PERIOD = 10;
    localparam HALF_PERIOD = CLOCK_PERIOD / 2;
    bit clk = 1; // posedge at t = 0 (mod 10) (except t = 0), negedge at t = 5 (mod 10)
    initial forever #HALF_PERIOD clk = ~clk;

    fifo_ram #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_READ_PORTS(N_READ_PORTS),
        .N_WRITE_PORTS(N_WRITE_PORTS)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),
        // init state
        .init(init),
        .init_entry_reg_state(tv.init_state.entry_reg),
        .init_enq_up_counter_state(tv.init_state.enq_up_counter),
        .init_deq_up_counter_state(tv.init_state.deq_up_counter),
        // in
        .enq_valid(tv.in.enq_valid),
        .enq_data(tv.in.enq_data),
        .deq_ready(tv.in.deq_ready),
        .rd_addr(tv.in.rd_addr),
        .wr_en(tv.in.wr_en),
        .wr_addr(tv.in.wr_addr),
        .wr_data(tv.in.wr_data),
        // dut outputs
        .enq_ready(dut_out.enq_ready),
        .enq_addr(dut_out.enq_addr),
        .deq_valid(dut_out.deq_valid),
        .deq_data(dut_out.deq_data),
        .deq_addr(dut_out.deq_addr),
        .rd_data(dut_out.rd_data),
        .entry_douts(dut_out.entry_douts),
        // dut state
        .current_entry_reg_state(dut_state.entry_reg),
        .current_enq_up_counter_state(dut_state.enq_up_counter),
        .current_deq_up_counter_state(dut_state.deq_up_counter)
    );
    fifo_ram_golden #(
        .N_ENTRIES(N_ENTRIES),
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_READ_PORTS(N_READ_PORTS),
        .N_WRITE_PORTS(N_WRITE_PORTS)
    ) golden (
        .clk(clk),
        .rst_aL(rst_aL),
        // init state
        .init(init),
        .init_entry_reg_state(tv.init_state.entry_reg),
        .init_enq_up_counter_state(tv.init_state.enq_up_counter),
        .init_deq_up_counter_state(tv.init_state.deq_up_counter),
        // in
        .enq_valid(tv.in.enq_valid),
        .enq_data(tv.in.enq_data),
        .deq_ready(tv.in.deq_ready),
        .rd_addr(tv.in.rd_addr),
        .wr_en(tv.in.wr_en),
        .wr_addr(tv.in.wr_addr),
        .wr_data(tv.in.wr_data),
        // golden outputs
        .enq_ready(gold_out.enq_ready),
        .enq_addr(gold_out.enq_addr),
        .deq_valid(gold_out.deq_valid),
        .deq_data(gold_out.deq_data),
        .deq_addr(gold_out.deq_addr),
        .rd_data(gold_out.rd_data),
        .entry_douts(gold_out.entry_douts),
        // golden state
        .current_entry_reg_state(gold_state.entry_reg),
        .current_enq_up_counter_state(gold_state.enq_up_counter),
        .current_deq_up_counter_state(gold_state.deq_up_counter)
    );

    function void check_output(int i, bit DEBUG = 0);
        if ((dut_out !== gold_out) || DEBUG) begin
            $display(
"Testcase %0d dut_out is %0s at time %0t:\n\
init_state (entry_reg=%h, enq_up_counter=%b, deq_up_counter=%b)\n\
in         (enq_valid=%b, enq_data=%h, deq_ready=%b, rd_addr=%b, wr_en=%b, wr_addr=%b, wr_data=%h)\n\
gold_out   (enq_ready=%b, enq_addr=%b, deq_valid=%b, deq_data=%h, deq_addr=%b, rd_data=%h, entry_douts=%h)\n\
dut_out    (enq_ready=%b, enq_addr=%b, deq_valid=%b, deq_data=%h, deq_addr=%b, rd_data=%h, entry_douts=%h)\n",
                i, (dut_out !== gold_out) ? "wrong" : "correct", $time,
                tv.init_state.entry_reg, tv.init_state.enq_up_counter, tv.init_state.deq_up_counter,
                tv.in.enq_valid, tv.in.enq_data, tv.in.deq_ready, tv.in.rd_addr, tv.in.wr_en, tv.in.wr_addr, tv.in.wr_data,
                gold_out.enq_ready, gold_out.enq_addr, gold_out.deq_valid, gold_out.deq_data, gold_out.deq_addr, gold_out.rd_data, gold_out.entry_douts,
                dut_out.enq_ready, dut_out.enq_addr, dut_out.deq_valid, dut_out.deq_data, dut_out.deq_addr, dut_out.rd_data, dut_out.entry_douts
            );
        end
        if (dut_out !== gold_out) begin
            testcases_passed[i] = 0;
        end
    endfunction

    function void check_next_state(int i, bit DEBUG = 0);
        if ((dut_state !== gold_state) || DEBUG) begin
            $display(
"Testcase %0d dut_next_state is %0s at time %0t:\n\
init_state      (entry_reg = %h, enq_up_counter = %b, deq_up_counter = %b)\n\
in              (enq_valid = %b, enq_data = %h, deq_ready = %b, rd_addr = %b, wr_en = %b, wr_addr = %b, wr_data = %h)\n\
gold_next_state (entry_reg = %h, enq_up_counter = %b, deq_up_counter = %b)\n\
dut_next_state  (entry_reg = %h, enq_up_counter = %b, deq_up_counter = %b)\n",
                i, (dut_state !== gold_state) ? "wrong" : "correct", $time,
                tv.init_state.entry_reg, tv.init_state.enq_up_counter, tv.init_state.deq_up_counter,
                tv.in.enq_valid, tv.in.enq_data, tv.in.deq_ready, tv.in.rd_addr, tv.in.wr_en, tv.in.wr_addr, tv.in.wr_data,
                gold_state.entry_reg, gold_state.enq_up_counter, gold_state.deq_up_counter,
                dut_state.entry_reg, dut_state.enq_up_counter, dut_state.deq_up_counter
            );
        end
        if (dut_state !== gold_state) begin
            testcases_passed[i] = 0;
        end
    endfunction

    initial begin
        // main test loop
        for (int i = 1; i <= N_TESTCASES; i++) begin
            num_testcases++;
            testcases_passed[i] = 1;
            @(negedge clk);
            tv.init_state = tv_arr[i].init_state;
            init = 1; // initialize state at t = 5 (mod 10)
            tv.in = tv_arr[i].in; // drive input at t = 5 (mod 10)
            #1;
            init = 0;
            check_output(i); // check output at t = 6 (mod 10)
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

    // initial begin

    // end
endmodule
