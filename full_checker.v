`timescale 1ns / 1ps

module full_checker #(
    parameter addr_size = 4
)(
    input wr_clk, rest_n, wr_enb,
    input [addr_size-1:0] syn_g_rd_ptr,
    output reg [addr_size-1:0] b_wr_ptr, g_wr_ptr,
    output reg full
);

    wire [addr_size-1:0] g_wr_ptr_next, b_wr_ptr_next;

    assign b_wr_ptr_next = b_wr_ptr + (wr_enb && !full);
    assign g_wr_ptr_next = (b_wr_ptr_next >> 1) ^ b_wr_ptr_next;
    
    always @(posedge wr_clk or negedge rest_n) begin
        if (!rest_n) begin
            b_wr_ptr <= 0;
            g_wr_ptr <= 0;
            full <= 0;
        end
        else begin
            b_wr_ptr <= b_wr_ptr_next;
            g_wr_ptr <= g_wr_ptr_next;
            full <= (g_wr_ptr_next == {~syn_g_rd_ptr[addr_size-1:addr_size-2],
                                       syn_g_rd_ptr[addr_size-3:0]});
        end
    end

endmodule
