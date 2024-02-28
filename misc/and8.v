// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module and8 (
    input wire [7:0] a,
    output wire y
);
    // Generate a first level of 2 4-input AND gates
    wire [1:0] y1;
    generate
        for (genvar i = 0; i < 2; i = i + 1) begin
            AND4_X1 and4_inst (
                .A1(a[i*4 + 0]),
                .A2(a[i*4 + 1]),
                .A3(a[i*4 + 2]),
                .A4(a[i*4 + 3]),
                .ZN(y1[i])
            );
        end
    endgenerate

    // Generate a second level of 1 2-input AND gate
    AND2_X1 and2_inst (
        .A1(y1[0]),
        .A2(y1[1]),
        .ZN(y)
    );
endmodule