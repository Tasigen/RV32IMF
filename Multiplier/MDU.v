`timescale 1ns/1ps

`define MD_MUL 3'b000
`define MD_MULH 3'b001
`define MD_MULHSU 3'b010
`define MD_MULHU 3'b011

`define MD_DIV 3'b100
`define MD_DIVU 3'b101
`define MD_REM 3'b110
`define MD_REMU 3'b111


module MDU(
input[31:0] rs1,
input[31:0] src2,
input[2:0] mdu_control,
output reg[31:0] mdu_result
);

always @(*) begin
	case(mdu_control)
	`MD_MUL  : mdu_result = $signed(rs1) * $signed(src2);
	`MD_MULH : mdu_result = $signed(rs1) * $signed(src2) >> 32;
	`MD_MULHSU: mdu_result = $signed(rs1) * src2 >> 32;
	`MD_MULHU : mdu_result = rs1 * src2 >> 32;
	
	`MD_DIV  : mdu_result = $signed(rs1) / $signed(src2);
	`MD_DIVU : mdu_result = rs1 / src2;
	`MD_REM  : mdu_result = $signed(rs1) % $signed(src2);
	`MD_REMU : mdu_result = rs1 % src2;
	default: mdu_result = 32'b0;
	endcase
end
endmodule 