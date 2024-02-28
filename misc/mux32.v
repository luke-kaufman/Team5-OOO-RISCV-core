// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module mux32 #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] [31:0] ins,
    input wire [4:0] sel,
    output wire [WIDTH-1:0] out
);
    // invert the select signals
    wire [4:0] inv_sel;
    generate
        for (genvar i = 0; i < 5; i = i + 1) begin
            INV_X1 inv(
                .a(sel[i]),
                .y(inv_sel[i])
            );
        end
    endgenerate

    // the gated inputs
    wire [WIDTH-1:0] [31:0] gated_ins;
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            // AND gates for each input condition
            and8 and_gate0(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], inv_sel[2], inv_sel[1], inv_sel[0], ins[0][i]}), .y(gated_ins[0][i]));
            and8 and_gate1(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], inv_sel[2], inv_sel[1], sel[0], ins[1][i]}), .y(gated_ins[1][i]));
            and8 and_gate2(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], inv_sel[2], sel[1], inv_sel[0], ins[2][i]}), .y(gated_ins[2][i]));
            and8 and_gate3(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], inv_sel[2], sel[1], sel[0], ins[3][i]}), .y(gated_ins[3][i]));
            and8 and_gate4(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], sel[2], inv_sel[1], inv_sel[0], ins[4][i]}), .y(gated_ins[4][i]));
            and8 and_gate5(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], sel[2], inv_sel[1], sel[0], ins[5][i]}), .y(gated_ins[5][i]));
            and8 and_gate6(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], sel[2], sel[1], inv_sel[0], ins[6][i]}), .y(gated_ins[6][i]));
            and8 and_gate7(.a({1'b1, 1'b1, inv_sel[4], inv_sel[3], sel[2], sel[1], sel[0], ins[7][i]}), .y(gated_ins[7][i]));
            and8 and_gate8(.a({1'b1, 1'b1, inv_sel[4], sel[3], inv_sel[2], inv_sel[1], inv_sel[0], ins[8][i]}), .y(gated_ins[8][i]));
            and8 and_gate9(.a({1'b1, 1'b1, inv_sel[4], sel[3], inv_sel[2], inv_sel[1], sel[0], ins[9][i]}), .y(gated_ins[9][i]));
            and8 and_gate10(.a({1'b1, 1'b1, inv_sel[4], sel[3], inv_sel[2], sel[1], inv_sel[0], ins[10][i]}), .y(gated_ins[10][i]));
            and8 and_gate11(.a({1'b1, 1'b1, inv_sel[4], sel[3], inv_sel[2], sel[1], sel[0], ins[11][i]}), .y(gated_ins[11][i]));
            and8 and_gate12(.a({1'b1, 1'b1, inv_sel[4], sel[3], sel[2], inv_sel[1], inv_sel[0], ins[12][i]}), .y(gated_ins[12][i]));
            and8 and_gate13(.a({1'b1, 1'b1, inv_sel[4], sel[3], sel[2], inv_sel[1], sel[0], ins[13][i]}), .y(gated_ins[13][i]));
            and8 and_gate14(.a({1'b1, 1'b1, inv_sel[4], sel[3], sel[2], sel[1], inv_sel[0], ins[14][i]}), .y(gated_ins[14][i]));
            and8 and_gate15(.a({1'b1, 1'b1, inv_sel[4], sel[3], sel[2], sel[1], sel[0], ins[15][i]}), .y(gated_ins[15][i]));
            and8 and_gate16(.a({1'b1, 1'b1, sel[4], inv_sel[3], inv_sel[2], inv_sel[1], inv_sel[0], ins[16][i]}), .y(gated_ins[16][i]));
            and8 and_gate17(.a({1'b1, 1'b1, sel[4], inv_sel[3], inv_sel[2], inv_sel[1], sel[0], ins[17][i]}), .y(gated_ins[17][i]));
            and8 and_gate18(.a({1'b1, 1'b1, sel[4], inv_sel[3], inv_sel[2], sel[1], inv_sel[0], ins[18][i]}), .y(gated_ins[18][i]));
            and8 and_gate19(.a({1'b1, 1'b1, sel[4], inv_sel[3], inv_sel[2], sel[1], sel[0], ins[19][i]}), .y(gated_ins[19][i]));
            and8 and_gate20(.a({1'b1, 1'b1, sel[4], inv_sel[3], sel[2], inv_sel[1], inv_sel[0], ins[20][i]}), .y(gated_ins[20][i]));
            and8 and_gate21(.a({1'b1, 1'b1, sel[4], inv_sel[3], sel[2], inv_sel[1], sel[0], ins[21][i]}), .y(gated_ins[21][i]));
            and8 and_gate22(.a({1'b1, 1'b1, sel[4], inv_sel[3], sel[2], sel[1], inv_sel[0], ins[22][i]}), .y(gated_ins[22][i]));
            and8 and_gate23(.a({1'b1, 1'b1, sel[4], inv_sel[3], sel[2], sel[1], sel[0], ins[23][i]}), .y(gated_ins[23][i]));
            and8 and_gate24(.a({1'b1, 1'b1, sel[4], sel[3], inv_sel[2], inv_sel[1], inv_sel[0], ins[24][i]}), .y(gated_ins[24][i]));
            and8 and_gate25(.a({1'b1, 1'b1, sel[4], sel[3], inv_sel[2], inv_sel[1], sel[0], ins[25][i]}), .y(gated_ins[25][i]));
            and8 and_gate26(.a({1'b1, 1'b1, sel[4], sel[3], inv_sel[2], sel[1], inv_sel[0], ins[26][i]}), .y(gated_ins[26][i]));
            and8 and_gate27(.a({1'b1, 1'b1, sel[4], sel[3], inv_sel[2], sel[1], sel[0], ins[27][i]}), .y(gated_ins[27][i]));
            and8 and_gate28(.a({1'b1, 1'b1, sel[4], sel[3], sel[2], inv_sel[1], inv_sel[0], ins[28][i]}), .y(gated_ins[28][i]));
            and8 and_gate29(.a({1'b1, 1'b1, sel[4], sel[3], sel[2], inv_sel[1], sel[0], ins[29][i]}), .y(gated_ins[29][i]));
            and8 and_gate30(.a({1'b1, 1'b1, sel[4], sel[3], sel[2], sel[1], inv_sel[0], ins[30][i]}), .y(gated_ins[30][i]));
            and8 and_gate31(.a({1'b1, 1'b1, sel[4], sel[3], sel[2], sel[1], sel[0], ins[31][i]}), .y(gated_ins[31][i]));

            // OR gate to combine the AND gates outputs
            or32 or_gate(.a(gated_ins[i]), .y(out[i]));
        end
    endgenerate
endmodule
