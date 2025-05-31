`timescale 1ns/1ps
`include "../src/AddSubFPU.v"

module AddSubFPU_tb;

    reg clk, rst, start, add_sub;
    reg [31:0] a, b;
    wire ready;
    wire [31:0] result;
    real expected, computed;

    AddSubFPU dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .add_sub(add_sub),
        .a(a),
        .b(b),
        .ready(ready),
        .result(result)
    );

    // Clock generator
    always #5 clk = ~clk;

    task apply_input(input [31:0] A, input [31:0] B, input integer mode, input real expected_val);
        begin
            a = A;
            b = B;
            add_sub = mode; // 0 = add, 1 = sub
            expected = expected_val;
            start = 1;

            @(posedge clk)
            start = 0;

            // Wait for ready signal
            wait (ready) @(posedge clk) begin
            if (ready) begin
            computed = (2.0**(result[30:23] - 127)) * 
                       ($itor({1'b1, result[22:0]}) / (2.0**23)) * 
                       ((result[31]) ? -1.0 : 1.0);
           
            $display("Op: %s | A = %h, B = %h | Expected = %f, Got = %f", 
                (mode ? "SUB" : "ADD"), A, B, expected, computed); 
            end
            else $display("Result not ready!");
            end            #1;

        end
    endtask

    initial begin
        $dumpfile("AddSubFPU.vcd");
        $dumpvars(0, AddSubFPU_tb);

        clk = 0;
        rst = 1;
        start = 0;
        #20;
        rst = 0;

        // Test cases (Add / Subtract)
        apply_input(32'h404CCCCD, 32'h40933333, 0, 3.2 + 4.6);  // 3.2 + 4.6 = 7.8
        apply_input(32'h404CCCCD, 32'h40933333, 1, 3.2 - 4.6);  // 3.2 - 4.6 = -1.4
        apply_input(32'h3F800000, 32'h40000000, 0, 1.0 + 2.0);  // 1.0 + 2.0 = 3.0
        apply_input(32'h3F800000, 32'h3F800000, 0, 1.0 + 1.0);  // 1.0 + 1.0 = 2.0
        apply_input(32'hC0800000, 32'h40800000, 0, -4.0 + 4.0); // -4 + 4 = 0.0
        apply_input(32'hC1200000, 32'hC0800000, 1, -10.0 - (-4.0)); // -10 - (-4) = -6

        #100;
        $finish;
    end
endmodule
