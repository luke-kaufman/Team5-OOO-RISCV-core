`define x (3 + 4)

module test #(
    parameter N = 4
);
    // typedef struct packed {
    //     logic [43:0] x;
    //     logic [30:0] y;
    //     logic [37:0] z;
    // } my_struct;
    // my_struct my_array [1:10];

    // reg [7:0] a = 8'b00_01_10_11;
    // logic [2:0] a = 3'b000;
    // logic [2:0] b = 3'b100;

    // wire [1:0] sel = 2'b01;
    // wire [3:0] [1:0] ins = {2'b11, 2'b10, 2'b01, 2'b00};

    // logic [74:0] a;
    // logic [17:0] b;

    // function automatic void randomize(output t_t data);
    //     for (int i = 0; i < $bits(data); i += 32) begin
    //         data[i+:32] = $urandom();
    //     end
    // endfunction
    // wire [1:0] deq = 2'b10;
    // wire [1:0] enq = 2'b10;
    // logic [3:0] y = 4'b1010;

    // int x = 0;
    // bit clk = 1;
    // initial forever #5 clk = ~clk;
    // bit rstn = 1;

    wire  [4:0] x = 5'b11111;


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


        // repeat (10)
        //     $display("%b", 1 << $urandom_range(0, -1));

        // randomize(a);
        // randomize(b);

        // $display("a: %b", a);
        // $display("b: %b", b);
        // int y = 5;
        // bit [4:0] x = 0;

        // repeat (10) begin
        //     // if ($urandom_range(0,1))
        //     //     $display("yes");
        //     // else
        //     //     $display("no");
        //     x = y;
        //     y++;
            // $display("x: %b, y: %d", x, y);
        // while (1) begin : hello
        //     for (int i = 0; i < 5; i++) begin
        //         $display("world");
        //         disable hello;
        //     end
        // end
        // repeat (10)
        // y = 0;
        //     $display("%b", `x);
        $display("%b", x[3-:2]);

    end

    // always @(posedge clk or negedge rstn) begin
    //     $display("%t x: %d", $time, x);
    //     repeat (5) @(negedge clk);
    //     x += 1;
    //     if (x == 10) $finish;
    // end
endmodule
