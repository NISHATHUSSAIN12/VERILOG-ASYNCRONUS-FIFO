`timescale 1ns / 1ps

module ff_sync #(
    parameter size = 4
)(
    input clk, rest_n,
    input [size-1:0] din,
    output reg [size-1:0] q2
);
    
    reg [size-1:0] q1;

    always @(posedge clk) begin
        if (!rest_n) begin
            q1 <= 0;
            q2 <= 0;
        end
        else begin
            q2 <= q1;
            q1 <= din;
        end
    end

endmodule
