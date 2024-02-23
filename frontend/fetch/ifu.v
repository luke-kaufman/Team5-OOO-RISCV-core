module ifu (
    output wire [:] inst_o;
    
);
    tag_array tag_array (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .tag_o(tag_o)
    );
endmodule

module tag_array (
    input wire clk,
    input wire rst,
    
)