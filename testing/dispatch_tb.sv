`include "misc/global_defs.svh"
`include "top/top.sv"

module dispatch_tb #(
    parameter addr_t HIGHEST_PC = 32'h10194,
    localparam main_mem_block_addr_t HIGHEST_INSTR_BLOCK_ADDR = HIGHEST_PC >> `MAIN_MEM_BLOCK_OFFSET_WIDTH
);
    bit clk = 1;
    bit init = 0;
    addr_t init_pc = 32'h1018c;
    reg_data_t init_sp = init_pc - 4;
    main_mem_block_addr_t block_addr0;
    main_mem_block_offset_t block_offset0;
    main_mem_block_addr_t block_addr1;
    main_mem_block_offset_t block_offset1;
    main_mem_block_addr_t block_addr2;
    main_mem_block_offset_t block_offset2;
    // block_data_t init_main_mem_state[`MAIN_MEM_N_BLOCKS];
    block_data_t init_main_mem_state[HIGHEST_INSTR_BLOCK_ADDR:0];

    initial forever #5 clk = ~clk;

    initial begin
        // for (int i = 0; i < `MAIN_MEM_N_BLOCKS; i++) begin // TODO: double-check if this is correct
        //     init_main_mem_state[i] = '0;
        // end
        {block_addr0, block_offset0} = 32'h1018c; // 0001 0000 0001 1000 1100
        // test_programs[s_i].prog[32'h10190]=32'h02812623;
        if (8*block_offset0 + `INSTR_WIDTH <= `BLOCK_DATA_WIDTH) begin
            // init_main_mem_state[block_addr0][8*block_offset0+:`INSTR_WIDTH] = 32'hfe010113;
            init_main_mem_state[block_addr0][8*block_offset0+:`INSTR_WIDTH] = 32'hfe010113;
        end
        {block_addr1, block_offset1} = 32'h10190; // 0001 0000 0001 1001 0000
        if (8*block_offset1 + `INSTR_WIDTH <= `BLOCK_DATA_WIDTH) begin
            // init_main_mem_state[block_addr1][8*block_offset1+:`INSTR_WIDTH] = 32'hfe010113;
            init_main_mem_state[block_addr1][8*block_offset1+:`INSTR_WIDTH] = 32'h00812e23;
        end
        {block_addr2, block_offset2} = 32'h10194; // 0001 0000 0001 1001 0100
        if (8*block_offset2 + `INSTR_WIDTH <= `BLOCK_DATA_WIDTH) begin
            // init_main_mem_state[block_addr2][8*block_offset2+:`INSTR_WIDTH] = 32'hfe010113;
            init_main_mem_state[block_addr2][8*block_offset2+:`INSTR_WIDTH] = 32'h00912c23;
        end
        // else begin
        //     automatic logic [`BLOCK_DATA_WIDTH-block_offset-1:0] instr_part1;
        //     automatic logic [`INSTR_WIDTH-$bits(instr_part1)-1:0] instr_part2;
        //     {instr_part1, instr_part2} = 32'hfe010113;
        //     init_main_mem_state[block_addr][`BLOCK_DATA_WIDTH-1:block_offset] = instr_part1;
        //     init_main_mem_state[block_addr+1][$bits(instr_part2)-1:0] = instr_part2;
        // end
        // test_ifu_outs[s_i] = new();
        // foreach (test_programs[s_i].prog[key_PC]) begin
        //     test_ifu_outs[s_i].ifu_out[key_PC].instr = test_programs[s_i].prog[key_PC];
        //     test_ifu_outs[s_i].ifu_out[key_PC].pc = key_PC;
        //     test_ifu_outs[s_i].ifu_out[key_PC].is_cond_br = 0;
        //     test_ifu_outs[s_i].ifu_out[key_PC].br_dir_pred = (key_PC == 32'h101e0);
        //     test_ifu_outs[s_i].ifu_out[key_PC].br_target_pred = key_PC + 4;
        // end
    end


    wire [`ARF_N_ENTRIES-1:0] [`REG_DATA_WIDTH-1:0] ARF_OUT;

    top #(
        .HIGHEST_PC(HIGHEST_PC)
    ) _top (
        .clk(clk),
        .rst_aL(),
        .init(init),
        .init_pc(init_pc),
        .init_sp(init_sp),
        .init_main_mem_state(init_main_mem_state),
        .ARF_OUT(ARF_OUT)
    );

    initial begin
        // #161 $display("%0t selected_instr: %h", $time, _top._core._ifu.selected_instr);
        // $display("%0t offset: %h", $time, _top._core._ifu.icache.pipeline_req_addr_offset_latched);
    end

    initial begin
        // $display("%0t way1_data: %b", $time, _top._core._ifu.icache.data_array_dout.way1_data);
        // #101 $display("%0t way1_data: %b", $time, _top._core._ifu.icache.data_array_dout.way1_data);

        // $display("%0t sel_data_behind[0]: %b", $time, _top._core.integer_issue_dut.iiq.sel_data_behind[0]);
        // $display("%0t sel_enq_data[0]: %b", $time, _top._core.integer_issue_dut.iiq.sel_enq_data[0]);
        // $display("%0t sel_wr_data[0]: %b", $time, _top._core.integer_issue_dut.iiq.sel_wr_data[0]);
        // $display("%0t sel_wr_data_behind[0]: %b", $time, _top._core.integer_issue_dut.iiq.sel_wr_data_behind[0]);
