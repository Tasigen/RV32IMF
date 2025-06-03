module DivFPU_FSM (
    input clk,
    input rst,
    input start,
    input [31:0] N1,
    input [31:0] N2,
    output reg [31:0] result,
    output reg done,
    output reg busy
);

// FSM states
parameter IDLE = 3'b000,
          UNPACK = 3'b001,
          INIT = 3'b010,
          DIVIDE = 3'b011,
          NORMALIZE = 3'b100,
          PACK = 3'b101,
          DONE = 3'b110;

reg [2:0] state, next_state;

// Internal fields
reg sign1, sign2, Sign;
reg [7:0] E1, E2, exponent;
reg [23:0] M1, M2;
reg [47:0] A, A_next;
reg [23:0] Q;
reg [4:0] count;
reg next_Q_bit;
integer i;

//temp for division
reg [47:0] A_shifted;
reg [23:0] Q_shifted;

// FSM controller
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE:      next_state = (start) ? UNPACK : IDLE;
        UNPACK:    next_state = INIT;
        INIT:      next_state = DIVIDE;
        DIVIDE:    next_state = (count == 5'd23) ? NORMALIZE : DIVIDE;
        NORMALIZE: next_state = PACK;
        PACK:      next_state = DONE;
        DONE:      next_state = (start) ? DONE : IDLE;
        default:   next_state = IDLE;
    endcase
end

// Main FSM logic
always @(posedge clk) begin
    case (state)
        IDLE: begin
            busy     <= 0;
            done     <= 0;
            //result   <= 0;
            Q        <= 0;
            A        <= 0;
            exponent <= 0;
            Sign     <= 0;
        end

        UNPACK: begin
            busy  <= 1;
            done  <= 0;
            E1    <= N1[30:23];
            E2    <= N2[30:23];
            M1    <= (N1[30:23] == 0) ? {1'b0, N1[22:0]} : {1'b1, N1[22:0]};
            M2    <= (N2[30:23] == 0) ? {1'b0, N2[22:0]} : {1'b1, N2[22:0]};
            Sign  <= N1[31] ^ N2[31];
        end

        INIT: begin
            A        <= 0;
            Q        <= M1;
            count    <= 0;
            exponent <= E1 - E2 + 127;
        end

        DIVIDE: begin
            // Shift left A and Q
            {A_shifted, Q_shifted} <= {A, Q} << 1;

            if (!A[47]) begin
                A_shifted <= A_shifted - {24'b0, M2};
                Q_shifted[0] <= 1'b1;
            end else begin
                A_shifted <= A_shifted + {24'b0, M2};
                Q_shifted[0] <= 1'b0;
            end

            A <= A_shifted;
            Q <= Q_shifted;

            count <= count + 1;
        end

        NORMALIZE: begin
            if (A[47]) A <= A + {24'b0, M2}; // Final correction

            if (Q[23] == 0 && Q != 0) begin
                for (i = 0; Q[23] != 1'b1 && exponent > 0 && i < 23; i = i + 1) begin
                    Q = Q << 1;
                    exponent = exponent - 1;
                end
            end
        end

        PACK: begin
            result <= {Sign, exponent[7:0], Q[22:0]};
        end

        DONE: begin
            busy <= 0;
            done <= 1;
        end
    endcase
end

endmodule
