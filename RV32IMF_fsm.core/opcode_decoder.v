`timescale 1ns / 1ps

module opcode_decoder(
    input [31:0] instruction,
    output wire fpu_op, fpu_en, mul_en, branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write,
    output wire [1:0] jump,
    output wire [1:0] alu_op
);

    reg [12:0] controls;

    // Format of controls: {branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write, jump[1], jump[0], alu_op[1], alu_op[0]}
    reg [6:0] opcode;
    reg [6:0] function7;

    always @(*) begin
        opcode = instruction[6:0];
        function7 = instruction[31:25];
        case(opcode)
            7'b0110011: controls = (function7 == 7'b0000001)? 13'b0_0_1_0_0_0_0_0_1_00_00:13'b0_0_0_0_0_0_0_0_1_00_10; // R-type - mdu : alu
            7'b1010011: controls = 13'b1_1_0_0_0_0_0_0_1_00_XX; //R-type - fpu
            7'b0010011: controls = 13'b0_0_0_0_0_0_0_1_1_00_10; // I-type ALU
            7'b0000011: controls = 13'b0_0_0_0_1_1_0_1_1_00_00; // I-type Load
            7'b0000111: controls = 13'b0_1_0_0_1_1_0_1_1_00_00; // I-type FPU load
            7'b0100011: controls = 13'b0_0_0_0_0_0_1_1_0_00_00; // S-type
            7'b0100111: controls = 13'b0_1_0_0_0_0_1_1_0_00_00; // S-type FPU
            7'b1100011: controls = 13'b0_0_0_1_0_0_0_0_0_00_01; // B-type
            7'b1101111: controls = 13'b0_0_0_0_0_0_0_0_1_10_00; // J-type (JAL)
            7'b1100111: controls = 13'b0_0_0_0_0_0_0_1_1_01_00; // I-type (JALR)
            7'b0110111: controls = 13'b0_0_0_0_0_0_0_1_1_00_11; // U-type (LUI)
            7'b0010111: controls = 13'b0_0_0_0_0_0_0_1_1_00_11; // U-type (AUIPC)
            default:    controls = 13'b0_0_0_0_0_0_0_0_0_00_00;
        endcase
    end

    assign fpu_op = controls[12];
    assign fpu_en = controls[11];
    assign mul_en = controls[10];
    assign branch = controls[9];
    assign mem_read = controls[8];
    assign mem_to_reg = controls[7];
    assign mem_write = controls[6]; // for S-Type Instruction
    assign alu_src = controls[5]; // alu_src = 1 means imm is needed
    assign reg_write = controls[4];
    assign jump = controls[3:2];
    assign alu_op = controls[1:0];


endmodule
