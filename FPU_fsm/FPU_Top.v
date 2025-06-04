module FPU_Top (
    input clk,
    input rst,
    input start,
    input [2:0] fpu_op,       // 000=add/sub, 001=mul, 010=div, 011=neg, 100=mv
    input [31:0] N1,
    input [31:0] N2,
    output reg [31:0] result,
    output reg done,
    output reg busy
);

    // Internal control signals
    reg start_addsub, start_mul, start_div;
    wire done_addsub, done_mul, done_div;
    wire [31:0] result_addsub, result_mul, result_div;

    // FSM states
    parameter IDLE = 3'd0,
              START_OP = 3'd1,
              WAIT_OP = 3'd2,
              NEG_OP = 3'd3,
              MV_OP = 3'd4,
              DONE = 3'd5;

    reg [2:0] state, next_state;

    // Store operation
    reg [2:0] op_latched;

    // FSM
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // FSM Transitions
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    case (fpu_op)
                        3'b000, 3'b001, 3'b010: next_state = START_OP; // add/mul/div
                        3'b011: next_state = NEG_OP;
                        3'b100: next_state = MV_OP;
                        default: next_state = IDLE;
                    endcase
                end
            end

            START_OP: next_state = WAIT_OP;

            WAIT_OP: begin
                case (op_latched)
                    3'b000: if (done_addsub) next_state = DONE;
                    3'b001: if (done_mul)    next_state = DONE;
                    3'b010: if (done_div)    next_state = DONE;
                endcase
            end

            NEG_OP, MV_OP: next_state = DONE;

            DONE: next_state = IDLE;
        endcase
    end

    // Control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_addsub <= 0;
            start_mul <= 0;
            start_div <= 0;
            busy <= 0;
            done <= 0;
            op_latched <= 3'b000;
        end else begin
            start_addsub <= 0;
            start_mul <= 0;
            start_div <= 0;
            done <= 0;

            case (state)
                IDLE: begin
                    busy <= 0;
                    if (start) op_latched <= fpu_op;
                end

                START_OP: begin
                    busy <= 1;
                    case (fpu_op)
                        3'b000: start_addsub <= 1;
                        3'b001: start_mul <= 1;
                        3'b010: start_div <= 1;
                    endcase
                end

                WAIT_OP: begin
                    case (op_latched)
                        3'b000: if (done_addsub) begin
                            result <= result_addsub;
                            done <= 1;
                            busy <= 0;
                        end
                        3'b001: if (done_mul) begin
                            result <= result_mul;
                            done <= 1;
                            busy <= 0;
                        end
                        3'b010: if (done_div) begin
                            result <= result_div;
                            done <= 1;
                            busy <= 0;
                        end
                    endcase
                end

                NEG_OP: begin
                    result <= {~N1[31], N1[30:0]};
                    done <= 1;
                    busy <= 0;
                end

                MV_OP: begin
                    result <= N1;
                    done <= 1;
                    busy <= 0;
                end
            endcase
        end
    end

    // Submodule instantiations
    AddSubFPU_FSM addsub_unit (
        .clk(clk),
        .rst(rst),
        .start(start_addsub),
        .N1(N1),
        .N2(N2),
        .sel(fpu_op[0]), // 0=add, 1=sub
        .result(result_addsub),
        .done(done_addsub),
        .busy()
    );

    MulFPU_FSM mul_unit (
        .clk(clk),
        .rst(rst),
        .start(start_mul),
        .N1(N1),
        .N2(N2),
        .result(result_mul),
        .done(done_mul),
        .busy()
    );

    DivFPU_Flowchart div_unit (
        .clk(clk),
        .rst(rst),
        .start(start_div),
        .N1(N1),
        .N2(N2),
        .result(result_div),
        .done(done_div),
        .busy()
    );

endmodule
