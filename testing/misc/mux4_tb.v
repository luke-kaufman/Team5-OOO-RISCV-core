// TODO: change t
`timescale 1ns / 1ps

module mux3_tb;

// Testbench signals
reg [31:0] d0, d1, d2, d3;
reg [1:0] s;
wire [31:0] y;

// Instantiate the Unit Under Test (UUT)
mux4 #(32) uut (
    .d0(d0), 
    .d1(d1), 
    .d2(d2), 
    .d3(d3), 
    .s(s),
    .y(y)
);

initial begin
    // Initialize Inputs
    d0 = 0;
    d1 = 0;
    d2 = 0;
    d3 = 0;
    s = 0;

    // Wait 100 ns for global reset to finish
    #100;
    
    // Apply test vectors
    d0 = 32'h000000FF; d1 = 0; d2 = 0; d3 = 0; s[0] = 0; s[1] = 0; #10; // Select d0
    d0 = 0; d1 = 32'h0000FF00; d2 = 0; d3 = 0; s[0] = 1; s[1] = 0; #10; // Select d1
    d0 = 0; d1 = 0; d2 = 32'h00FF0000; d3 = 0; s[0] = 0; s[1] = 1; #10; // Select d2
    d0 = 0; d1 = 0; d2 = 0; d3 = 32'hFF000000; s[0] = 1; s[1] = 1; #10; // Select d3


    // Add more test vectors as needed
    
    // Finalize test
    #10;
    $display("Test completed.");
end

// Monitor changes
initial begin
    $monitor("At time %t, s[1]=%b s[0]=%b | d0=%b d1=%b d2=%b d3=%b => y=%b", $time, s[1], s[0], d0, d1, d2, d3, y);
end

endmodule