//         #164 $display("%0t sel_way0: %b, sel_way1: %b", $time, _top._core._ifu.icache.sel_way0, _top._core._ifu.icache.sel_way1);
//         $display("%0t tag_array_dout.way0_valid: %b, tag_array_dout.way0_tag: %b, PC_mux_out: %b", $time, _top._core._ifu.icache.tag_array_dout.way0_valid, _top._core._ifu.icache.tag_array_dout.way0_tag, _top._core._ifu.PC_mux_out);
//         $display(
//             "%0t
// fetch_redirect_PC: %b
// PC_wire: %b
// next_PC: %b
// fetch_redirect_valid: %b
// stall: %b",
// $time,
//           _top._core._ifu.fetch_redirect_PC,
//           _top._core._ifu.PC_wire,
//           _top._core._ifu.next_PC,
//           _top._core._ifu.fetch_redirect_valid,
        //   _top._core._ifu.stall);
        // tag_array_dout.way0_valid & (tag_array_dout.way0_tag == pipeline_req_addr_tag_latched)
    end

    always @(negedge clk) begin #1
        $display("%0t pipeline_req_addr_tag_latched: %b", $time, _top._core._ifu.icache.pipeline_req_addr_tag_latched);
        $display("%0t pipeline_req_addr_index_latched: %b", $time, _top._core._ifu.icache.pipeline_req_addr_index_latched);
        $display("%0t pipeline_req_addr_offset_latched: %b", $time, _top._core._ifu.icache.pipeline_req_addr_offset_latched);
        $display("%0t pipeline_resp_valid: %b", $time, _top._core._ifu.icache.pipeline_resp_valid);
        // $display("%0t data_array_addr: %b", $time, _top._core._ifu.icache.data_array_addr);
        $display("%0t data_array_dout: %h", $time, _top._core._ifu.icache.data_array_dout);
        $display("%0t sel_way0: %h", $time, _top._core._ifu.icache.sel_way0);
        $display("%0t sel_way1: %h", $time, _top._core._ifu.icache.sel_way1);

        $display("%0t selected_instr: %h", $time, _top._core._ifu.selected_instr);
        $display("%0t PC_mux_out: %h", $time, _top._core._ifu.PC_mux_out);
         $display(
            "%0t
fetch_redirect_PC: %b
PC_wire: %b
next_PC: %b
fetch_redirect_valid: %b
stall: %b",
$time,
          _top._core._ifu.fetch_redirect_PC,
          _top._core._ifu.PC_wire,
          _top._core._ifu.next_PC,
          _top._core._ifu.fetch_redirect_valid,
          _top._core._ifu.stall);
    end

    initial begin
        // $monitor("%b", ARF_OUT);
        // $monitor("%0t PC_mux_out: %b", $time, _top._core._ifu.PC_mux_out);
        $monitor("%0t ififo: %h", $time, _top._core._ifu.instruction_FIFO.entry_dout);
        // $monitor("%0t selected_instr: %h", $time, _top._core._ifu.selected_instr);
        // $monitor("%0t tag_array_hit: %b", $time, _top._core._ifu.icache.tag_array_hit);

        // $monitor("%p", _top._main_mem.mem);
        // $monitor("%b", _top._mem_ctrl.icache_req_valid);
        // $monitor("%b", _top._mem_ctrl.icache_req_block_addr);
        // $monitor("%b", _top._mem_ctrl.icache_req_ready);
        // $monitor("%t, %p", $time, _top._main_mem.req_pipeline);

        #1;
        init = 1;
        #1;
        init = 0;
        #1;
        @(negedge clk);
        @(negedge clk);
        repeat (25)
            @(negedge clk);
        $finish;
    end
endmodule
