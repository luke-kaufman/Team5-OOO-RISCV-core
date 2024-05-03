`ifndef INV_V
`define INV_V

module inv (
    input wire a,
    output wire y
);
    INV_X1 _inv (
        .A(a),
        .ZN(y)
    );
endmodule

`endif
