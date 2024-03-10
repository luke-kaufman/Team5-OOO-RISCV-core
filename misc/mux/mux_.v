`ifndef MUX_V
`define MUX_V

`include "freepdk-45nm/stdcells.v"
`include "misc/and/and_.v"
`include "misc/or/or_.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: COMPLETE

module mux_ #(
    parameter WIDTH = 1,
    parameter N_INS = 2,
    localparam SEL_WIDTH = $clog2(N_INS)
) (
    input wire [N_INS-1:0][WIDTH-1:0] ins,
    input wire [SEL_WIDTH-1:0] sel,
    output wire [WIDTH-1:0] out
);
    // invert the select signals
    wire [SEL_WIDTH-1:0] inv_sel;
    for (genvar i = 0; i < SEL_WIDTH; i = i + 1) begin
        INV_X1 inv(
            .A(sel[i]),
            .ZN(inv_sel[i])
        );
    end

    // the gated inputs
    wire [N_INS-1:0][WIDTH-1:0] gated_ins;
    genvar i,j,k;
    // for each bit 
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            
            // ith bit of input j
            wire [N_INS-1:0] gated_ins_i;
            for(j = 0; j < N_INS; j = j + 1) begin

                wire [(SEL_WIDTH+1)-1:0] and_in;
                assign and_in[0] = ins[j][i];
                for(k = 0; k < SEL_WIDTH; k = k + 1) begin
                    assign and_in[k+1] = (j & (1'b1 << k)) ? sel[k] : inv_sel[k];
                end

                and_ #(.N_INS(SEL_WIDTH+1)) and_gate(
                    .a(and_in),
                    .y(gated_ins[j][i])
                );

                // store the "column" of bits (ith bit of each input) so we can or it after
                assign gated_ins_i[j] = gated_ins[j][i];
            end

            // OR gate to combine the AND gates outputs
            or_ #(.N_INS(N_INS)) or_gate(.a(gated_ins_i), .y(out[i]));
        end
    endgenerate
endmodule

`endif
