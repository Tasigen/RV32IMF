`timescale 1ns / 1ps

module tb_AddSubFPU_FSM;

reg clk;
reg rst;
reg start;
reg [31:0] N1, N2;
reg sel;
wire [31:0] result;
wire done;
wire busy;

// Instantiate the unit under test (UUT)
AddSubFPU_FSM uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .N1(N1),
    .N2(N2),
    .sel(sel),
    .result(result),
    .done(done),
    .busy(busy)
);

// Clock generation
initial clk = 0;
always #5 clk = ~clk; // 100 MHz clock

// Stimulus
initial begin
    $dumpfile("AddSubFPU_FSM.vcd");
    $dumpvars(0,tb_AddSubFPU_FSM);
    $display("Starting FSM FPU Test...");
    rst = 1;
    start = 0;
    N1 = 0;
    N2 = 0;
    sel = 0;

    #20 rst = 0;

    // Test 1: 3.5 + 1.5 = 5.0
    @(negedge clk);
    N1 = 32'h40600000; // 3.5
    N2 = 32'h3fc00000; // 1.5
    sel = 0;           // FADD
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);  // Allow result to settle
    $display("Test 1: 3.5 + 1.5 = %h (Expected: 40a00000)", result);

    // Test 2: 5.0 - 2.0 = 3.0
    @(negedge clk);
    N1 = 32'h40a00000; // 5.0
    N2 = 32'h40000000; // 2.0
    sel = 1;           // FSUB
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);  // Allow result to settle
    $display("Test 2: 5.0 - 2.0 = %h (Expected: 40400000)", result);

    // Test 3: 1.0 - 1.0 = 0.0
    @(negedge clk);
    N1 = 32'h3f800000; // 1.0
    N2 = 32'h3f800000; // 1.0
    sel = 1;           // FSUB
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);  // Allow result to settle
    $display("Test 3: 1.0 - 1.0 = %h (Expected: 00000000)", result);

    // Test 4: -2.5 + 2.5 = 0.0
    @(negedge clk);
    N1 = 32'hc0200000; // -2.5
    N2 = 32'h40200000; // 2.5
    sel = 0;           // FADD
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);  // Allow result to settle
    $display("Test 4: -2.5 + 2.5 = %h (Expected: 00000000)", result);

    // Test 5: 3.2 - 4.2 = -1.0
    @(negedge clk);
    N1 = 32'b0_10000000_10011001100110011001100;
    N2 = 32'b0_10000001_00001100110011001100110;
    sel = 1;
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);
    $display("Test 5: 3.2 - 4.2 = %h (Expected: bf800000)", result);

    // Test 6: 0.2 - 0.2 = 0.0
    @(negedge clk);
    N1 = 32'b0_01111011_10011001100110011001101;
    N2 = 32'b0_01111011_10011001100110011001101;
    sel = 1;
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);
    $display("Test 6: 0.2 - 0.2 = %h (Expected: 00000000)", result);

    // Test 7: -0.5 - (-6.4) = 5.9
    @(negedge clk);
    N1 = 32'b1_01111110_00000000000000000000000;
    N2 = 32'b1_10000001_10011001100110011001100;
    sel = 1;
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);
    $display("Test 7: -0.5 - (-6.4) = %h (Expected: 40bd70a4)", result);

    // Test 8: -0.5 - (+6.4) = -6.9
    @(negedge clk);
    N1 = 32'b1_01111110_00000000000000000000000;
    N2 = 32'b0_10000001_10011001100110011001100;
    sel = 1;
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);
    $display("Test 8: -0.5 - (+6.4) = %h (Expected: c0dd70a4)", result);

    // Test 9: 2.81 - (-0.94) = 3.75
    @(negedge clk);
    N1 = 32'h4034b4b5;
    N2 = 32'hbf70f0f1;
    sel = 1;
    start = 1;
    @(negedge clk);
    start = 0;

    wait (done == 1);
    @(negedge clk);
    $display("Test 9: 2.81 - (-0.94) = %h (Expected: 40700000)", result);

    // Finish
    #20;
    $finish;
end

endmodule
