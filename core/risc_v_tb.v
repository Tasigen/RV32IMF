`timescale 1ns / 1ps
`include "pipeline_rv32i.v"

module risc_v_tb;

    reg clk=0, rst;
    
    always begin
        clk = ~clk;
        #50;
    end

    initial begin
        $dumpfile("riscv.vcd");
        $dumpvars(0,risc_v_tb);
        rst <= 1'b1;
        #200;
        rst <= 1'b0;
        #9000;
        $finish;    
    end
    pipeline_rv32i dut (.clk(clk), .rst(rst));
endmodule
