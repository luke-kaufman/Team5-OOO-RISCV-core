module test;
    wire [2:0] [1:0] mat = {2'b11, 2'b01, 2'b10};

    initial $display("%0b", mat & 6'b111111);
endmodule