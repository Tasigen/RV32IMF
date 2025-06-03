`timescale 1ns / 1ps

module tb_DivFPU_FSM;

reg clk;
reg rst;
reg start;
reg [31:0] N1, N2;
wire [31:0] result;
wire done;
wire busy;

// Instantiate the Unit Under Test (UUT)
DivFPU_FSM uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .N1(N1),
    .N2(N2),
    .result(result),
    .done(done),
    .busy(busy)
);

// Clock generation
initial clk = 0;
always #5 clk = ~clk; // 100 MHz clock

// Stimulus
initial begin
    $dumpfile("DivFPU_FSM.vcd");
    $dumpvars(0, tb_DivFPU_FSM);
    $display("Starting FSM DivFPU Test...");
    rst = 1;
    start = 0;
    N1 = 0;
    N2 = 0;

    #20 rst = 0;

    // Test 1: 6.0 / 2.0 = 3.0
    @(negedge clk);
    N1 = 32'h40C00000; // 6.0
    N2 = 32'h40000000; // 2.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait(done);
    @(negedge clk);
    $display("Test 1: 6.0 / 2.0 = %h (Expected: 40400000)", result);

    // Test 2: -9.0 / 3.0 = -3.0
    @(negedge clk);
    N1 = 32'hC1100000; // -9.0
    N2 = 32'h40400000; // 3.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait(done);
    @(negedge clk);
    $display("Test 2: -9.0 / 3.0 = %h (Expected: C0400000)", result);

    // Test 3: 1.0 / 3.0 ≈ 0.333 (approx 3EAAAAAB)
    @(negedge clk);
    N1 = 32'h3F800000; // 1.0
    N2 = 32'h40400000; // 3.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait(done);
    @(negedge clk);
    $display("Test 3: 1.0 / 3.0 = %h (Expected approx: 3EAAAAAB)", result);

    // Test 4: -8.4 / -2.0 = 4.2
    @(negedge clk);
    N1 = 32'hC0A66666; // -8.4
    N2 = 32'hC0000000; // -2.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait(done);
    @(negedge clk);
    $display("Test 4: -8.4 / -2.0 = %h (Expected: 40866666)", result);

    // Test 5: 10.0 / 4.0 = 2.5
    @(negedge clk);
    N1 = 32'h41200000; // 10.0
    N2 = 32'h40800000; // 4.0
    start = 1;
    @(negedge clk);
    start = 0;
    wait(done);
    @(negedge clk);
    $display("Test 5: 10.0 / 4.0 = %h (Expected: 40200000)", result);

    #20;
    $finish;
end

endmodule
