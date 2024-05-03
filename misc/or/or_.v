`ifndef OR_V
`define OR_V

`include "misc/or/or8.v"
`include "misc/or/or16.v"
`include "misc/or/or32.v"

module or_ #(
    parameter N_INS
) (
    input wire [N_INS-1:0] a,
    output wire y
);
    case (N_INS)
        2: OR2_X1 _or (
            .A1(a[0]),
            .A2(a[1]),
            .ZN(y)
        );
        3: OR3_X1 _or (
            .A1(a[0]),
            .A2(a[1]),
            .A3(a[2]),
            .ZN(y)
        );
        4: OR4_X1 _or (
            .A1(a[0]),
            .A2(a[1]),
            .A3(a[2]),
            .A4(a[3]),
            .ZN(y)
        );
        5: or8 _or (
            .a({a, 3'b000}),
            .y(y)
        );
        6: or8 _or (
            .a({a, 2'b00}),
            .y(y)
        );
        7: or8 _or (
            .a({a, 1'b0}),
            .y(y)
        );
        8: or8 _or (
            .a(a),
            .y(y)
        );
        9: or16 _or (
            .a({a, 7'b0000_000}),
            .y(y)
        );
        10: or16 _or (
            .a({a, 6'b0000_00}),
            .y(y)
        );
        11: or16 _or (
            .a({a, 5'b0000_0}),
            .y(y)
        );
        12: or16 _or (
            .a({a, 4'b0000}),
            .y(y)
        );
        13: or16 _or (
            .a({a, 3'b000}),
            .y(y)
        );
        14: or16 _or (
            .a({a, 2'b00}),
            .y(y)
        );
        15: or16 _or (
            .a({a, 1'b0}),
            .y(y)
        );
        16: or16 _or (
            .a(a),
            .y(y)
        );
        17: or32 _or (
            .a({a, 15'b0000_0000_0000_000}),
            .y(y)
        );
        18: or32 _or (
            .a({a, 14'b0000_0000_0000_00}),
            .y(y)
        );
        19: or32 _or (
            .a({a, 13'b0000_0000_0000_0}),
            .y(y)
        );
        20: or32 _or (
            .a({a, 12'b0000_0000_0000}),
            .y(y)
        );
        21: or32 _or (
            .a({a, 11'b0000_0000_000}),
            .y(y)
        );
        22: or32 _or (
            .a({a, 10'b0000_0000_00}),
            .y(y)
        );
        23: or32 _or (
            .a({a, 9'b0000_0000_0}),
            .y(y)
        );
        24: or32 _or (
            .a({a, 8'b0000_0000}),
            .y(y)
        );
        25: or32 _or (
            .a({a, 7'b0000_000}),
            .y(y)
        );
        26: or32 _or (
            .a({a, 6'b0000_00}),
            .y(y)
        );
        27: or32 _or (
            .a({a, 5'b0000_0}),
            .y(y)
        );
        28: or32 _or (
            .a({a, 4'b0000}),
            .y(y)
        );
        29: or32 _or (
            .a({a, 3'b000}),
            .y(y)
        );
        30: or32 _or (
            .a({a, 2'b00}),
            .y(y)
        );
        31: or32 _or (
            .a({a, 1'b0}),
            .y(y)
        );
        32: or32 _or (
            .a(a),
            .y(y)
        );
        default: begin
            assign y = 1'b0;
        end
    endcase
endmodule

`endif
