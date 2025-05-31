module execute(
    input mul_en,
    input fpu_op,
    input [31:0] rs1,
    input [31:0] rs2,
    input alu_src,
    input [31:0] imm_out,
    input [3:0] alu_control,
    input [1:0] jump,
    input [31:0] pc,
    input [2:0] funct3,
    input [4:0] funct5,
    input branch,
    output [31:0] result,
    output branch_sel,
    output [31:0] branch_target,
    output [31:0] jump_target,
    output [31:0] result_fpu,//introduced for synthesis
    output [31:0] result_alu,//introduced for synthesis
    output [31:0] result_mdu//introduced for synthesis
);

    //ALU wires
    wire [31:0] alu_input2;
    assign alu_input2 = (alu_src)?imm_out:rs2;

    wire [31:0] fpu_result;
    wire [31:0] alu_result;
    wire [31:0] mdu_result;

    reg [31:0] final_result;

    ALU ALU_inst (
        .rs1(rs1),
        .src2(alu_input2),
        .alu_control(alu_control),
        .jump(jump),
        .pc(pc),
        .alu_result(alu_result)
    );

    MDU MDU_inst(
       .rs1(rs1),
       .rs2(rs2),
       .function3(funct3),
       .mdu_result(mdu_result)
    );

    FPU FPU_inst(
        .rs1(rs1),
        .rs2(rs2),
        .fpu_control(funct5),
        .fpu_sel(funct5[0]),
        .fpu_result(fpu_result)
    );

    branch_comp branch_comp_inst(
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .branch(branch),
        .branch_sel(branch_sel)
    );

    assign branch_target = pc+imm_out;
    assign jump_target = (jump == 2'b01)? (rs1 + alu_input2) & 32'hfffffffe:branch_target; // ?JALR = 01:JAL = 10  //so that for JALR instructions address is always multiple of 2 
    
    always @(*) begin
     
        if (mul_en)
            final_result = mdu_result;
        else if (fpu_op)
            final_result = fpu_result;
        else
            final_result = alu_result;

       //final_result = (mul_en)?mdu_result:alu_result;
    end

    assign result = final_result;
    assign result_alu = alu_result; // Introduced for DC synthesis
    assign result_mdu = mdu_result; // Introduced for DC synthesis
    assign result_fpu = fpu_result; // Introduced for DC synthesis
endmodule