// TODO: probably remove this
module shift_register #(
  parameter WIDTH = 1,
  parameter SHIFT_AMOUNT = 1
) (
  input wire clk,
  input wire rst,
  input wire shft,
  input wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);


  // always @(posedge clk or posedge reset) begin
  //   if (reset) begin
  //     // Reset the shift register to all zeros
  //     data_out <= 4'b0000;
  //   end else begin
  //     // Shift data to the right by the specified SHIFT_AMOUNT
  //     data_out <= {data_out[3-SHIFT_AMOUNT:0], data_in};
  //   end
  // end
  generate
    for (genvar i = 0; i < WIDTH; i++) begin

      dff_we dff(.clk(clk), .rst(rst), .we(shft), .d(dff), .q())
    end
  endgenerate

endmodule