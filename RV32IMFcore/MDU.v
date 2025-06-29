`timescale 1ns/1ps

`define MD_MUL 3'b000 //Case for Multiplication of signed integers and storing the lower bits result in the destination register.
`define MD_MULH 3'b001 //Case for Multiplication of signed integers and storing the higher bits in the destination register.
`define MD_MULHSU 3'b010 //Case for Multiplication between signed and unsigned integers, storing higher bits of result in the destination register.
`define MD_MULHU 3'b011 //Case for Multiplication of unsigned integers and storing at the higher bits in the destination register.

`define MD_DIV 3'b100 //Case for Division of signed integers.
`define MD_DIVU 3'b101 //Case for Division of unsigned integers. 
`define MD_REM 3'b110 //Case for Remainder of signed integers.
`define MD_REMU 3'b111 //Case for Remainder of unsigned integers.


module MDU(
input signed[31:0] rs1, // first operand of the MDU.
input signed[31:0] rs2, // second operand of the MDU.
input[2:0] function3, // function3 from the instruction used to select between different MDU operations.
output reg[31:0] mdu_result // MDU output for result.
);

reg signed [63:0] temp_mul;
always @(*) begin
	case(function3)
	`MD_MUL  : mdu_result = $signed(rs1) * $signed(rs2);// MUL dest_reg, rs1, rs2
	`MD_MULH : begin 
		temp_mul = $signed(rs1) * $signed(rs2);
		mdu_result = temp_mul[63:32];
	end                                               // MULH dest_reg, rs1, rs2
	`MD_MULHSU: begin
		temp_mul = $signed(rs1) * rs2;
		mdu_result =temp_mul[63:32];
		end 										// MULHSU dest_reg, rs1, rs2
	`MD_MULHU : begin
		temp_mul = rs1 * rs2;
		mdu_result = temp_mul[63:32];
		end											// MULHU dest_reg, rs1, rs2
	
	`MD_DIV  : mdu_result = $signed(rs1) / $signed(rs2);// DIV dest_reg, rs1, rs2
	`MD_DIVU : mdu_result = rs1 / rs2; // DIVU dest_reg, rs1, rs2
	`MD_REM  : mdu_result = $signed(rs1) % $signed(rs2);// REM dest_reg, rs1, rs2
	`MD_REMU : mdu_result = rs1 % rs2;// REMU dest_reg, rs1, rs2
	default: mdu_result = 32'b0;
	endcase
end
endmodule 