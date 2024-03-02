`ifndef AND32_V
`define AND32_V

`include "freepdk-45nm/stdcells.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module and32 (
    input wire [31:0] a,
    output wire y
);
    // Generate a first level of 8 4-input AND gates
    wire [7:0] y1;
    for (genvar i = 0; i < 8; i++) begin
        AND4_X1 and_gate (
            .A1(a[i*4+0]),
            .A2(a[i*4+1]),
            .A3(a[i*4+2]),
            .A4(a[i*4+3]),
            .ZN(y1[i])
        );
    end

    // Generate a second level of 2 4-input AND gates
    wire [1:0] y2;
    for (genvar i = 0; i < 2; i++) begin
        AND4_X1 and_gate (
            .A1(y1[i*4+0]),
            .A2(y1[i*4+1]),
            .A3(y1[i*4+2]),
            .A4(y1[i*4+3]),
            .ZN(y2[i])
        );
    end

    // Generate a third level of 1 2-input AND gate
    AND2_X1 and_gate (
        .A1(y2[0]),
        .A2(y2[1]),
        .ZN(y)
    );
endmodule

`endif
