`timescale 1ns / 1ps

module empty_checker #(
    parameter addr_size = 4
)(
    input rd_clk, rest_n, rd_enb,
    input [addr_size-1:0] syn_g_wr_ptr,
    output reg [addr_size-1:0] b_rd_ptr, g_rd_ptr,
    output reg empty
);

    wire [addr_size-1:0] g_rd_ptr_next, b_rd_ptr_next;

    assign b_rd_ptr_next = b_rd_ptr + (rd_enb && !empty);
    assign g_rd_ptr_next = (b_rd_ptr_next >> 1) ^ b_rd_ptr_next;
    
    always @(posedge rd_clk or negedge rest_n) begin
        if (!rest_n) begin
            b_rd_ptr <= 0;
            g_rd_ptr <= 0;
            empty <= 1;
        end
        else begin
            b_rd_ptr <= b_rd_ptr_next;
            g_rd_ptr <= g_rd_ptr_next;
            empty <= (g_rd_ptr_next == syn_g_wr_ptr);
        end
    end

endmodule
