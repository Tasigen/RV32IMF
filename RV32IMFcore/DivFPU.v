module DivFPU (
    input [31:0] N1,
    input [31:0] N2,
    output [31:0]result
);

wire [7:0] Exponent;
wire [31:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, result_unprotected;
wire [31:0] reciprocal;
wire [31:0] x0,x1,x2,x3;

// zero division flag
assign zero_division = (N2[30:23] == 0) ? 1'b1 : 1'b0;

/*----Initial value----       B_Mantissa * (2 ^ -1)            32 / 17 */
MulFPU M1(.N1({{1'b0,8'd126,N2[22:0]}}), .N2(32'h3ff0f0f1), .result(temp1)); //verified
//                         48 / 17        -abs(temp1)
AddSubFPU A1(.N1(32'h4034b4b5), .N2({1'b1,temp1[30:0]}), .sel(1'b0), .result(x0));

/*----First Iteration----*/
MulFPU M2(.N1({{1'b0,8'd126,N2[22:0]}}), .N2(x0), .result(temp2));
//                         +2            -temp2
AddSubFPU A2(.N1(32'h40000000), .N2({!temp2[31],temp2[30:0]}), .sel(1'b0), .result(temp3));
MulFPU M3(.N1(x0), .N2(temp3), .result(x1));

/*----Second Iteration----*/
MulFPU M4(.N1({1'b0,8'd126,N2[22:0]}), .N2(x1), .result(temp4));
AddSubFPU A3(.N1(32'h40000000), .N2({!temp4[31],temp4[30:0]}), .sel(1'b0), .result(temp5));
MulFPU M5(.N1(x1), .N2(temp5), .result(x2));

/*----Third Iteration----*/
MulFPU M6(.N1({1'b0,8'd126,N2[22:0]}), .N2(x2), .result(temp6));
AddSubFPU A4(.N1(32'h40000000), .N2({!temp6[31],temp6[30:0]}), .sel(1'b0), .result(temp7));
MulFPU M7(.N1(x2), .N2(temp7), .result(x3));

/*----Reciprocal : 1/B----*/
assign Exponent = x3[30:23]+8'd126-N2[30:23];
assign reciprocal = {N2[31],Exponent,x3[22:0]};

/*----Multiplication A*1/B----*/
MulFPU M8(.N1(N1), .N2(reciprocal), .result(result_unprotected));

assign result = ((N1[30:23] == 0) || zero_division) ? 32'h0000_0000 : result_unprotected;
endmodule