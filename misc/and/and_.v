`ifndef AND_V
`define AND_V

// `include "freepdk-45nm/stdcells.v"
`include "misc/and/and8.v"
`include "misc/and/and16.v"
`include "misc/and/and32.v"

// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
module and_ #(
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    case (N_INS)
        2: AND2_X1 and_gate (
            .A1(a[0]),
            .A2(a[1]),
            .ZN(y)
        );
        3: AND3_X1 and_gate (
            .A1(a[0]),
            .A2(a[1]),
            .A3(a[2]),
            .ZN(y)
        );
        4: AND4_X1 and_gate (
            .A1(a[0]),
            .A2(a[1]),
            .A3(a[2]),
            .A4(a[3]),
            .ZN(y)
        );
        5: and8 and_gate (
            .a({a, 3'b111}),
            .y(y)
        );
        6: and8 and_gate (
            .a({a, 2'b11}),
            .y(y)
        );
        7: and8 and_gate (
            .a({a, 1'b1}),
            .y(y)
        );
        8: and8 and_gate (
            .a(a),
            .y(y)
        );
        9: and16 and_gate (
            .a({a, 7'b1111111}),
            .y(y)
        );
        10: and16 and_gate (
            .a({a, 6'b111111}),
            .y(y)
        );
        11: and16 and_gate (
            .a({a, 5'b11111}),
            .y(y)
        );
        12: and16 and_gate (
            .a({a, 4'b1111}),
            .y(y)
        );
        13: and16 and_gate (
            .a({a, 3'b111}),
            .y(y)
        );
        14: and16 and_gate (
            .a({a, 2'b11}),
            .y(y)
        );
        15: and16 and_gate (
            .a({a, 1'b1}),
            .y(y)
        );
        16: and16 and_gate (
            .a(a),
            .y(y)
        );
        17: and32 and_gate (
            .a({a, 15'b111111111111111}),
            .y(y)
        );
        18: and32 and_gate (
            .a({a, 14'b11111111111111}),
            .y(y)
        );
        19: and32 and_gate (
            .a({a, 13'b1111111111111}),
            .y(y)
        );
        20: and32 and_gate (
            .a({a, 12'b111111111111}),
            .y(y)
        );
        21: and32 and_gate (
            .a({a, 11'b11111111111}),
            .y(y)
        );
        22: and32 and_gate (
            .a({a, 10'b1111111111}),
            .y(y)
        );
        23: and32 and_gate (
            .a({a, 9'b111111111}),
            .y(y)
        );
        24: and32 and_gate (
            .a({a, 8'b11111111}),
            .y(y)
        );
        25: and32 and_gate (
            .a({a, 7'b1111111}),
            .y(y)
        );
        26: and32 and_gate (
            .a({a, 6'b111111}),
            .y(y)
        );
        27: and32 and_gate (
            .a({a, 5'b11111}),
            .y(y)
        );
        28: and32 and_gate (
            .a({a, 4'b1111}),
            .y(y)
        );
        29: and32 and_gate (
            .a({a, 3'b111}),
            .y(y)
        );
        30: and32 and_gate (
            .a({a, 2'b11}),
            .y(y)
        );
        31: and32 and_gate (
            .a({a, 1'b1}),
            .y(y)
        );
        32: and32 and_gate (
            .a(a),
            .y(y)
        );
        default: begin
            assign y = 1'b0;
        end
    endcase
endmodule

`endif
