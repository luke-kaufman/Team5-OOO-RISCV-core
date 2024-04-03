`include "test.v"
`include "misc/fifo.v"

module test_tb #(
    parameter N_ENTRIES = 8,
    parameter ENTRY_WIDTH = 32
);
    reg clk;
    reg rst_aL;
    
    wire enq_ready;
    reg enq_valid;
    reg [ENTRY_WIDTH-1:0] enq_data;
    
    reg deq_ready;
    wire deq_valid;
    wire [ENTRY_WIDTH-1:0] deq_data;
    
    // wire [PTR_WIDTH-1:0] count;

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
        .deq_data(deq_data)

        // .count(count)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 1;
        #1;
        for (int i = 0; i < N_ENTRIES; i++) begin
            force dut.entry[i].entry_reg.we = 1'b1;
            force dut.entry[i].entry_reg.din = 32'hDEADBEE0 + i;
        end
        force dut.enq_up_counter.counter_reg.we = 1'b1;
        force dut.enq_up_counter.counter_reg.din = 4'b1001;
        force dut.deq_up_counter.counter_reg.we = 1'b1;
        force dut.deq_up_counter.counter_reg.din = 4'b0110;
        $display("enq_up_counter: %d", dut.enq_up_counter.counter_reg.dout);
        $display("deq_up_counter: %d", dut.deq_up_counter.counter_reg.dout);
        $finish;
    end
endmodule