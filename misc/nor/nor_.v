`ifndef NOR_V
`define NOR_V

`include "misc/or/or_.v"
`include "misc/inv/inv.v"

module nor_ #(
    parameter N_INS
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    wire or_y;
    or_ #(.N_INS(N_INS)) _or (
        .a(a),
        .y(or_y)
    );

    inv _inv (
        .a(or_y),
        .y(y)
    );
endmodule

`endif
