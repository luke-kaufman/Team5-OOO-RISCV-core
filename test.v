typedef struct packed {
        logic b;
} my_type;

module test;
    // struct packed {
    //     logic a;
    // } val1;
    wire my_type val2;
    initial begin
        // val1.a = 1'b0;
        val2.b = 1'b0;
    end
    // assign val2.b = 1'b0;
    // assign val1.a = 1'b0;
endmodule