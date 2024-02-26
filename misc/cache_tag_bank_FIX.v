module cache_tag_bank #(
    parameter TAG_ENTRY_SIZE = 32,
    parameter NUM_WORDS = 64,
) (
    input wire clk,
    input wire rst,
    input wire en,
    //TODO add inputs to tag bank
    output wire [WORD_SIZE-1:0] dout
);

generate
    if(TAG_ENTRY_SIZE == ICACHE_TAG_ENTRY_SIZE
    && NUM_WORDS == ICACHE_NUM_SETS) begin
        sram_64x24_1rw icache_tag_b (
            .clk0(/*TODO*/),
            .csb0_aL(/*TODO*/),
            .web0_aL(/*TODO*/),
            .addr0(/*TODO*/),
            .din0(/*TODO*/),
            .dout0(/*TODO*/)
        );
    end
    else if(TAG_ENTRY_SIZE == DCACHE_TAG_ENTRY_SIZE 
         && NUM_WORDS == ICACHE_NUM_SETS) begin
        sram_64x25_1rw dcache_tag_b (
            .clk0(/*TODO*/),
            .csb0_aL(/*TODO*/),
            .web0_aL(/*TODO*/),
            .addr0(/*TODO*/),
            .din0(/*TODO*/),
            .dout0(/*TODO*/)
        );
    end
    else begin
        // THROW ERROR - bank size not supported - generate a new sram block
    end
endgenerate

endmodule