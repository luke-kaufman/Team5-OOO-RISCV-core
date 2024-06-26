`ifndef CMP32_V
`define CMP32_V

// IMPL STATUS: COMPLETE
// TEST STATUS: COMPLETE

// `include "freepdk-45nm/stdcells.v"
`include "misc/and/and32.v"

module cmp32 (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire y
);
    wire [31:0] eq;

    generate
        for (genvar i = 0; i < 32; i = i + 1) begin
            XNOR2_X1 xnor_(.A(a[i]), .B(b[i]), .ZN(eq[i]));
        end
    endgenerate

    and32 and_(.a(eq), .y(y));
endmodule

`endif
