// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module fifo8 #(
    parameter DATA_WIDTH = 32,
    localparam FIFO_DEPTH = 8,
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH), // = 3
    localparam CTR_WIDTH = PTR_WIDTH + 1 // = 4
    // CTR_WIDTH is PTR_WIDTH + 1 to disambiguate between full and empty conditions
) (
    input wire clk,
    input wire rst_aL,

    output wire ready_enq,
    input wire valid_enq,
    input wire [DATA_WIDTH-1:0] data_enq,
    
    input wire ready_deq,
    output wire valid_deq,
    output wire [DATA_WIDTH-1:0] data_deq
);

    wire fifo_empty;
    wire fifo_full;
    wire enq;
    wire deq;
    wire [CTR_WIDTH-1:0] enq_ctr;
    wire [CTR_WIDTH-1:0] deq_ctr;
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] deq_ptr = deq_ctr[PTR_WIDTH-1:0];
    
    counter #(.WIDTH(CTR_WIDTH)) enq_counter (
        .clk(clk),
        .rst_aL(rst_aL),
        .en(enq),
        .count(enq_ctr)
    );
    counter #(.WIDTH(CTR_WIDTH)) deq_counter (
        .clk(clk),
        .rst_aL(rst_aL),
        .en(deq),
        .count(deq_ctr)
    );
    
    wire eq_msb;
    wire not_eq_msb;
    wire eq_ptr;

    cmp #(.WIDTH(1)) cmp_msb (
        .a(enq_ctr[CTR_WIDTH-1]),
        .b(deq_ctr[CTR_WIDTH-1]),
        .y(eq_msb)
    );
    cmp #(.WIDTH(PTR_WIDTH)) cmp_ptr (
        .a(enq_ptr),
        .b(deq_ptr),
        .y(eq_ptr)
    );
    AND2_X1 eq_msb_AND_eq_ptr (
        .A1(eq_msb),
        .A2(eq_ptr),
        .ZN(fifo_empty)
    );
    INV_X1 NOT_eq_msb (
        .A(eq_msb),
        .ZN(not_eq_msb)
    );
    AND2_X1 not_eq_msb_AND_eq_ptr (
        .A1(not_eq_msb),
        .A2(eq_ptr),
        .ZN(fifo_full)
    );

    INV_X1 NOT_fifo_full (
        .A(fifo_full),
        .ZN(ready_enq)
    );
    INV_X1 NOT_fifo_empty (
        .A(fifo_empty),
        .ZN(valid_deq)
    );

    AND2_X1 ready_enq_AND_valid_enq (
        .A1(ready_enq),
        .A2(valid_enq),
        .ZN(enq)
    );
    AND2_X1 ready_deq_AND_valid_deq (
        .A1(ready_deq),
        .A2(valid_deq),
        .ZN(deq)
    );

    wire [FIFO_DEPTH-1:0] onehot_enq_ptr;
    decoder #(.IN_WIDTH(PTR_WIDTH)) enq_ptr_dec (
        .in(enq_ptr),
        .out(onehot_enq_ptr)
    );

    wire [FIFO_DEPTH-1:0] fifo_entry_we;
    wire [DATA_WIDTH-1:0] fifo_entry_dout [0:FIFO_DEPTH-1];
    generate
        for (genvar i = 0; i < FIFO_DEPTH; i = i + 1) begin
            AND2_X1 onehot_enq_ptr_AND_enq (
                .A1(onehot_enq_ptr[i]),
                .A2(enq),
                .ZN(fifo_entry_we[i])
            );
            register #(.WIDTH(DATA_WIDTH)) fifo_entry (
                .clk(clk),
                .rst_aL(rst_aL),
                .we(fifo_entry_we[i]),
                .din(data_enq),
                .dout(fifo_entry_dout[i])
            );
        end
    endgenerate

    mux8 #(.WIDTH(DATA_WIDTH)) fifo_entry_mux (
        .ins(fifo_entry_dout),
        .sel(deq_ptr),
        .out(data_deq)
    );
endmodule