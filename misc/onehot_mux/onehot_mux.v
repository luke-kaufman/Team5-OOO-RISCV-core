`ifndef ONEHOT_MUX_V
`define ONEHOT_MUX_V

`include "misc/global_defs.svh"

module onehot_mux #(
    parameter WIDTH,
    parameter N_INS
) (
    input wire clk,
    input wire [N_INS-1:0] [WIDTH-1:0] ins,
    input wire [N_INS-1:0] sel,
    output logic [WIDTH-1:0] out // FIXME: change to wire by implementing in structural
);
    // TODO: fix this. gives syntax error
    // always @(*) begin
    //     for (genvar i = 0; i < WIDTH; i++) begin
    //         wire [N_INS-1:0] ins_i;
    //         for (genvar j = 0; j < N_INS; j++) begin
    //             assign ins_i[j] = ins[j][i];
    //         end
    //         assign out[i] = |(ins_i & sel);
    //     end
    // end
    always_comb begin
        out = {WIDTH{1'b0}};
        for (int i = 0; i < N_INS; i++) begin
            if (sel[i]) begin
                out = ins[i];
                break; // NOTE: icarus does not support break
            end
        end
    end

    // assertions
    function void no_double_select(edge_t _edge);
        if (!$onehot0(sel)) begin
            $error(
                "Assertion failed: sel is not one-hot or all-zeros after %0s.\n\
                sel = %b\n",
                _edge == NEGEDGE ? "setting init_state and driving inputs" : "state transition",
                sel
            );
        end
    endfunction


    // always @(negedge clk) begin #1
    //     no_double_select(NEGEDGE);
    // end
    // always @(posedge clk) begin #1
    //     no_double_select(POSEDGE);
    // end
endmodule

`endif
