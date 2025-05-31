`timescale 1ns / 1ps
module SqrtFPU (input [31:0]A,
                     output overflow,
                     output underflow,
                     output exception,
                     output [31:0] result);
wire [7:0] Exponent;
wire [22:0] Mantissa;
wire Sign;
wire [31:0] temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8,temp;
wire [31:0] x0,x1,x2,x3;
wire [31:0] sqrt_1by05,sqrt_2,sqrt_1by2;
wire [7:0] Exp_2,Exp_Adjust;
wire remainder;
wire pos;
assign x0 = 32'h3f5a827a;
assign sqrt_1by05 = 32'h3fb504f3;  // 1/sqrt(0.5)
assign sqrt_2 = 32'h3fb504f3;
assign sqrt_1by2 = 32'h3f3504f3;
assign Sign = A[31];
assign Exponent = A[30:23];
assign Mantissa = A[22:0];
/*----First Iteration----*/
DivFPU D1(.N1({1'b0,8'd126,Mantissa}),.N2(x0),.result(temp1));
AddSubFPU A1(.N1(temp1),.N2(x0), .sel(1'b0), .result(temp2));
assign x1 = {temp2[31],temp2[30:23]-1'b1,temp2[22:0]};

/*----Second Iteration----*/
DivFPU D2(.N1({1'b0,8'd126,Mantissa}),.N2(x1),.result(temp3));
AddSubFPU A2(.N1(temp3),.N2(x1), .sel(1'b0),.result(temp4));
assign x2 = {temp4[31],temp4[30:23]-1'b1,temp4[22:0]};
/*----Third Iteration----*/
DivFPU D3(.N1({1'b0,8'd126,Mantissa}),.N2(x2),.result(temp5));
AddSubFPU A3(.N1(temp5),.N2(x2), .sel(1'b0),.result(temp6));
assign x3 = {temp6[31],temp6[30:23]-1'b1,temp6[22:0]};
MulFPU M1(.N1(x3),.N2(sqrt_1by05),.result(temp7));

assign pos = (Exponent>=8'd127) ? 1'b1 : 1'b0;
assign Exp_2 = pos ? (Exponent-8'd127)/2 : (Exponent-8'd127-1)/2 ;
assign remainder = (Exponent-8'd127)%2;
assign temp = {temp7[31],Exp_2 + temp7[30:23],temp7[22:0]};
//assign temp7[30:23] = Exp_2 + temp7[30:23];
MulFPU M2(.N1(temp),.N2(sqrt_2),.result(temp8));
assign result = remainder ? temp8 : temp;
endmodule