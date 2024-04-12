`include "test.v"
`include "misc/fifo.v"

module test_tb #(
    parameter N_ENTRIES = 8,
    parameter ENTRY_WIDTH = 32,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1 // CTR_WIDTH is PTR_WIDTH + 1 to disambiguate between full and empty conditions
);
    reg clk;
    reg rst_aL;

    wire enq_ready;
    reg enq_valid;
    reg [ENTRY_WIDTH-1:0] enq_data;

    reg deq_ready;
    wire deq_valid;
    wire [ENTRY_WIDTH-1:0] deq_data;

    wire [PTR_WIDTH-1:0] count;

    reg init;
    reg [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_entry_reg_state;
    reg [CTR_WIDTH-1:0] init_enq_up_counter_state;
    reg [CTR_WIDTH-1:0] init_deq_up_counter_state;

    fifo #(
        .ENTRY_WIDTH(ENTRY_WIDTH),
        .N_ENTRIES(N_ENTRIES)
    ) dut (
        .clk(clk),
        .rst_aL(rst_aL),

        .enq_ready(enq_ready),
        .enq_valid(enq_valid),
        .enq_data(enq_data),

        .deq_ready(deq_ready),
        .deq_valid(deq_valid),
        .deq_data(deq_data),

        // .count(count),

        .init(init),
        .init_entry_reg_state(init_entry_reg_state),
        .init_enq_up_counter_state(init_enq_up_counter_state),
        .init_deq_up_counter_state(init_deq_up_counter_state)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 1;
        #1;
        for (int i = 0; i < N_ENTRIES; i++) begin
            init_entry_reg_state[i] = 32'hDEADBEE0 + i;
        end
        init_enq_up_counter_state = 4'b1001;
        init_deq_up_counter_state = 4'b0110;
        init = 1;
        @(negedge clk);
        $display("enq_up_counter: %0d", dut.enq_up_counter.counter_reg.dout);
        $display("deq_up_counter: %0d", dut.deq_up_counter.counter_reg.dout);
        $finish;
    end
endmodule