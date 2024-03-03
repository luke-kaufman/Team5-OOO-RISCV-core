module integer_issue #(
    // valid stands for "exists"
    // ready stands for "produced"
    localparam SRC1_VALID_WIDTH = 1,
    localparam SRC1_READY_WIDTH = 1,
    localparam SRC1_TAG_WIDTH = 4,
    localparam SRC1_DATA_WIDTH = 32,
    
    localparam SRC2_VALID_WIDTH = 1,
    localparam SRC2_READY_WIDTH = 1,
    localparam SRC2_TAG_WIDTH = 4,
    localparam SRC2_DATA_WIDTH = 32,

    localparam DST_VALID_WIDTH = 1,
    localparam DST_TAG_WIDTH = 4,

    // ?
    localparam ALU_CTRL_BITS = 4,
    // whether the branch is predicted taken or not
    localparam BRANCH_PRED_BITS = 1,
    localparam BRANCH_TARGET_PC_WIDTH = 32,
    
    localparam IIQ_ENTRY_WIDTH = (SRC1_VALID_WIDTH + SRC1_READY_WIDTH + SRC1_TAG_WIDTH + SRC1_DATA_WIDTH
                                + SRC2_VALID_WIDTH + SRC2_READY_WIDTH + SRC2_TAG_WIDTH + SRC2_DATA_WIDTH
                                + DST_VALID_WIDTH + DST_TAG_WIDTH
                                + ALU_CTRL_BITS
                                + BRANCH_PRED_BITS + BRANCH_TARGET_PC_WIDTH),
    localparam IIQ_DEPTH = 8,


    localparam ISSUE_DATA_WIDTH = ,
) (
    input wire clk,
    input wire rst_aL,

    // INTERFACE TO DECODE/RENAME/DISPATCH
    output wire iiq_dispatch_ready,
    input wire iiq_dispatch_valid,
    input wire [IIQ_ENTRY_WIDTH-1:0] iiq_dispatch_data,

    // INTERFACE TO EXECUTE
    output wire issue_valid,
    output wire [ISSUE_DATA_WIDTH-1:0] issue_data
);
    // internal signals
    // wakeup feedback: (wakeup_valid, wakeup_tag/index, wakeup_data)
    wire wakeup_valid;

    shift_queue iiq #(
        
    ) (

    );

    
endmodule