`ifndef ONEHOT_MUX_V
`define ONEHOT_MUX_V

// `include "freepdk-45nm/stdcells.v"

// IMPL STATUS: MISSING
// TEST STATUS: MISSING
module onehot_mux_ #(
    parameter WIDTH = 1,
    parameter N_INS = 2
) (
    input wire [N_INS-1:0] [WIDTH-1:0] ins,
    input wire [N_INS-1:0] sel,
    output logic [WIDTH-1:0] out // FIXME: change to wire by implementing in structural
);
    // TODO: fix this. gives syntax error
    // always @(*) begin
    //     for (genvar i = 0; i < WIDTH; i++) begin
    //         wire [N_INS-1:0] ins_i;
    //         for (genvar j = 0; j < N_INS; j++) begin
    //             assign ins_i[j] = ins[j][i];
    //         end
    //         assign out[i] = |(ins_i & sel);
    //     end
    // end
    always_comb begin
        out = {WIDTH{1'b0}};
        for (int i = 0; i < N_INS; i++) begin
            if (sel[i]) begin
                out = ins[i];
                break; // NOTE: icarus does not support break
            end
        end
    end

    // write a systemverilog assert that will continuously assert that only one bit is set in sel
    assert property (|sel == 1'b1) else $error("sel must have exactly one bit set");
endmodule

`endif
