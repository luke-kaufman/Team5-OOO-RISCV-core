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
    generate
        for (genvar i = 0; i < FIFO_DEPTH; i++) begin
            register #(.WIDTH(DATA_WIDTH)) fifo_entry (
                .clk(clk),
                .rst(rst),
                .we()
                .d()
            )
        end
    endgenerate
    
    register #(.WIDTH(ADDR_WIDTH)) enq_ptr;
    register #(.WIDTH(ADDR_WIDTH)) deq_ptr;
    wire enq;
    wire deq;

    assign 

    assign enq = ready_o & valid_i;
    assign deq = ready_i & valid_o;
endmodule