module dff_we_golden (
    input logic clk,
    input logic rst_aL,
    input logic we,
    input logic d,
    output logic q
);
    logic q_r;
    always_ff @(posedge clk or negedge rst_aL) begin
        if (!rst_aL) begin
            q_r <= 0;
        end else if (we) begin
            q_r <= d;
        end
    end
    assign q = q_r;
endmodule
