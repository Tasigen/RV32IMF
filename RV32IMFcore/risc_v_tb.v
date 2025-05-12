`timescale 1ns / 1ps

`include "../ALU.v"
`include "../ALU_decoder.v"
`include "../Instruction_memory.v"
`include "../PC.v"
`include "../branch_comp.v"

`include "../data_memory.v"
`include "../decode.v"
`include "../execute.v"
`include "../fetch.v"
`include "../hazard_detection.v"

`include "../imm_gen.v"
`include "../memory.v"
`include "../opcode_decoder.v"
`include "../register.v"
`include "../writeback.v"

`include "../MDU.v"
`include "../registerFPU.v"
`include "../FPU.v"

`include "../pipeline_rv32i.v"

module risc_v_tb;

    reg clk=0, rst=0;
    
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
