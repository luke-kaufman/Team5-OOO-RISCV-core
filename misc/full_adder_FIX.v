module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire s,
    output wire cout
);
    assign s = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule