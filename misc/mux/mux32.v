// IMPL STATUS: COMPLETE
// TEST STATUS: COMPLETE

`ifndef MUX32_V
`define MUX32_V
`include "freepdk-45nm/stdcells.v"
`include "misc/global_defs.svh"
`include "misc/and/and8.v"
`include "misc/or/or32.v"

module mux32 #(
    parameter WIDTH = 1
) (
    input wire [31:0][WIDTH-1:0] ins,
    input wire [4:0] sel,
    output wire [WIDTH-1:0] out
);
    // invert the select signals
    wire [4:0] inv_sel;
    for (genvar i = 0; i < 5; i = i + 1) begin
        INV_X1 inv(
            .A(sel[i]),
            .ZN(inv_sel[i])
        );
    end

    // the gated inputs
    wire [31:0][WIDTH-1:0] gated_ins;
    genvar i,j;
    // for each bit 
    for (i = 0; i < WIDTH; i = i + 1) begin
        
        // ith bit of input j
        wire [31:0] gated_ins_i;
        for(j = 0; j < 32; j = j + 1) begin
            // AND gates for each input condition
            and8 and_gate(
                .a({
                    1'b1,
                    1'b1,
                    (j & 5'b00001) ? sel[0] : inv_sel[0],
                    (j & 5'b00010) ? sel[1] : inv_sel[1],
                    (j & 5'b00100) ? sel[2] : inv_sel[2],
                    (j & 5'b01000) ? sel[3] : inv_sel[3],
                    (j & 5'b10000) ? sel[4] : inv_sel[4],
                    ins[j][i]
                }),
                .y(gated_ins[j][i])
            );
            // store the "column" of bits (ith bit of each input) so we can or it after
            assign gated_ins_i[j] = gated_ins[j][i];
        end

        // OR gate to combine the AND gates outputs
        or32 or_gate(.a(gated_ins_i), .y(out[i]));
    end
endmodule
`endif
