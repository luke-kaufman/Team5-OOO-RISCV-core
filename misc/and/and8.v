`ifndef AND8_V
`define AND8_V

module and8 (
    input wire [7:0] a,
    output wire y
);
    wire and0;
    wire and1;

    AND4_X1 _and0(.A1(a[0]), .A2(a[1]), .A3(a[2]), .A4(a[3]), .ZN(and0));
    AND4_X1 _and1(.A1(a[4]), .A2(a[5]), .A3(a[6]), .A4(a[7]), .ZN(and1));

    AND2_X1 _and_y(.A1(and0), .A2(and1), .ZN(y));
endmodule

`endif
