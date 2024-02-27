module fifo_tb;
    reg clk;
    reg rst_aL;

    wire ready_enq;
    reg valid_enq;
    reg [31:0] data_enq;
    
    reg ready_deq;
    wire valid_deq;
    wire [31:0] data_deq;
    
    fifo #(
        .DATA_WIDTH(32),
        .FIFO_DEPTH(8)
    ) uut (
        .clk(clk),
        .rst_aL(rst_aL),
    
        .valid_enq(valid_enq),
        .ready_enq(ready_enq),
        .data_enq(data_enq),
    
        .ready_deq(ready_deq),
        .valid_deq(valid_deq),
        .data_deq(data_deq)
    );
    initial begin
        clk = 0;
        rst_aL = 0;
        valid_enq = 0;
        data_enq = 0;
        #10;
        rst_aL = 1;
        #10;
        #10;
        valid_enq = 1;
        data_enq = 1;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 2;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 3;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 4;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 5;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 6;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 7;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 8;
        #10;
        valid_enq = 0;
        #10;
        valid_enq = 1;
        data_enq = 9;
        #10;
        valid_enq = 0;
    end

    initial begin
        forever begin
            #5;
            clk = ~clk;
        end
    end

    initial begin
        $monitor("clk=%b rst_aL=%b ready_enq=%b valid_enq=%b data_enq=%d ready_deq=%b valid_deq=%b data_deq=%d", clk, rst_aL, ready_enq, valid_enq, data_enq, ready_deq, valid_deq, data_deq);
    end
endmodule