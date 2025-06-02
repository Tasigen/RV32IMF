
module MulFPU_FSM (
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
          MULTIPLY = 3'b010,
          NORMALIZE = 3'b011,
          PACK = 3'b100,
          DONE = 3'b101;

reg [2:0] state, next_state;

// Internal registers
reg [23:0] M1, M2;
reg [7:0] E1, E2, exponent;
reg [8:0] E;
reg S1, S2, Sign;
reg [47:0] M;
reg [22:0] mantissa;

reg zero_flag;
integer i;

always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE:       next_state = start ? UNPACK : IDLE;
        UNPACK:     next_state = MULTIPLY;
        MULTIPLY:   next_state = NORMALIZE;
        NORMALIZE:  next_state = PACK;
        PACK:       next_state = DONE;
        DONE:       next_state = start ? DONE : IDLE;
        default:    next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    case (state)
        IDLE: begin
            busy <= 0;
            done <= 0;
            result <= 32'd0;
            exponent <= 8'd0;
            mantissa <= 23'd0;
            M <= 48'd0;
        end

        UNPACK: begin
            busy <= 1;
            done <= 0;

            M1 <= {1'b1, N1[22:0]};
            M2 <= {1'b1, N2[22:0]};

            E1 <= N1[30:23];
            E2 <= N2[30:23];

            S1 <= N1[31];
            S2 <= N2[31];
            
            Sign <= N1[31] ^ N2[31];
        end

        MULTIPLY: begin
            if (M1[22:0] == 0 || M2[22:0] == 0) begin
                M <= 0;
                E <= 0;
                zero_flag <= 1;
            end else begin
                M <= M1 * M2;
                E <= E1 + E2 - 127;
                zero_flag <=0;
                if (M[47]) begin
                    M <= M >> 1;
                    E <= E + 1;
                end
            end
        end

        NORMALIZE: begin
            if (M != 0 && !M[47]) begin
                for (i = 0; M[46] !== 1'b1 && E > 0 && i < 47; i = i + 1) begin
                    M <= M << 1;
                    E <= E - 1;
                end
            end

            if (E[8]) begin
                exponent <= 8'hFF;
                mantissa <= 23'd0; 
            end else begin
                exponent <= E[7:0];
                mantissa <= M[45:23];
            end
        end

        PACK: begin
            if (zero_flag)
                result <= 8'h0;
            else
                result <= {Sign, exponent, mantissa};        
        end

        DONE: begin
            busy <= 0;
            done <= 1;
        end
    endcase
end

endmodule
