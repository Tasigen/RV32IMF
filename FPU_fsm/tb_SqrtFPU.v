`timescale 1ns / 1ps

module tb_SqrtFPU;

reg clk;
reg [31:0] A;
wire [31:0] result;
wire overflow, underflow, exception;

// Instantiate the Unit Under Test (UUT)
SqrtFPU uut (
    .A(A),
    .overflow(overflow),
    .underflow(underflow),
    .exception(exception),
    .result(result)
);

// Clock generation (unused by UUT, but for waveform timing)
initial clk = 0;
always #5 clk = ~clk; // 100 MHz clock

initial begin
    $dumpfile("SqrtFPU.vcd");
    $dumpvars(0, tb_SqrtFPU);
    $display("Starting SqrtFPU Test...");

    // Test 1: sqrt(4.0) = 2.0
    @(negedge clk);
    A = 32'h40800000; // 4.0
    @(negedge clk);
    $display("Test 1: sqrt(4.0) = %h (Expected: 40000000)", result);

    // Test 2: sqrt(2.0) ≈ 1.4142135
    @(negedge clk);
    A = 32'h40000000; // 2.0
    @(negedge clk);
    $display("Test 2: sqrt(2.0) = %h (Expected: 3FB504F3)", result);

    // Test 3: sqrt(0.25) = 0.5
    @(negedge clk);
    A = 32'h3E800000; // 0.25
    @(negedge clk);
    $display("Test 3: sqrt(0.25) = %h (Expected: 3F000000)", result);

    // Test 4: sqrt(9.0) = 3.0
    @(negedge clk);
    A = 32'h41100000; // 9.0
    @(negedge clk);
    $display("Test 4: sqrt(9.0) = %h (Expected: 40400000)", result);

    // Test 5: sqrt(1.0) = 1.0
    @(negedge clk);
    A = 32'h3F800000; // 1.0
    @(negedge clk);
    $display("Test 5: sqrt(1.0) = %h (Expected: 3F800000)", result);

    // Test 6: sqrt(0.0) = 0.0
    @(negedge clk);
    A = 32'h00000000; // 0.0
    @(negedge clk);
    $display("Test 6: sqrt(0.0) = %h (Expected: 00000000)", result);

    #20;
    $finish;
end

endmodule
