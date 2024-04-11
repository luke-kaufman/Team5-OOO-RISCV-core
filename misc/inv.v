`ifndef INV_V
`define INV_V

// `include "freepdk-45nm/stdcells.v"

module inv (
    input wire a,
    output wire y
);
    INV_X1 inv (
        .A(a),
        .ZN(y)
    );
endmodule

`endif
