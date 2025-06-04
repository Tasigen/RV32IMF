`timescale 1ns / 1ps
`include "../AddSubFPU_FSM.v"
`include "../DivFPU_Flowchart.v"
`include "../MulFPU_FSM.v"
module tb_FPU_Top;

    reg clk, rst, start;
    reg [2:0] fpu_op;
    reg [31:0] N1, N2;
    wire [31:0] result;
    wire done, busy;

    FPU_Top uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .fpu_op(fpu_op),
        .N1(N1),
        .N2(N2),
        .result(result),
        .done(done),
        .busy(busy)
    );

    // Clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    // Tasks for each test
    task run_test(input [2:0] op, input [31:0] a, input [31:0] b);
        begin
            @(negedge clk);
            fpu_op <= op;
            N1 <= a;
            N2 <= b;
            start <= 1;
            @(negedge clk);
            start <= 0;
            wait (done);
            $display("OP: %b | N1: %h, N2: %h => Result: %h", op, a, b, result);
            #10;
        end
    endtask

    initial begin
        $dumpfile("FPU_Top.vcd");
        $dumpvars(0, tb_FPU_Top);
        // Reset
        rst = 1; start = 0;
        #20 rst = 0;

        // Add: 6.0 + 2.0 = 8.0
        run_test(3'b000, 32'h40C00000, 32'h40000000); // 6.0 + 2.0

        // Sub: 6.0 - 2.0 = 4.0
        run_test(3'b001, 32'h40C00000, 32'h40000000); // 6.0 - 2.0
        //fpu_op[0] = 1; // change to subtraction inside addsub

        // Mul: 3.0 * -2.0 = -6.0
        run_test(3'b001, 32'h40400000, 32'hC0000000); // 3.0 * -2.0

        // Div: 9.0 / 3.0 = 3.0
        run_test(3'b010, 32'h41100000, 32'h40400000); // 9.0 / 3.0

        // fneg.s: -3.0
        run_test(3'b011, 32'h40400000, 32'h00000000); // fneg.s

        // f.mv.s: just copy N1
        run_test(3'b100, 32'h3FC00000, 32'h00000000); // f.mv.s

        // Add: 1.5 + 2.25 = 3.75
        run_test(3'b000, 32'h3FC00000, 32'h40200000); // 1.5 + 2.25

        // Mul: 1.5 * 2.0 = 3.0
        run_test(3'b001, 32'h3FC00000, 32'h40000000);

        $display("All tests completed.");
        $finish;
    end

endmodule
