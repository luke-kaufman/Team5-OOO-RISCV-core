// Data banks for icache and dcache are exactly the same (as of 2/26/2024)
module cache_data_bank (
    input wire clk,
    input wire rst_aL
    
);

generate
    // MAKE ICACHE DATA BANK
    if(TAG_ENTRY_SIZE == ICACHE_DATA_ENTRY_SIZE
    && NUM_WORDS == ICACHE_NUM_SETS) begin
        sram_64x64_1rw icache_tag_b (
            .clk0(/*TODO*/),
            .csb0_aL(/*TODO*/),
            .web0_aL(/*TODO*/),
            .addr0(/*TODO*/),
            .din0(/*TODO*/),
            .dout0(/*TODO*/)
        );
    end
    // MAKE DCACHE DATA BANK
    else if(TAG_ENTRY_SIZE == DCACHE_DATA_ENTRY_SIZE 
         && NUM_WORDS == ICACHE_NUM_SETS) begin
        sram_64x64_1rw dcache_tag_b (
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