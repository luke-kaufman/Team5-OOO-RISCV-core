`ifndef ONEHOT_MUX_V
`define ONEHOT_MUX_V

`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module onehot_mux_ #(
    parameter WIDTH = 1,
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] [WIDTH-1:0] ins,
    input wire [N_INS-1:0] sel,
    output wire [WIDTH-1:0] out
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
endmodule

`endif
