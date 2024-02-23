module parametric_and #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    parameter N_LVL1_AND4S = N_INS / 4;
    parameter N_LVL2_INS = N_LVL1_AND4S + (N_INS % 4);
    wire [N_LVL1_AND4S-1:0] lvl1_and4_outs;
    wire [N_LVL2_INS-1:0] lvl2_ins;

    generate
        for (genvar i = 0; i < N_LVL1_AND4S; i = i + 1) begin
            AND4_X1 and4(.A1(a[i*4]), .A2(a[i*4+1]), .A3(a[i*4+2]), .A4(a[i*4+3]), .Z(lvl1_and4_outs[i]));
        end
    endgenerate

    // TODO: finish this
    assign lvl2_ins = {a[N_LVL2_INS-1 : N_LVL1_INS-1 - ()]};
endmodule
