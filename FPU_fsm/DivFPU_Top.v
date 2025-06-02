
module DivFPU_Top (
    input clk,
    input rst,
    input start,
    input [31:0] N,
    input [31:0] D,
    output [31:0] result,
    output done,
    output busy
);

// Internal signals
wire start_mul, mul_done, mul_busy;
wire start_addsub, addsub_done, addsub_busy;
wire [31:0] operand_a, operand_b;
wire [31:0] mul_result, addsub_result;

// Instantiate the Division FSM
DivFPU_FSM div_fpu (
    .clk(clk),
    .rst(rst),
    .start(start),
    .N1(N),
    .N2(D),
    .result(result),
    .done(done),
    .busy(busy),
    .start_mul(start_mul),
    .mul_done(mul_done),
    .mul_result(mul_result),
    .start_addsub(start_addsub),
    .addsub_done(addsub_done),
    .addsub_result(addsub_result)
);

// Instantiate the Multiplier FSM
MulFPU_FSM mul_fpu (
    .clk(clk),
    .rst(rst),
    .start(start_mul),
    .N1(operand_a),
    .N2(operand_b),
    .result(mul_result),
    .done(mul_done),
    .busy(mul_busy)
);

// Instantiate the Adder/Subtractor FSM
AddSubFPU_FSM addsub_fpu (
    .clk(clk),
    .rst(rst),
    .start(start_addsub),
    .N1(operand_a),
    .N2(operand_b),
    .sel(1'b1), // For Newton-Raphson, always subtract (2 - D*x)
    .result(addsub_result),
    .done(addsub_done),
    .busy(addsub_busy)
);

endmodule
