`timescale 1ns / 1ps

module pipeline_rv32i(
    input clk,
    input rst,
    output reg [31:0] writeback_data,//introduced for DC synthesis
    output reg [31:0] result//introduced for DC synthesis
    );

    wire flush;

    wire stall;
    //fetch stage
    wire [31:0] pc_F, instruction_F;

    //Decode stage
    wire [31:0] read_data1_D, read_data2_D, imm_out_D;
    wire [3:0] alu_control_D;
    wire mul_en_D, branch_D, mem_read_D, mem_to_reg_D, mem_write_D, alu_src_D, reg_write_o;
    wire [1:0] jump_D;
    wire reg_sel_D;
    wire fpu_op_D;


    //Execute stage
    wire [31:0] alu_result_E, branch_target_E, jump_target_E;
    wire branch_sel_E;
    wire [31:0] alu_result_E_DC, fpu_result_E, mdu_result_E;//introduced for DC synthesis


    //Memory stage
    wire [31:0] read_data_M;

    //Writeback stage
    wire [31:0] write_data_W;

    //pipeline registers
    
    //Fetch stage
    reg [31:0] pc_nxt_f;
    reg pc_sel_f;

    //Decode stage
    reg [31:0] instruction_D, pc_D, write_data_D;
    reg reg_write_D;
    reg FPR_GPR_sel;
    
    //Execute stage
    reg mul_en_E;
    reg fpu_op_E;
    reg [31:0] instruction_E, pc_E, rs1_E, rs2_E, imm_out_E;
    reg [3:0] alu_control_E;
    reg reg_sel_E, alu_src_E, mem_read_E, mem_to_reg_E, mem_write_E, branch_E, reg_write_E;
    reg [1:0] jump_E;

    //Memory stage
    reg [31:0] instruction_M, alu_result_M, rs2_M;
    reg mem_read_M, mem_to_reg_M, mem_write_M, reg_write_M;
    
    //Writeback stage
    reg [31:0] alu_result_W, read_data_W, instruction_W;
    reg mem_to_reg_W, reg_write_W;
    reg reg_sel_W;


    always @(*) begin
        pc_sel_f = (rst == 1'b0)? (branch_sel_E | (jump_E == 2'b01) | (jump_E == 2'b10)) : 1'b0;
        pc_nxt_f = (jump_E == 2'b01 || jump_E == 2'b10) ? jump_target_E : branch_target_E;
    end

    assign flush = (branch_sel_E || jump_E);
    
    //Fetch Stage Instantiation
    fetch fetch_inst(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_sel(pc_sel_f),
        .pc_nxt(pc_nxt_f),
        .pc_out(pc_F),
        .instruction(instruction_F)
    );

    //Decode Stage Instantiation
    decode decode_inst(
        .clk(clk),
        .rst(rst),
        .instruction(instruction_D),
        .read_reg1(instruction_D[19:15]), //rs1
        .read_reg2(instruction_D[24:20]), //rs2
        .write_reg(instruction_W[11:7]), //rd
        .write_data(write_data_W),
        .reg_write_i(reg_write_W),
        .FPR_GPR_sel(FPR_GPR_sel),
        .read_data1(read_data1_D),
        .read_data2(read_data2_D),
        .imm_out(imm_out_D),
        .alu_control(alu_control_D),
        .fpu_op(fpu_op_D),
        .reg_sel(reg_sel_D),
        .mul_en(mul_en_D),
        .branch(branch_D),
        .mem_read(mem_read_D),
        .mem_to_reg(mem_to_reg_D),
        .mem_write(mem_write_D),
        .alu_src(alu_src_D),
        .reg_write_o(reg_write_o),
        .jump(jump_D)
    );

    //Execute Stage Instantiation
    execute execute_inst (
        .mul_en(mul_en_E),
        .fpu_op(fpu_op_E),
        .rs1(rs1_E),
        .rs2(rs2_E),
        .alu_src(alu_src_E),
        .imm_out(imm_out_E),
        .alu_control(alu_control_E),
        .jump(jump_E),
        .pc(pc_E),
        .funct3(instruction_E[14:12]),
        .funct5(instruction_E[31:27]),
        .branch(branch_E),
        .result(alu_result_E),
        .branch_sel(branch_sel_E),
        .branch_target(branch_target_E),
        .jump_target(jump_target_E),
        .result_fpu(fpu_result_E),//introduced for synthesis
        .result_alu(alu_result_E_DC),//introduced for synthesis
        .result_mdu(mdu_result_E)//introduced for synthesis
    );

    //Memory Stage Instantiation
    memory memory_inst (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read_M),
        .mem_write(mem_write_M),
        .alu_result(alu_result_M),
        .write_data(rs2_M),
        .funct3(instruction_M[14:12]),
        .read_data(read_data_M)
    );

    //Writeback Stage Instantiation
    writeback writeback_inst(
        .alu_result(alu_result_W),
        .read_data(read_data_W),
        .mem_to_reg(mem_to_reg_W),
        .write_data(write_data_W)
    );

    //Hazard Detection module
    hazard_detection hazard_detection_inst(
        //.clk(clk),
        .rs1_D(instruction_D[19:15]),
        .rs2_D(instruction_D[24:20]),
        .rd_E(instruction_E[11:7]),
        .rd_M(instruction_M[11:7]),
        .rd_W(instruction_W[11:7]),
        .reg_write_E(reg_write_E),
        .reg_write_M(reg_write_M),
        .reg_write_W(reg_write_W),
        .stall(stall)
    );

    always @(posedge clk) begin
        if (rst) begin
            //reset all pipelined registers
            //pc_sel_f <= 1'b0;
            instruction_D <= 32'b0;
            pc_D <= 32'b0;
            write_data_D <= 32'b0;
            instruction_E <= 32'b0;
            pc_E <= 32'b0;
            rs1_E <= 32'b0;
            rs2_E <= 32'b0;
            imm_out_E <= 32'b0;
            alu_control_E <= 4'b0;
            alu_src_E <= 1'b0;
            mem_read_E <= 1'b0;
            mem_to_reg_E <= 1'b0;
            jump_E <= 2'b0;
            instruction_M <= 32'b0;
            alu_result_M <= 32'b0;
            rs2_M <= 32'b0;
            mem_read_M <= 1'b0;
            mem_to_reg_M <= 1'b0;
            alu_result_W <= 32'b0;
            read_data_W <= 32'b0;
            mem_to_reg_W <= 1'b0;
            writeback_data <= 32'b0;
        end else begin
            //Fetch to Decode
            instruction_D <= instruction_F;
            pc_D <= pc_F;
            
            //Decode to Execute
            fpu_op_E <= fpu_op_D;
            reg_sel_E <= reg_sel_D;
            mul_en_E = mul_en_D;
            rs1_E <= read_data1_D;
            rs2_E <= read_data2_D;
            imm_out_E <= imm_out_D;
            alu_control_E <= alu_control_D;
            alu_src_E <= alu_src_D;
            mem_read_E <= mem_read_D;
            mem_to_reg_E <= mem_to_reg_D;

            mem_write_E <= mem_write_D;
            branch_E <= branch_D;
            reg_write_E <= reg_write_o;

            //Execute to Memory
            instruction_M <= instruction_E;
            alu_result_M <= alu_result_E;
            rs2_M <= rs2_E;
            mem_read_M <= mem_read_E;
            mem_to_reg_M <= mem_to_reg_E;
            mem_write_M <= mem_write_E;
            reg_write_M <= reg_write_E;

            // Memory to Writeback
            instruction_W <= instruction_M;
            alu_result_W <= alu_result_M; 
            read_data_W <= read_data_M;
            mem_to_reg_W <= mem_to_reg_M;
            reg_write_W <= reg_write_M;
            reg_sel_W <= reg_sel_E;

            //other
            FPR_GPR_sel = reg_sel_W;
            write_data_D <= write_data_W;
            reg_write_D <= write_data_W;

            writeback_data<= write_data_W; //introduced for DC synthesis
            result <= alu_result_E; //introduced for DC synthesis
            //stalling logic
            if (stall) begin
                instruction_D <= instruction_D;
                pc_D <=pc_D;
                instruction_E <= 32'h00000013;  // addi x0, x0, 0 (NOP)
            end else begin
                instruction_E <= instruction_D;
                pc_E <= pc_D;
                jump_E <= jump_D;
            end
            if (flush) begin
                instruction_D <= 32'h00000013;  // addi x0, x0, 0 (NOP)
                instruction_E <= 32'h00000013;  // addi x0, x0, 0 (NOP)
            end else if (!stall) begin
                instruction_D <= instruction_F;
            end
        end
    end
endmodule