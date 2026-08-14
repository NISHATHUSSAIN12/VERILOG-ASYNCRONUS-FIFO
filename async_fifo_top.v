`timescale 1ns / 1ps

module async_fifo_top #(
    parameter DATA_SIZE = 8,
    parameter ADDR_SIZE = 3
)(
    input wr_clk,
    input rd_clk,
    input rest_n,
    input wr_enb,
    input rd_enb,
    input [DATA_SIZE-1:0] wr_data,
    output [DATA_SIZE-1:0] rd_data,
    output full,
    output empty
);

    // Internal pointers
    wire [ADDR_SIZE:0] b_wr_ptr;
    wire [ADDR_SIZE:0] b_rd_ptr;
    wire [ADDR_SIZE:0] g_wr_ptr;
    wire [ADDR_SIZE:0] g_rd_ptr;
    
    // Synchronized pointers
    wire [ADDR_SIZE:0] syn_g_wr_ptr;
    wire [ADDR_SIZE:0] syn_g_rd_ptr;

    // ========== FIFO Memory ==========
    FIFO_memory #(
        .DATA_SIZE(DATA_SIZE),
        .ADDR_SIZE(ADDR_SIZE)
    ) fifo_mem (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rest_n(rest_n),
        .wr_enb(wr_enb),
        .rd_enb(rd_enb),
        .full(full),
        .empty(empty),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );
    
    // ========== Synchronize write pointer to read clock domain ==========
    ff_sync #(
        .size(ADDR_SIZE+1)
    ) sync_wr (
        .clk(rd_clk),
        .rest_n(rest_n),
        .din(g_wr_ptr),
        .q2(syn_g_wr_ptr)
    );
    
    // ========== Synchronize read pointer to write clock domain ==========
    ff_sync #(
        .size(ADDR_SIZE+1)
    ) sync_rd (
        .clk(wr_clk),
        .rest_n(rest_n),
        .din(g_rd_ptr),
        .q2(syn_g_rd_ptr)
    );
    
    // ========== Empty Flag Checker ==========
    empty_checker #(
        .addr_size(ADDR_SIZE+1)
    ) status (
        .rd_clk(rd_clk),
        .rest_n(rest_n),
        .rd_enb(rd_enb),
        .syn_g_wr_ptr(syn_g_wr_ptr),
        .b_rd_ptr(b_rd_ptr),
        .g_rd_ptr(g_rd_ptr),
        .empty(empty)
    );
    
    // ========== Full Flag Checker ==========
    full_checker #(
        .addr_size(ADDR_SIZE+1)
    ) status1 (
        .wr_clk(wr_clk),
        .rest_n(rest_n),
        .wr_enb(wr_enb),
        .syn_g_rd_ptr(syn_g_rd_ptr),
        .b_wr_ptr(b_wr_ptr),
        .g_wr_ptr(g_wr_ptr),
        .full(full)
    );

endmodule
