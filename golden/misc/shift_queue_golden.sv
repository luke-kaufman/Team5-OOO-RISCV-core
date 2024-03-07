module shift_queue_golden #(
    parameter N_ENTRIES = 8,
    parameter ENTRY_WIDTH = 81, /* LSQ Entry width */
    localparam PTR_WIDTH = $clog2(N_ENTRIES),
    localparam CTR_WIDTH = PTR_WIDTH + 1 // 
) (
    input wire clk,
    input wire rst_aL,

    // enqueue interface: ready & valid
    output wire enq_ready,
    input wire enq_valid,
    input wire [ENTRY_WIDTH-1:0] enq_data,

    // dequeue interface: select then valid
    input wire deq_ready,
    input wire [N_ENTRIES-1:0] deq_sel_onehot, // can be either one-hot or all 0s
    output wire deq_valid,
    output wire [ENTRY_WIDTH-1:0] deq_data,

    input wire [N_ENTRIES-1:0] wr_en,
    input wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] wr_data,

    output wire [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] entry_douts
);
    // state elements
    logic [CTR_WIDTH-1:0] enq_ctr_r;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] queue_r;

    // next state signals
    logic [CTR_WIDTH-1:0] next_enq_ctr;
    logic [N_ENTRIES-1:0] [ENTRY_WIDTH-1:0] next_queue;

    // internal signals
    wire [PTR_WIDTH-1:0] enq_ptr = enq_ctr_r[PTR_WIDTH-1:0]; // lower bits of enq_ctr_r
    wire queue_full = enq_ctr_r[PTR_WIDTH]; // MSB of enq_ctr_r
    wire enq = enq_ready && enq_valid;
    wire deq = deq_ready && deq_valid;
    logic [N_ENTRIES-1:0] shift_we_pre;
    always_comb begin
        shift_we_pre[0] = deq_sel_onehot[0];
        for (int i = 0; i < N_ENTRIES; i++) begin
            shift_we_pre[i] = shift_we_pre[i-1] | deq_sel_onehot[i];
        end
    end
    wire [N_ENTRIES-1:0] shift_we = shift_we_pre & deq;
    
    
endmodule