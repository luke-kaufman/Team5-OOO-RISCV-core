`ifndef FIFO_RAM_V
`define FIFO_RAM_V

`include "misc/inv.v"
`include "misc/and/and_.v"
`include "misc/cmp/unsigned_cmp_.v"
`include "misc/dec/dec_.v"
`include "misc/mux/mux_.v"
`include "misc/onehot_mux/onehot_mux_.v"
`include "misc/reg_.v"
`include "misc/up_counter.v"

module fifo_ram #(
    parameter  int unsigned ENTRY_WIDTH = 32,
    parameter  int unsigned N_ENTRIES = 8,
    localparam int unsigned PTR_WIDTH = $clog2(N_ENTRIES),
    localparam int unsigned CTR_WIDTH = PTR_WIDTH + 1,
    parameter N_READ_PORTS = 2,
    parameter N_WRITE_PORTS = 2 // NOTE: all writes are assumed to be to separate entries
) (
    input wire clk,
    input wire rst_aL,

    output wire enq_ready,
    input wire enq_valid,
    input wire [ENTRY_WIDTH-1:0] enq_data,
    output wire [PTR_WIDTH-1:0] enq_addr, // to get the ROB tail ID for dispatch

    input wire deq_ready,
    output wire deq_valid,
    output wire [ENTRY_WIDTH-1:0] deq_data,
    output wire [PTR_WIDTH-1:0] deq_addr, // to get the ROB head ID for retirement

    input wire [N_READ_PORTS-1:0] [PTR_WIDTH-1:0] rd_addr,
    output wire [N_READ_PORTS-1:0] [ENTRY_WIDTH-1:0] rd_data,

    // NOTE: all writes are assumed to be to separate entries
    // writes are generalized to be optional and partial across all entries
    input wire [N_WRITE_PORTS-1:0] wr_en,
    input wire [N_WRITE_PORTS-1:0] [PTR_WIDTH-1:0] wr_addr,
    input wire [N_ENTRIES-1:0] [N_WRITE_PORTS-1:0] [ENTRY_WIDTH-1:0] wr_data,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts,

    // for testing
    input wire init,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] init_entry_reg_state,
    input wire [CTR_WIDTH-1:0] init_enq_up_counter_state,
    input wire [CTR_WIDTH-1:0] init_deq_up_counter_state,
    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] current_entry_reg_state,
    output wire [CTR_WIDTH-1:0] current_enq_up_counter_state,
    output wire [CTR_WIDTH-1:0] current_deq_up_counter_state
);
    // counter that holds the enqueue pointer
    wire enq;
    wire [CTR_WIDTH-1:0] enq_ctr;
    up_counter #(.WIDTH(CTR_WIDTH)) enq_up_counter ( // NOTE: STATEFUL
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(enq),
        .count(enq_ctr),
        .init(init),
        .init_state(init_enq_up_counter_state)
    );
    // counter that holds the dequeue pointer
    wire deq;
    wire [CTR_WIDTH-1:0] deq_ctr;
    up_counter #(.WIDTH(CTR_WIDTH)) deq_up_counter ( // NOTE: STATEFUL
        .clk(clk),
        .rst_aL(rst_aL),
        .inc(deq),
        .count(deq_ctr),
        .init(init),
        .init_state(init_deq_up_counter_state)
    );

    // comparator that disambiguates between full and empty conditions using the MSB
    wire eq_msb;
    unsigned_cmp_ #(.WIDTH(1)) eq_msb_cmp (
        .a(enq_ctr[CTR_WIDTH-1]),
        .b(deq_ctr[CTR_WIDTH-1]),
        .eq(eq_msb),
        .lt(),
        .ge()
    );

    // pointers are the lower bits of the counters
    wire [PTR_WIDTH-1:0] enq_ptr;
    wire [PTR_WIDTH-1:0] deq_ptr;
    assign enq_ptr = enq_ctr[PTR_WIDTH-1:0];
    assign deq_ptr = deq_ctr[PTR_WIDTH-1:0];

    // comparator that checks if the enqueue and dequeue pointers are equal (i.e. the fifo is empty or full)
    wire eq_ptr;
    unsigned_cmp_ #(.WIDTH(PTR_WIDTH)) eq_ptr_cmp (
        .a(enq_ptr),
        .b(deq_ptr),
        .eq(eq_ptr),
        .lt(),
        .ge()
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

    // TODO: current assumption is that there won't ever be a race condition between enq_we and wr_en_we(s) (WRITE AN ASSERT TO CHECK)
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
        // TODO: current assumption is that there won't ever be a race condition between the enq_data and wr_data(s) (WRITE AN ASSERT TO CHECK)
        // mux that selects the din for each fifo entry
        // NOTE: mux_ only works with power-of-2 N_INS
        // if all selects are 0, the output is don't care (physically all 0s), entry_we in this case is 0 anyway
        onehot_mux_ #(.WIDTH(ENTRY_WIDTH), .N_INS(N_WRITE_PORTS+1)) entry_din_mux (
            .clk(clk),
            .ins({wr_data[i], enq_data}),
            .sel({wr_en_we_transposed[i], enq_we[i]}),
            .out(entry_dins[i])
        );
        // register that holds each fifo entry
        reg_ #(.WIDTH(ENTRY_WIDTH)) entry_reg ( // NOTE: STATEFUL
            .clk(clk),
            .rst_aL(rst_aL),
            .we(entry_we[i]),
            .din(entry_dins[i]),
            .dout(entry_douts[i]),
            .init(init),
            .init_state(init_entry_reg_state[i])
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

    // assign the enqueue and dequeue addresses
    assign enq_addr = enq_ptr;
    assign deq_addr = deq_ptr;

    // for testing
    assign current_enq_up_counter_state = enq_ctr;
    assign current_deq_up_counter_state = deq_ctr;
    assign current_entry_reg_state = entry_douts;

    // assertions
    // enq_ctr should not be distant from deq_ctr by more than N_ENTRIES
    function void assert_enq_ctr_not_distant_from_deq_ctr();
        automatic int ctr_distance = enq_ctr - deq_ctr;
        if (ctr_distance < 0) ctr_distance += 2 * N_ENTRIES;
        if (ctr_distance > N_ENTRIES) begin
            $error("ERROR: enq_ctr is distant from deq_ctr by more than N_ENTRIES");
        end
    endfunction
    // wr_addrs should not be equal to each other when both their respective wr_ens are true
    function void assert_wr_addrs_not_eq();
        for (int i = 0; i < N_WRITE_PORTS; i++) begin
            for (int j = i + 1; j < N_WRITE_PORTS; j++) begin
                if (wr_en[i] && wr_en[j] && (wr_addr[i] == wr_addr[j])) begin
                    $error("ERROR: wr_addr[%0d] is equal to wr_addr[%0d]", i, j);
                end
            end
        end
    endfunction
    // wr_addr should be to a valid entry when wr_en is true
    function bit [N_ENTRIES-1:0] valid_entries();
        if (deq_ctr <= enq_ctr) begin
            for (int i = deq_ctr; i < enq_ctr; i++) begin
                valid_entries[i[PTR_WIDTH-1:0]] = 1;
            end
        end else begin
            for (int i = deq_ctr; i < 2*N_ENTRIES; i++) begin
                valid_entries[i[PTR_WIDTH-1:0]] = 1;
            end
            for (int i = 0; i < enq_ctr; i++) begin
                valid_entries[i[PTR_WIDTH-1:0]] = 1;
            end
        end
    endfunction
    function void assert_wr_addr_valid();
        for (int i = 0; i < N_WRITE_PORTS; i++) begin
            if (wr_en[i] && !(valid_entries()[wr_addr[i]])) begin
                $error("ERROR: wr_addr[%0d] is not to a valid entry\n\
                        wr_addr[%0d] = %b, deq_ctr = %b, enq_ctr = %b\n",
                        i,
                        i, wr_addr[i], deq_ctr, enq_ctr);
            end
        end
    endfunction
    // rd_addr should be to a valid entry
    function void assert_rd_addr_valid();
        for (int i = 0; i < N_READ_PORTS; i++) begin
            if (!(valid_entries()[rd_addr[i]])) begin
                $error("ERROR: rd_addr[%0d] is not to a valid entry", i);
            end
        end
    endfunction

    always @(negedge clk) begin #1
        assert_enq_ctr_not_distant_from_deq_ctr();
        assert_wr_addrs_not_eq();
        assert_wr_addr_valid();
        // assert_rd_addr_valid(); // FIXME
    end

    // always @(posedge clk) begin #1
    //     assert_enq_ctr_not_distant_from_deq_ctr();
    // end
endmodule

`endif
