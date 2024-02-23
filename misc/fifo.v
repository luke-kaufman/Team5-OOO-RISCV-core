module fifo #(
    parameter DATA_WIDTH = 1,
    parameter FIFO_DEPTH = 2,
    parameter ADDR_WIDTH = 1
) (
    input wire clk,
    input wire rst,
    output wire ready_o,
    input wire valid_i,
    input wire [DATA_WIDTH-1:0] data_i,
    input wire ready_i,
    output wire valid_o,
    output wire [DATA_WIDTH-1:0] data_o
);

    wire fifo_empty;
    wire fifo_full;
    wire enq;
    wire deq;
    
    register #(.WIDTH(ADDR_WIDTH)) enq_ptr;
    register #(.WIDTH(ADDR_WIDTH)) deq_ptr;

    generate
        for (genvar i = 0; i < FIFO_DEPTH; i = i + 1) begin
            register #(.WIDTH(DATA_WIDTH)) fifo_entry (
                .clk(clk),
                .rst(rst),
                .we()
                .d()
            )
        end
    endgenerate
    

    assign fifo_empty = enq_ptr == deq_ptr;
    assign fifo_full = (enq_ptr[ADDR_WIDTH-2:0] == deq_ptr[ADDR_WIDTH-2:0]) (enq_ptr[ADDR_WIDTH] != 
    

    assign 

    assign enq = ready_o & valid_i;
    assign deq = ready_i & valid_o;
endmodule