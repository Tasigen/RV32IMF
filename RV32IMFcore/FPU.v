`timescale 1ns / 1ps



`define FPU_ADDSUB   3'b000, 3'b001
`define FPU_MUL      3'b010
`define FPU_DIV      3'b011
`define SIGN_INJECTION  3'b100

module FPU(
    input [31:0] rs1,
    input [31:0] rs2,
    input [2:0] fpu_control,
    input [2:0] funct3,
    input fpu_sel,
    output reg [31:0] fpu_result
    );

    // temporary results for fpu operations
    wire [31:0] AddSubResult;
    wire [31:0] MulResult;
    wire [31:0] DivResult;
    wire [31:0] SqrtResult;
    wire sign_temp;

    assign sign_temp = rs1[31] ^ rs2[31];

    //module instantiation
    AddSubFPU ASFPU_inst (.N1(rs1), .N2(rs2), .sel(fpu_sel), .result(AddSubResult));
    MulFPU MulFPUinst(.N1(rs1),.N2(rs2),.result(MulResult));
    DivFPU_Flowchart DivFPUinst(.N1(rs1), .N2(rs2), .result(DivResult));

    always @(*) begin
        case(fpu_control) 
            `FPU_ADDSUB: fpu_result = AddSubResult;
            `FPU_MUL: fpu_result = MulResult;
            `FPU_DIV: fpu_result = DivResult;
            `SIGN_INJECTION: begin
                case(funct3)
                    3'b000:fpu_result = {rs2[31],rs1[30:0]} ;
                    3'b010:fpu_result = {sign_temp,rs1[30:0]};
                endcase
            end
            default:    
                fpu_result = 32'b0;
    endcase
    end

endmodule