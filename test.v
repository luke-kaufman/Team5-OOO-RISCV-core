module test #(
    parameter N = 4
);
    typedef struct packed {
        logic [43:0] x;
        logic [30:0] y;
        logic [37:0] z;
    } my_struct;
    my_struct my_array [1:10];

    // reg [7:0] a = 8'b00_01_10_11;
    logic [2:0] a = 3'b000;
    logic [2:0] b = 3'b100;

    initial begin
        // for (int i = 1; i <= 10; i = i + 1) begin
        //     for (int j = 0; j < $bits(my_struct); j += 32) begin
        //         my_array[i][j+:32] = $urandom();
        //     end
        // end

        // for (int i = 1; i <= 10; i = i + 1) begin
        //     $display("x: %b, y: %b, z: %b", my_array[i].x, my_array[i].y, my_array[i].z);
        // end

        // a[7+:2] = 2'b11;
        // $display("a: %b", a[7]);

        $display(1'b1 || 1'bx);
    end
endmodule