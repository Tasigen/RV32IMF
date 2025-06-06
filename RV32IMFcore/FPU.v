`timescale 1ns / 1ps


`define FPU_ADDSUB   5'b00000, 5'b00001
`define FPU_MUL      5'b00010
`define FPU_DIV      5'b00011
`define FPU_SQRT     5'b01011

module FPU(
    input [31:0] rs1,
    input [31:0] rs2,
    input [4:0] fpu_control,
    input fpu_sel,
    output reg [31:0] fpu_result
    );

    // temporary results for fpu operations
    wire [31:0] AddSubResult;
    wire [31:0] MulResult;
    wire [31:0] DivResult;
    wire [31:0] SqrtResult;

    //module instantiation
    AddSubFPU ASFPU_inst (.N1(rs1), .N2(rs2), .sel(fpu_sel), .result(AddSubResult));
    MulFPU MulFPUinst(.N1(rs1),.N2(rs2),.result(MulResult));
    DivFPU_Flowchart DivFPUinst(.N1(rs1), .N2(rs2), .result(DivResult));
    //SqrtFPU SqrtFPUinst(.A(rs1), .result(SqrtResult));

    always @(*) begin
        case(fpu_control) 
            `FPU_ADDSUB: fpu_result = AddSubResult;
            `FPU_MUL: fpu_result = MulResult;
            `FPU_DIV: fpu_result = DivResult;
            `FPU_SQRT: fpu_result = SqrtResult;
            default:    
                fpu_result = 32'b0;
    endcase
    end

endmodule