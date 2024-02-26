module fulladder(
  input a, b, cin,
  output s, cout
);
    // S
    // wire aXORb;
    // XOR2_X1 axb(
    //     .A(a),
    //     .B(b),
    //     .Z(aXORb)
    // );
    // XOR2_X1 axbxC(
    //     .A(aXORb),
    //     .B(cin),
    //     .Z(s)
    // );

    // // Cout
    // wire aANDb, aXORbANDcin;
    // AND2_X1 aAb(
    //     .A1(a),
    //     .A2(b),
    //     .ZN(aANDb)
    // );
    // AND2_X1 aXbAcin(
    //     .A1(aXORb),
    //     .A2(cin),
    //     .ZN(aXORbANDcin)
    // );

    // OR2_X1 cout_orgate(
    //     .A1(aANDb),
    //     .A2(aXORbANDcin),
    //     .ZN(Cout)
    // );

  assign s = a ^ b ^ cin;
  assign cout = (a & b) | (b & cin) | (a & cin);

endmodule