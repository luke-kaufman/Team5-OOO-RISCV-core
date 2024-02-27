module counter_tb;
    reg clk;
    reg rst_aL;
    reg en;
    wire [3:0] count;
    
    // Instantiate the Unit Under Test (UUT)
    counter uut (
        .clk(clk), 
        .rst_aL(rst_aL), 
        .en(en), 
        .count(count)
    );

    initial begin
        // Initialize all stimuli and put the UUT in reset
        clk = 0;
        en = 0;
        rst_aL = 0;
        // Wait for 10 clock cycles
        #10;
        // Release reset
        rst_aL = 1;
        // Wait for 10 clock cycles
        #10;
        // Enable the counter
        en = 1;
        // Wait for 1 clock cycle
        #1;
        // Check if the counter is at 1
        if (count != 1) $display("Counter is not at 1");
        // Wait for 1 clock cycle
        #1;
        // Check if the counter is at 2
        if (count != 2) $display("Counter is not at 2");
        // Wait for 1 clock cycle
        #1;
        // Check if the counter is at 3
        if (count != 3) $display("Counter is not at 3");
        // Disable the counter
        en = 0;
        // Wait for 1 clock cycle
        #1;
        // Check if the counter is at 3
        if (count != 3) $display("Counter is not at 3");
        end

        initial begin
            $monitor("count = %0d", count);
            // Toggle the clock every 5ns
            forever #5 clk = ~clk;
        end
endmodule