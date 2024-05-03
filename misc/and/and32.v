`ifndef AND32_V
`define AND32_V

`include "misc/and/and16.v"

module and32 (
    input wire [31:0] a,
    output wire y
);
    wire and0;
    wire and1;

    and16 _and0(.a(a[15:0]), .y(and0));
    and16 _and1(.a(a[31:16]), .y(and1));

    AND2_X1 _and_y(.A1(and0), .A2(and1), .ZN(y));
endmodule

`endif
