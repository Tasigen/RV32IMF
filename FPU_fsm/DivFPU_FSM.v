module DivFPU_FSM (
    input clk,
    input rst,
    input start,
    input [31:0] N1,
    input [31:0] N2,
    output reg [31:0] result,
    output reg done,
    output reg busy,

    output reg [31:0] operand_a,
    output reg [31:0] operand_b,
    output reg start_mul,
    input mul_done,
    input [31:0] mul_result,

    output reg start_addsub,
    input addsub_done,
    input [31:0] addsub_result
);

parameter IDLE = 4'd0, INIT = 4'd1,
          M1 = 4'd2, A1 = 4'd3, X0 = 4'd4,
          M2 = 4'd5, A2 = 4'd6, X1 = 4'd7,
          M3 = 4'd8, A3 = 4'd9, X2 = 4'd10,
          M4 = 4'd11, A4 = 4'd12, X3 = 4'd13,
          FINAL_MUL = 4'd14, DONE = 4'd15;

reg [3:0] state, next_state;
reg [31:0] temp_result, x0, x1, x2, x3, reciprocal;
reg [7:0] Exponent;

always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: next_state = start ? INIT : IDLE;
        INIT: next_state = M1;
        M1:   next_state = mul_done ? A1 : M1;
        A1:   next_state = addsub_done ? X0 : A1;
        X0:   next_state = M2;
        M2:   next_state = mul_done ? A2 : M2;
        A2:   next_state = addsub_done ? X1 : A2;
        X1:   next_state = M3;
        M3:   next_state = mul_done ? A3 : M3;
        A3:   next_state = addsub_done ? X2 : A3;
        X2:   next_state = M4;
        M4:   next_state = mul_done ? A4 : M4;
        A4:   next_state = addsub_done ? X3 : A4;
        X3:   next_state = FINAL_MUL;
        FINAL_MUL: next_state = mul_done ? DONE : FINAL_MUL;
        DONE: next_state = start ? DONE : IDLE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    start_mul <= 0;
    start_addsub <= 0;
    case (state)
        IDLE: begin
            result <= 0;
            done <= 0;
            busy <= 0;
        end
        INIT: begin
            busy <= 1;
            done <= 0;
        end
        M1: begin
            operand_a <= {1'b0, 8'd126, N2[22:0]};
            operand_b <= 32'h3ff0f0f1;
            start_mul <= 1;
        end
        A1: if (mul_done) begin
            operand_a <= 32'h4034b4b5;
            operand_b <= {1'b1, mul_result[30:0]};
            start_addsub <= 1;
        end
        X0: if (addsub_done) x0 <= addsub_result;
        M2: begin
            operand_a <= {1'b0, 8'd126, N2[22:0]};
            operand_b <= x0;
            start_mul <= 1;
        end
        A2: if (mul_done) begin
            operand_a <= 32'h40000000;
            operand_b <= {!mul_result[31], mul_result[30:0]};
            start_addsub <= 1;
        end
        X1: if (addsub_done) x1 <= addsub_result;
        M3: begin
            operand_a <= x0;
            operand_b <= addsub_result;
            start_mul <= 1;
        end
        A3: if (mul_done) begin
            operand_a <= 32'h40000000;
            operand_b <= {~mul_result[31], mul_result[30:0]};
            start_addsub <= 1;
        end
        X2: if (addsub_done) x2 <= addsub_result;
        M4: begin
            operand_a <= x2;
            operand_b <= addsub_result;
            start_mul <= 1;
        end
        A4: if (mul_done) begin
            operand_a <= 32'h40000000;
            operand_b <= {~mul_result[31], mul_result[30:0]};
            start_addsub <= 1;
        end
        X3: if (addsub_done) x3 <= addsub_result;
        FINAL_MUL: begin
            Exponent <= x3[30:23] + 8'd126 - N2[30:23];
            reciprocal <= {N2[31], Exponent, x3[22:0]};
            operand_a <= N1;
            operand_b <= reciprocal;
            start_mul <= 1;
        end
        DONE: if (mul_done) begin
            result <= mul_result;
            done <= 1;
            busy <= 0;
        end
    endcase
end

endmodule