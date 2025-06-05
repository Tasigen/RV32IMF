`timescale 1ns / 1ps
module SqrtFPU (
    input  [31:0] A,
    output       overflow,
    output       underflow,
    output       exception,
    output [31:0] result
);
    // Extract sign, exponent, mantissa
    wire Sign = A[31];
    wire [7:0] Exponent = A[30:23];
    wire [22:0] Mantissa = A[22:0];

    // Temporary wires for iterations and results
    wire [31:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8, temp;
    wire [31:0] x0, x1, x2, x3;

    // Constants: 1/sqrt(5), sqrt(2), 1/sqrt(2)
    wire [31:0] sqrt_1by05 = 32'h3EE4F8B6;  // ≈ 0.4472136
    wire [31:0] sqrt_2    = 32'h3FB504F3;  // ≈ 1.4142135
    wire [31:0] sqrt_1by2  = 32'h3F3504F3;  // ≈ 0.7071068

    // Exponent adjustments
    wire pos;
    wire [7:0] Exp_2;
    wire remainder;

    // Initial approximation for sqrt (Newton-Raphson seed)
    assign x0 = 32'h3F5A827A;  // ≈ 0.8451543

    // First Newton-Raphson iteration:
    // x1 = 0.5 * (x0 + (M1 / x0))
    // We do: temp1 = (1.Mantissa)/x0, temp2 = x0 + temp1, then x1 = temp2 * 0.5
    DivFPU D1 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1({1'b0, 8'd126, Mantissa}),  // Normalized mantissa as 1.xxxxx
        .N2(x0),
        .result(temp1)
    );
    AddSubFPU A1 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1(temp1),
        .N2(x0),
        .sel(1'b0),
        .result(temp2)
    );
    // Multiply by 0.5 to average: x1 = temp2 * 0.5
    assign x1 = {temp2[31], temp2[30:23] - 1'b1, temp2[22:0]};

    // Second iteration:
    DivFPU D2 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1({1'b0, 8'd126, Mantissa}),
        .N2(x1),
        .result(temp3)
    );
    AddSubFPU A2 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1(temp3),
        .N2(x1),
        .sel(1'b0),
        .result(temp4)
    );
    assign x2 = {temp4[31], temp4[30:23] - 1'b1, temp4[22:0]};

    // Third iteration:
    DivFPU D3 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1({1'b0, 8'd126, Mantissa}),
        .N2(x2),
        .result(temp5)
    );
    AddSubFPU A3 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1(temp5),
        .N2(x2),
        .sel(1'b0),
        .result(temp6)
    );
    assign x3 = {temp6[31], temp6[30:23] - 1'b1, temp6[22:0]};

    // Multiply x3 by 1/sqrt(5) to get refined root mantissa:
    MulFPU M1 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1(x3),
        .N2(sqrt_1by05),
        .result(temp7)
    );

    // Adjust exponent: if original exponent >= 127, use (exp-127)/2 + 127, else adjust for odd case
    assign pos  = (Exponent >= 8'd127) ? 1'b1 : 1'b0;
    assign Exp_2 = pos ? ((Exponent - 8'd127) >> 1) + 8'd127
                       : (((Exponent - 8'd127 - 1) >> 1) + 8'd127);
    assign remainder = ((Exponent - 8'd127) & 1'b1);

    // Pack mantissa and adjusted exponent into 'temp'
    assign temp = { temp7[31], Exp_2 + temp7[30:23], temp7[22:0] };

    // If original exponent was odd (remainder=1), multiply by sqrt(2):
    MulFPU M2 (
        .clk(1'b0), .rst(1'b0), .start(1'b1),
        .N1(temp),
        .N2(sqrt_2),
        .result(temp8)
    );

    assign result = remainder ? temp8 : temp;

    // For simplicity, tie off exception flags
    assign overflow  = 1'b0;
    assign underflow = 1'b0;
    assign exception = 1'b0;

endmodule
