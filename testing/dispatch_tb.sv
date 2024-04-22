`include "misc/global_defs.svh"
`include "top/top.sv"

module dispatch_tb;
    bit clk = 0;
    bit init = 0;
    addr_t init_pc = 32'h1018c;
    main_mem_block_addr_t block_addr;
    main_mem_block_offset_t block_offset;
    block_data_t init_main_mem_state[`MAIN_MEM_N_BLOCKS];

    initial forever #5 clk = ~clk;

    initial begin
        for (int i = 0; i < `MAIN_MEM_N_BLOCKS; i++) begin // TODO: double-check if this is correct
            init_main_mem_state[i] = 0;
        end
        {block_addr, block_offset} = 32'h1018c; // 0001 0000 0001 1000 1100
        if (block_offset + `INSTR_WIDTH < `BLOCK_DATA_WIDTH) begin
            init_main_mem_state[block_addr][block_offset+:`INSTR_WIDTH] = 32'hfe010113;
        end
        // else begin
        //     automatic logic [`BLOCK_DATA_WIDTH-block_offset-1:0] instr_part1;
        //     automatic logic [`INSTR_WIDTH-$bits(instr_part1)-1:0] instr_part2;
        //     {instr_part1, instr_part2} = 32'hfe010113;
        //     init_main_mem_state[block_addr][`BLOCK_DATA_WIDTH-1:block_offset] = instr_part1;
        //     init_main_mem_state[block_addr+1][$bits(instr_part2)-1:0] = instr_part2;
        // end
    end


    wire [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] ARF_OUT;

    top _top (
        .clk(clk),
        .rst_aL(),
        .init(init),
        .init_pc(init_pc),
        .init_main_mem_state(init_main_mem_state),
        .ARF_OUT(ARF_OUT)
    );

    // for (genvar i = 0; i < `ARF_N_ENTRIES; i++)
    //         $monitor("ARF[%0d] = %b", i, ARF_OUT[i]);

    initial begin

        $monitor("%b", ARF_OUT);
        // $monitor("%p", _top._main_mem.mem);
        $monitor("%b", _top._mem_ctrl.icache_req_valid);
        $monitor("%b", _top._mem_ctrl.icache_req_block_addr);
        $monitor("%b", _top._mem_ctrl.icache_req_ready);
        $monitor("%t, %p", $time, _top._main_mem.req_pipeline);

        #1;
        init = 1;
        #1;
        init = 0;
        #1;
        @(negedge clk);
        @(negedge clk);
        repeat (10)
            @(negedge clk);
        $finish;
    end
endmodule
