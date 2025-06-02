
`timescale 1ns / 1ps

module tb_MulFPU_FSM;

reg clk;
reg rst;
reg start;
reg [31:0] N1, N2;
wire [31:0] result;
wire done, busy;

MulFPU_FSM uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .N1(N1),
    .N2(N2),
    .result(result),
    .done(done),
    .busy(busy)
);

initial clk = 0;
always #5 clk = ~clk;

initial begin
    $display("Starting FSM FPU Multiply Test...");
    rst = 1;
    start = 0;
    N1 = 0;
    N2 = 0;

    #20 rst = 0;

    // Test 1: 3.0 * 2.0 = 6.0
    @(negedge clk);
    N1 = 32'h40400000; // 3.0
    N2 = 32'h40000000; // 2.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait (done == 1);
    @(negedge clk);
    $display("Test 1: 3.0 * 2.0 = %h (Expected: 40c00000)", result);

    // Test 2: -1.5 * 4.0 = -6.0
    @(negedge clk);
    N1 = 32'hbfc00000; // -1.5
    N2 = 32'h40800000; // 4.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait (done == 1);
    @(negedge clk);
    $display("Test 2: -1.5 * 4.0 = %h (Expected: c0c00000)", result);

    // Test 3: 0.0 * 5.0 = 0.0
    @(negedge clk);
    N1 = 32'h00000000;
    N2 = 32'h40a00000; // 5.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait (done == 1);
    @(negedge clk);
    $display("Test 3: 0.0 * 5.0 = %h (Expected: 00000000)", result);

    // Test 4: -2.5 * -2.5 = 6.25
    @(negedge clk);
    N1 = 32'hc0200000; // -2.5
    N2 = 32'hc0200000; // -2.5
    start = 1;
    @(negedge clk);
    start = 0;
    wait (done == 1);
    @(negedge clk);
    $display("Test 4: -2.5 * -2.5 = %h (Expected: 40c80000)", result);

    // Test 5: Exponent Overflow
    @(negedge clk);
    N1 = 32'h7f7fffff; // ~3.4e+38 (max finite float)
    N2 = 32'h501502f9; // ~1e+10
    start = 1;
    @(negedge clk);
    start = 0;
    
    wait (done == 1);
    @(negedge clk);
    $display("Test 5: Exponent Overflow = %h (Expected: 7f800000 or 7fffffff)", result);
    #20;
    $finish;
end

endmodule
