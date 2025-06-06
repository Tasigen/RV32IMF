`define FPU_ADD 1'b0
`define FPU_SUB 1'b1

module AddSubFPU_FSM (
    input clk,
    input rst,
    input start,
    input [31:0] N1,
    input [31:0] N2,
    input sel,
    output reg [31:0] result,
    output reg done,
    output reg busy
);

// FSM states
parameter IDLE = 3'b000,
          UNPACK = 3'b001,
          ALIGN = 3'b010,
          OPERATE = 3'b011,
          NORMALIZE = 3'b100,
          PACK = 3'b101,
          DONE = 3'b110;

reg [2:0] state, next_state;

// Internal registers
reg [7:0] E1, E2, exponent;
reg [23:0] S1, S2, temp_mantissa;
reg [22:0] mantissa;
reg sign1, sign2, Sign;
reg [7:0] d;
integer i;

reg carry;
reg [31:0] N1_swap, N2_swap;
reg sel_reg;

// FSM control
always @(posedge clk or rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE:      next_state = (start) ? UNPACK : IDLE;
        UNPACK:    next_state = ALIGN;
        ALIGN:     next_state = OPERATE;
        OPERATE:   next_state = NORMALIZE;
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
            busy = 0;
            done = 0;
            //result <= 32'd0;
            exponent = 8'd0;
            mantissa = 23'd0;
            temp_mantissa = 24'd0;
        end

        UNPACK: begin
            busy = 1;
            done = 0;
            N1_swap = N1;
            N2_swap = N2;
            sel_reg = sel;

            // Is E1 =  0
            if (N1[31:23] == 0)
                S1[23] = 1'b0;
            //is E2 = 0
            if (N2[31:23] == 0)
                S2[23] = 1'b0;

            //Is E2 greater than E1? Yes(swap) : No(Dont swap) 
            if (N2[30:23] > N1[30:23]) 
                begin
                    N1_swap = N2;
                    N2_swap = N1;
                end
            else
                begin
                    N1_swap = N1;
                    N2_swap = N2;
                end     

            // Unpack fields
            E1 = N1_swap[30:23];
            E2 = N2_swap[30:23];
            S1 = {1'b1, N1_swap[22:0]};
            S2 = {1'b1, N2_swap[22:0]};
            sign1 = N1_swap[31];
            sign2 = N2_swap[31];
        end

        ALIGN: begin
            //shifting by d
            d = E1 - E2;
            S2 = (d > 0)? (S2 >> d) : S2;
            E2 = E2 + d;
            exponent = E1;
        end

        OPERATE: begin
            case(sel_reg)
                `FPU_ADD :{carry,temp_mantissa} = (sign1 ~^ sign2)? (S1 + S2) : (S1 - S2);
                `FPU_SUB : begin
                            {carry,temp_mantissa} = (sign1 ~^ sign2)? S1 - S2 : S1 + S2;
                            if (N2[30:23] > N1[30:23]) sign1 = ~sign1;
                end
                //default :temp_mantissa = 23'b0;
            endcase
        end

        NORMALIZE: begin
            // check for the 1.xxxx format in mantissa
            if(carry)
                begin
                    temp_mantissa = temp_mantissa>>1;
                    exponent = (exponent < 8'hff) ? exponent + 1 : 8'hff;  // protect exponent overflow
                    mantissa = temp_mantissa[22:0];
                    Sign = sign1; 
                end
            else if(|temp_mantissa == 24'b0)  // mantissa contains no 1 or unknown value (result should be 0)
                begin
                    temp_mantissa = 0;
                    exponent = 0;
                    Sign = 0;
                end
            else
                begin
                    // 1st bit is not 1, but there is some 1 in the mantissa (protecting exponent underflow)
                    // fixed limit of iterations because Vivado saw this as an infinite loop
                    for(i = 0; temp_mantissa[23] !== 1'b1 && exponent > 0 && i < 24; i = i + 1) begin
                        temp_mantissa = temp_mantissa << 1;
                        exponent = exponent - 1;
                    end

                    mantissa = temp_mantissa[22:0];
                    Sign = sign1; 
                end         
        end

        PACK: begin

            result = {Sign, exponent, mantissa};
        end

        DONE: begin
            busy = 0;
            done = 1;
        end
    endcase
end

endmodule
