// IMPL STATUS: COMPLETE
// TEST STATUS: MISSING
// WARNING: the burden of making sure the select line is one-hot is on the user
module onehot_mux2 #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] d0,
    input wire [WIDTH-1:0] d1,
    input wire [1:0] s,         
    output wire [WIDTH-1:0] y
);
    // Internal signals
    wire [WIDTH-1:0] _d0, _d1;
    
generate
    for (genvar i = 0; i < WIDTH; i = i + 1) begin
        AND2_X1 and_gate1(s[0], d0[i], _d0[i]);     // d0 is selected when s0=1
        AND2_X1 and_gate2(s[1], d1[i], _d1[i]);     // d1 is selected when s1=1
        
        // OR gate to combine the AND gates outputs
        OR2_X1 or_gate(_d0[i], _d1[i], y[i]);
    end
endgenerate

// Always block only for the assertion to check if 'sel' is one-hot
// TODO: ask if this is the right way to do this
// always @(*) begin
//     // Count the number of '1's in 'sel'
//     static int one_count = 0;
//     for (int i = 0; i < WIDTH; i++) begin
//         one_count += s[i];
//     end

//     // Assert that exactly one of the bits in 'sel' is '1'
//     assert(one_count == 1) else $error("Select line is not one-hot.");
// end

endmodule