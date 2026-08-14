`timescale 1ns / 1ps

module FIFO_memory #(
    parameter DATA_SIZE = 8,
    parameter ADDR_SIZE = 3
)(
    input wr_clk, rd_clk, rest_n, wr_enb, rd_enb, full, empty,
    input [DATA_SIZE - 1 : 0] wr_data,
    output reg [DATA_SIZE - 1 : 0] rd_data,
    output reg [ADDR_SIZE-1:0] b_rd_addr, b_wr_addr
);
    
    // Depth calculation
    localparam DEPTH = 1 << ADDR_SIZE;
    
    // Memory declaration
    reg [DATA_SIZE-1:0] mem[0:DEPTH-1];
    
    // Write logic
    always @(posedge wr_clk) begin
        if (!rest_n)
            b_wr_addr <= 0;
        else if (wr_enb && !full) begin
            mem[b_wr_addr] <= wr_data;
            b_wr_addr <= b_wr_addr + 1'b1;
        end
    end
    
    // Read logic
    always @(posedge rd_clk) begin
        if (!rest_n)
            b_rd_addr <= 0;
        else if (rd_enb && !empty) begin
            rd_data <= mem[b_rd_addr];
            b_rd_addr <= b_rd_addr + 1'b1;
        end
    end
    
endmodule
