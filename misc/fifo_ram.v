`ifndef FIFO_RAM_V
`define FIFO_RAM_V

`include "misc/inv.v"
`include "misc/and/and_.v"
`include "misc/cmp/cmp_.v"
`include "misc/dec/dec_.v"
`include "misc/mux/mux_.v"
`include "misc/onehot_mux/onehot_mux_.v"
`include "misc/register.v"
`include "misc/up_counter.v"

module fifo_ram #(
    parameter ENTRY_WIDTH = 32,
    parameter N_ENTRIES = 8,
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1,

    // RAM parameters
    parameter N_READ_PORTS = 2,
    // NOTE: all writes are assumed to be to separate entries
    parameter N_WRITE_PORTS = 2
) (
    input wire clk,
    // input wire rst_aL, (NOTE: edited to suppress "coerced to inout" warning)
    inout wire rst_aL,

    output wire enq_ready,
    input wire enq_valid,
    input wire [ENTRY_WIDTH-1:0] enq_data,
    
    input wire deq_ready,
    output wire deq_valid,
    output wire [ENTRY_WIDTH-1:0] deq_data,

    input wire [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr,
    output wire [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data,
    // NOTE: all writes are assumed to be to separate entries
    input wire [N_WRITE_PORTS-1:0] wr_en,
    input wire [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr,
    input wire [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data,

    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts, // for updating entries by partial writes

    output wire [PTR_WIDTH-1:0] count // for debugging
);
    // counter that holds the enqueue pointer
    wire enq;
    wire [CTR_WIDTH-1:0] enq_ctr;
    up_counter #(.WIDTH(CTR_WIDTH)) enq_up_counter (
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(enq),
        .count(enq_ctr)
    );
    // counter that holds the dequeue pointer
    wire deq;
    wire [CTR_WIDTH-1:0] deq_ctr;
    up_counter #(.WIDTH(CTR_WIDTH)) deq_up_counter (
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(deq),
        .count(deq_ctr)
    );
    
    // comparator that disambiguates between full and empty conditions using the MSB
    wire eq_msb;
    cmp_ #(.WIDTH(1)) eq_msb_cmp (
        .a(enq_ctr[CTR_WIDTH-1]),
        .b(deq_ctr[CTR_WIDTH-1]),
        .y(eq_msb)
    );
    
    // pointers are the lower bits of the counters
    wire [PTR_WIDTH-1:0] enq_ptr;
    wire [PTR_WIDTH-1:0] deq_ptr;
    assign enq_ptr = enq_ctr[PTR_WIDTH-1:0];
    assign deq_ptr = deq_ctr[PTR_WIDTH-1:0];

    // comparator that checks if the enqueue and dequeue pointers are equal (i.e. the fifo is empty or full)
    wire eq_ptr;
    cmp_ #(.WIDTH(PTR_WIDTH)) eq_ptr_cmp (
        .a(enq_ptr),
        .b(deq_ptr),
        .y(eq_ptr)
    );
    
    // logic that checks if the fifo is empty
    wire fifo_empty;
    and_ #(.N_INS(2)) fifo_empty_and (
        .a({eq_msb, eq_ptr}),
        .y(fifo_empty)
    );
    // logic that checks if the fifo is full
    wire not_eq_msb;
    wire fifo_full;
    inv eq_msb_inv (
        .a(eq_msb),
        .y(not_eq_msb)
    );
    and_ #(.N_INS(2)) fifo_full_and (
        .a({not_eq_msb, eq_ptr}),
        .y(fifo_full)
    );

    // logic that checks if the fifo is ready to enqueue
    inv fifo_full_inv (
        .a(fifo_full),
        .y(enq_ready)
    );
    // logic that checks if the fifo is valid to dequeue
    inv fifo_empty_inv (
        .a(fifo_empty),
        .y(deq_valid)
    );

    // logic that drives the enqueue signal using the ready-valid interface
    and_ #(.N_INS(2)) enq_and (
        .a({enq_ready, enq_valid}),
        .y(enq)
    );
    // logic that drives the dequeue signal using the ready-valid interface
    and_ #(.N_INS(2)) deq_and (
        .a({deq_ready, deq_valid}),
        .y(deq)
    );

    // decode the enq_pte into enq_we precursor for each fifo entry
    wire [N_ENTRIES-1:0] enq_we_pre;
    dec_ #(.IN_WIDTH(PTR_WIDTH)) enq_ptr_dec (
        .in(enq_ptr),
        .out(enq_we_pre)
    );

    // decode the write address(es) into wr_en_we precursor(s) for each fifo entry
    wire [N_WRITE_PORTS-1:0] [N_ENTRIES-1:0] wr_en_we_pre;
    for (genvar i = 0; i < N_WRITE_PORTS; i = i + 1) begin
        dec_ #(.IN_WIDTH(PTR_WIDTH)) wr_addr_dec (
            .in(wr_addr[i]),
            .out(wr_en_we_pre[i])
        );
    end

    // NOTE: current assumption is that there won't ever be a race condition between enq_we and wr_en_we(s)
    // i.e., they are supposed to be mutually exclusive
    // there won't be a race condition among the wr_en_we(s) either

    // enq_we precursor to entry_we
    wire [N_ENTRIES-1:0] enq_we;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        and_ #(.N_INS(2)) enq_we_and (
            .a({enq_we_pre[i], enq}),
            .y(enq_we[i])
        );
    end
    // wr_en_we precursor(s) to entry_we
    wire [N_WRITE_PORTS-1:0] [N_ENTRIES-1:0] wr_en_we;
    for (genvar i = 0; i < N_WRITE_PORTS; i++) begin
        for (genvar j = 0; j < N_ENTRIES; j++) begin
            and_ #(.N_INS(2)) wr_en_we_and (
                .a({wr_en_we_pre[i][j], wr_en[i]}),
                .y(wr_en_we[i][j])
            );
        end
    end

    // combine enq_we and wr_en_we(s) to entry_we
    wire [N_ENTRIES-1:0] entry_we;
    wire [N_ENTRIES-1:0] [N_WRITE_PORTS-1:0] wr_en_we_transposed;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        for (genvar j = 0; j < N_WRITE_PORTS; j++) begin
            assign wr_en_we_transposed[i][j] = wr_en_we[j][i];
        end
        or_ #(.N_INS(N_WRITE_PORTS+1)) entry_we_or (
            .a({enq_we[i], wr_en_we_transposed[i]}),
            .y(entry_we[i])
        );
    end

    // memory that holds fifo entries
    wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_dins;
    for (genvar i = 0; i < N_ENTRIES; i++) begin
        // NOTE: current assumption is that there won't ever be a race condition between the enq_data and wr_data(s)
        // mux that selects the din for each fifo entry
        // NOTE: mux_ only works with power-of-2 N_INS
        onehot_mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_WRITE_PORTS+1)) entry_din_mux (
            .ins({wr_data, enq_data}),
            .sel({wr_en_we_transposed[i], enq_we[i]}),
            .out(entry_dins[i])
        );
        // register that holds each fifo entry
        register #(.WIDTH(ENTRY_WIDTH)) entry (
            .clk(clk),
            .rst_aL(rst_aL),
            .we(entry_we[i]),
            .din(entry_dins[i]),
            .dout(entry_douts[i])
        );
    end

    // mux that drives the dequeue data using the dequeue pointer
    mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_ENTRIES)) deq_data_mux (
        .ins(entry_douts),
        .sel(deq_ptr),
        .out(deq_data)
    );

    // mux(es) that drives read data using the read address(es)
    for (genvar i = 0; i < N_READ_PORTS; i++) begin
        mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_ENTRIES)) rd_data_mux (
            .ins(entry_douts),
            .sel(rd_addr[i]),
            .out(rd_data[i])
        );
    end

    assign count = enq_ctr[PTR_WIDTH-1:0] - deq_ctr[PTR_WIDTH-1:0]; // for debugging (NOTE: behavioral code)
endmodule

`endif
