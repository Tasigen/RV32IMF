`timescale 1ns/1ps
`include "../src/MulFPU.v"

module MulFPU_tb;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg [31:0] A, B;
    wire [31:0] result;
    wire ready;
    real expected, value;

    // Instantiate DUT
    MulFPU dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(A),
        .b(B),
        .ready(ready),
        .result(result)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Convert result to real value
    task display_result(input real expected_val);
        begin
            value = (2.0**(result[30:23] - 127)) *
                    ($itor({1'b1, result[22:0]}) / (2**23)) *
                    ((result[31]) ? -1.0 : 1.0);
            $display("Expected: %f, Got: %f", expected_val, value);
        end
    endtask

    // Apply inputs and test pipeline
    task apply_test(input [31:0] in1, input [31:0] in2, input real expected_val);
        begin
            @(posedge clk);
            A = in1;
            B = in2;
            start = 1;
            @(posedge clk);
            start = 0;

            // Wait for 4 cycles (the pipeline depth)
            repeat (5) @(posedge clk) begin
            if (ready) display_result(expected_val);
            else $display("Result not ready!");
            end
        end
    endtask

    initial begin
        $dumpfile("MulFPU.vcd");
        $dumpvars(0, MulFPU_tb);

        // Reset
        @(posedge clk);
        rst = 0;

        // Test cases
        apply_test(32'b0_10000000_10011001100110011001100, 32'b0_10000001_00001100110011001100110, 3.2 * 4.2);
        apply_test(32'b0_01111011_10011001100110011001101, 32'b0_01111011_10011001100110011001101, 0.1 * 0.1);
        apply_test(32'b1_01111110_00000000000000000000000, 32'b1_10000001_10011001100110011001100, -0.5 * -6.4);
        apply_test(32'b1_01111110_00000000000000000000000, 32'b0_10000001_10011001100110011001100, -0.5 * 6.4);
        apply_test(32'h4034b4b5, 32'hbf70f0f1, 2.82 * -0.94);
        apply_test(32'b01000000000000000000000000000000, 32'b01000000010000000000000000000000, 2 * 3);

        $finish;
    end

endmodule