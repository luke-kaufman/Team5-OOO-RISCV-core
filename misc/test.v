module test;
    wire o;
    INV_X1 inv1 (
        .A(1'b0),
        .ZN(inv2.A)
    );
    INV_X1 inv2 (
        .A(inv1.ZN),
        .ZN(o)
    );

    initial begin
        #10;
        $display("o = %b", o);
    end
endmodule