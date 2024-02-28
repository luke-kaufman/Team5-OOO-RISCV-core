// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux8 #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] [7:0] ins,
    input wire [3:0] sel;
    output wire [WIDTH-1:0] out
);
    // invert the select lines
    wire [3:0] inv_sel;
    INV_X1 inv(.a(sel[0]), .y(inv_sel[0]));
    INV_X1 inv(.a(sel[1]), .y(inv_sel[1]));
    INV_X1 inv(.a(sel[2]), .y(inv_sel[2]));

    // the gated inputs
    wire [WIDTH-1:0] [7:0] gated_ins;
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            // AND gates for each input condition
            AND4_X1 and_gate0(.A1(inv_sel[2]), .A2(inv_sel[1]), .A3(inv_sel[0]), .A4(ins[0][i]), .ZN(gated_ins[0][i]));
            AND4_X1 and_gate1(.A1(inv_sel[2]), .A2(inv_sel[1]), .A3(sel[0]), .A4(ins[1][i]), .ZN(gated_ins[1][i]));
            AND4_X1 and_gate2(.A1(inv_sel[2]), .A2(sel[1]), .A3(inv_sel[0]), .A4(ins[2][i]), .ZN(gated_ins[2][i]));
            AND4_X1 and_gate3(.A1(inv_sel[2]), .A2(sel[1]), .A3(sel[0]), .A4(ins[3][i]), .ZN(gated_ins[3][i]));
            AND4_X1 and_gate4(.A1(sel[2]), .A2(inv_sel[1]), .A3(inv_sel[0]), .A4(ins[4][i]), .ZN(gated_ins[4][i]));
            AND4_X1 and_gate5(.A1(sel[2]), .A2(inv_sel[1]), .A3(sel[0]), .A4(ins[5][i]), .ZN(gated_ins[5][i]));
            AND4_X1 and_gate6(.A1(sel[2]), .A2(sel[1]), .A3(inv_sel[0]), .A4(ins[6][i]), .ZN(gated_ins[6][i]));
            AND4_X1 and_gate7(.A1(sel[2]), .A2(sel[1]), .A3(sel[0]), .A4(ins[7][i]), .ZN(gated_ins[7][i]));
    
            // OR gate to combine the AND gates outputs
            or8 or_gate(.a(gated_ins), .y(out));
        end
    endgenerate
endmodule