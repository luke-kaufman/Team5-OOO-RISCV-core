module matrix_ram_golden #(
    parameter int unsigned N_ROWS,
    parameter int unsigned N_COLS,
    localparam int unsigned ROW_ADDR_WIDTH = $clog2(N_ROWS),
    localparam int unsigned COL_ADDR_WIDTH = $clog2(N_COLS)
) (
    input logic clk,
    input logic rst_aL,
    input logic [ROW_ADDR_WIDTH-1:0] row_rd_addr,
    input logic [COL_ADDR_WIDTH-1:0] col_rd_addr,
    output logic [N_COLS-1:0] row_rd_data,
    output logic [N_ROWS-1:0] col_rd_data,
    input logic row_wr_en,
    input logic col_wr_en,
    input logic [ROW_ADDR_WIDTH-1:0] row_wr_addr,
    input logic [COL_ADDR_WIDTH-1:0] col_wr_addr,
    input logic [N_COLS-1:0] row_wr_data,
    input logic [N_ROWS-1:0] col_wr_data,

    // for testing
    input logic init,
    input logic [N_ROWS-1:0] [N_COLS-1:0] init_matrix_state,
    output logic [N_ROWS-1:0] [N_COLS-1:0] current_matrix_state
);
    logic [N_ROWS-1:0] [N_COLS-1:0] matrix;
    logic [N_ROWS-1:0] [N_COLS-1:0] matrix_next;

    assign row_rd_data = matrix[row_rd_addr];
    assign col_rd_data = matrix[col_rd_addr];

    always_comb begin
        matrix_next = matrix;
        if (row_wr_en) begin
            matrix_next[row_wr_addr] = row_wr_data;
        end
        if (col_wr_en) begin
            for (int i = 0; i < N_ROWS; i++) begin
                matrix_next[i][col_wr_addr] = col_wr_data[i];
            end
        end
    end

    always_ff @(posedge clk or posedge init or negedge rst_aL) begin
        if (!rst_aL) begin
            matrix = 0;
        end if (init) begin
            matrix = init_matrix_state;
        end else begin
            matrix = matrix_next;
        end
    end

    // assertions
    // row_wr_en and col_wr_en are never enabled at the same time TODO
    function assert_row_wr_col_wr_mut_exc;
    endfunction
endmodule