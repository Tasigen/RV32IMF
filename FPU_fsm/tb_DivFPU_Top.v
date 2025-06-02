
`timescale 1ns / 1ps
`include "../DivFPU_FSM.v"
`include "../MulFPU_FSM.v"
`include "../AddSubFPU_FSM.v"

module tb_DivFPU_Top;

reg clk;
reg rst;
reg start;
reg [31:0] N, D;
wire [31:0] result;
wire done;
wire busy;

DivFPU_Top uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .N(N),
    .D(D),
    .result(result),
    .done(done),
    .busy(busy)
);

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

initial begin
    $display("Starting DivFPU_Top Test...");
    rst = 1;
    start = 0;
    N = 0;
    D = 0;

    #20 rst = 0;

    // Test 1: 6.0 / 2.0 = 3.0
    @(negedge clk);
    N = 32'h40C00000; // 6.0
    D = 32'h40000000; // 2.0
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done);
    @(negedge clk);
    $display("Test 1: 6.0 / 2.0 = %h (Expected: 40400000)", result);

    // Test 2: -9.0 / 3.0 = -3.0
    @(negedge clk);
    N = 32'hC1100000; // -9.0
    D = 32'h40400000; // 3.0
    start = 1;
    #20;
    @(negedge clk);
    start = 0;

    wait (done);
    @(negedge clk);
    $display("Test 2: -9.0 / 3.0 = %h (Expected: C0400000)", result);

    // Test 3: 1.0 / 3.0 ≈ 0.333...
    @(negedge clk);
    N = 32'h3F800000; // 1.0
    D = 32'h40400000; // 3.0
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done);
    @(negedge clk);
    $display("Test 3: 1.0 / 3.0 = %h (Expected approx: 3EAAAAAB)", result);

    #20;
    $finish;
end

endmodule
