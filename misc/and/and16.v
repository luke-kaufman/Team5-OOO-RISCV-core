`ifndef AND16_V
`define AND16_V

`include "misc/and/and8.v"

module and16 (
    input wire [15:0] a,
    output wire y
);
    wire and0;
    wire and1;

    and8 _and0(.a(a[7:0]), .y(and0));
    and8 _and1(.a(a[15:8]), .y(and1));

    AND2_X1 _and_y(.A1(and0), .A2(and1), .ZN(y));
endmodule

`endif
