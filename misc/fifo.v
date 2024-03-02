`ifndef FIFO_V
`define FIFO_V

`include "freepdk-45nm/stdcells.v"
`include "misc/counter.v"
`include "misc/cmp/cmp_.v"
`include "misc/dec/dec_.v"
`include "misc/mux/mux_.v"
`include "misc/register.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module fifo #(
    // parameter RANDOM_ACCESS = 0, // 0 for strictly fifo, 1 for fifo with random access
    // localparam N_READ_PORTS = 2,
    // localparam N_WRITE_PORTS = 2,
    parameter DATA_WIDTH = 32,
    parameter enum {_8=8, _16=16} FIFO_DEPTH = 8,
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH), // = 3 or 4
    localparam CTR_WIDTH = PTR_WIDTH + 1 // = 4 or 5
    // CTR_WIDTH is PTR_WIDTH + 1 to disambiguate between full and empty conditions
) (
    input wire clk,
    input wire rst_aL,

    input wire valid_enq,
    input wire ready_deq,
    input wire [DATA_WIDTH-1:0] data_enq,
    
    output wire valid_deq,
    output wire ready_enq,
    output wire [DATA_WIDTH-1:0] data_deq

    // random access ports
    // input wire [PTR_WIDTH-1:0] rd_addr0,
    // input wire [PTR_WIDTH-1:0] rd_addr1,
    // input wire [PTR_WIDTH-1:0] wr_addr0,
    // input wire [PTR_WIDTH-1:0] wr_addr1
);
    // counter that holds the enqueue pointer
    wire enq;
    wire [CTR_WIDTH-1:0] enq_ctr;
    counter #(.WIDTH(CTR_WIDTH)) enq_counter (
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(enq),
        .count(enq_ctr)
    );
    // counter that holds the dequeue pointer
    wire deq;
    wire [CTR_WIDTH-1:0] deq_ctr;
    counter #(.WIDTH(CTR_WIDTH)) deq_counter (
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(deq),
        .count(deq_ctr)
    );
    
    // comparator that disambiguates between full and empty conditions using the MSB
    wire eq_msb;
    cmp_ #(.WIDTH(1)) cmp_msb (
        .a(enq_ctr[CTR_WIDTH-1]),
        .b(deq_ctr[CTR_WIDTH-1]),
        .y(eq_msb)
    );
    // comparator that checks if the enqueue and dequeue pointers are equal (i.e. the fifo is empty or full)
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] deq_ptr = deq_ctr[PTR_WIDTH-1:0];
    wire eq_ptr;
    cmp_ #(.WIDTH(PTR_WIDTH)) cmp_ptr (
        .a(enq_ptr),
        .b(deq_ptr),
        .y(eq_ptr)
    );
    
    // logic that checks if the fifo is empty
    wire fifo_empty;
    AND2_X1 eq_msb_AND_eq_ptr (
        .A1(eq_msb),
        .A2(eq_ptr),
        .ZN(fifo_empty)
    );
    // logic that checks if the fifo is full
    wire not_eq_msb;
    wire fifo_full;
    INV_X1 NOT_eq_msb (
        .A(eq_msb),
        .ZN(not_eq_msb)
    );
    AND2_X1 not_eq_msb_AND_eq_ptr (
        .A1(not_eq_msb),
        .A2(eq_ptr),
        .ZN(fifo_full)
    );

    // logic that checks if the fifo is ready to enqueue
    INV_X1 NOT_fifo_full (
        .A(fifo_full),
        .ZN(ready_enq)
    );
    // logic that checks if the fifo is valid to dequeue
    INV_X1 NOT_fifo_empty (
        .A(fifo_empty),
        .ZN(valid_deq)
    );

    // logic that drives the enqueue signal using the ready-valid interface
    AND2_X1 ready_enq_AND_valid_enq (
        .A1(ready_enq),
        .A2(valid_enq),
        .ZN(enq)
    );
    // logic that drives the dequeue signal using the ready-valid interface
    AND2_X1 ready_deq_AND_valid_deq (
        .A1(ready_deq),
        .A2(valid_deq),
        .ZN(deq)
    );

    // decoder that feeds into the write enable logic for each fifo entry
    wire [FIFO_DEPTH-1:0] onehot_enq_ptr;
    dec_ #(.IN_WIDTH(PTR_WIDTH)) enq_ptr_dec (
        .in(enq_ptr),
        .out(onehot_enq_ptr)
    );

    // memory that holds fifo entries
    wire [FIFO_DEPTH-1:0] fifo_entry_we;
    wire [DATA_WIDTH-1:0] [FIFO_DEPTH-1:0] fifo_entry_dout;
    for (genvar i = 0; i < FIFO_DEPTH; i = i + 1) begin
        // logic that drives the write enable signal for each fifo entry
        AND2_X1 onehot_enq_ptr_AND_enq (
            .A1(onehot_enq_ptr[i]),
            .A2(enq),
            .ZN(fifo_entry_we[i])
        );
        // register that holds each fifo entry
        register #(.WIDTH(DATA_WIDTH)) fifo_entry (
            .clk(clk),
            .rst_aL(rst_aL),
            .we(fifo_entry_we[i]),
            .din(data_enq),
            .dout(fifo_entry_dout[i])
        );
    end

    // mux that drives the dequeue data using the dequeue pointer
    mux_ #(.WIDTH(DATA_WIDTH), .N_INS(FIFO_DEPTH)) fifo_entry_mux (
        .ins(fifo_entry_dout),
        .sel(deq_ptr),
        .out(data_deq)
    );
endmodule

`endif
