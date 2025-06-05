//---------------------------------------------------------------------------------
//  DivFPU_Flowchart.v
//
//  Implements the flowchart from “Fig 4 – Flow Chart for floating point Division”
//  (q = x / d; N1 = x, N2 = d)
//  This module assumes IEEE-754 single‐precision (32-bit) inputs and outputs.
//  It is an FSM that takes multiple cycles: UNPACK → CALC → NORMALIZE → PACK → DONE
//
//  Usage:
//    * Apply `start=1` for one cycle after both N1 and N2 are valid.
//    * The unit will assert `busy=1` while it works, then `done=1` for one cycle
//      when the result is ready.  After `start` is lowered, it returns to IDLE.
//    * If N2 (the divisor) is zero, this simply outputs zero (you can extend it to INF if needed).
//---------------------------------------------------------------------------------

module DivFPU_Flowchart (
    input  wire         clk,
    input  wire         rst,      // Active‐high synchronous reset
    input  wire         start,    // Start signal (pulse for one cycle)
    input  wire [31:0]  N1,       // Dividend (IEEE-754 single)
    input  wire [31:0]  N2,       // Divisor  (IEEE-754 single)
    output reg  [31:0]  result,   // Quotient (IEEE-754 single)
    output reg          busy,     // High while FSM is working
    output reg          done      // Pulses high for one cycle when result is valid
);

//---------------------------------------------------------------------------------
//  State Encoding
//---------------------------------------------------------------------------------
localparam IDLE      = 3'd0,
           UNPACK    = 3'd1,
           CALC      = 3'd2,
           NORMALIZE = 3'd3,
           PACK      = 3'd4,
           DONE      = 3'd5;

reg [2:0] state, next_state;

//---------------------------------------------------------------------------------
//  Internal Registers for Unpacked Fields
//---------------------------------------------------------------------------------
reg         sign1, sign2, Sign;       // Individual signs, then final sign
reg  [7:0]  E1, E2;                    // Original exponents (biased)
reg  [23:0] M1, M2;                    // “Unpacked” mantissas (with implicit 1 for normals)
reg  [7:0]  exp_diff;                 // E_out = E1 – E2 + 127

//---------------------------------------------------------------------------------
//  Raw Mantissa Quotient (“fixed-point” / 24‐bit fraction)  
//      – We compute (M1<<23) / M2 in one cycle, storing the 24 top bits in raw_mant.
//      – That is a 24-bit “1.xxx…” or “0.xxx…” representation.  
//---------------------------------------------------------------------------------
reg [47:0] numerator;
reg  [23:0] raw_mant;

//---------------------------------------------------------------------------------
//  Loop-counter for normalization (shifting left if raw_mant<1.0)  
//---------------------------------------------------------------------------------
reg  [4:0]  norm_count;

//---------------------------------------------------------------------------------
//  State Register
//---------------------------------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) 
        state <= IDLE;
    else 
        state <= next_state;
end

//---------------------------------------------------------------------------------
//  Next‐State Logic
//---------------------------------------------------------------------------------
always @(*) begin
    case (state)
        //───────────────────────────────────────────────────────────────────────────
        IDLE: begin
            if (start) 
                next_state = UNPACK;
            else 
                next_state = IDLE;
        end
        //───────────────────────────────────────────────────────────────────────────
        UNPACK: 
            // We immediately go on to division once unpacking is captured
            next_state = CALC;
        //───────────────────────────────────────────────────────────────────────────
        CALC: 
            // After computing raw mantissa, move to normalization
            next_state = NORMALIZE;
        //───────────────────────────────────────────────────────────────────────────
        NORMALIZE: begin
            // If raw_mant==0, we will go straight to PACK.
            // Otherwise, if raw_mant[23] == 1 → it's already normalized → PACK.
            // Else we keep shifting left until it becomes 1.xxx… or norm_count hits max.
            if (raw_mant == 24'd0) 
                next_state = PACK;
            else if (raw_mant[23] == 1'b1) 
                next_state = PACK;
            else 
                next_state = NORMALIZE; 
        end
        //───────────────────────────────────────────────────────────────────────────
        PACK: 
            // After packing everything into a 32-bit result, go to DONE
            next_state = DONE;
        //───────────────────────────────────────────────────────────────────────────
        DONE: begin
            // Wait for start to be de-asserted before returning to IDLE
            if (start) 
                next_state = DONE;
            else 
                next_state = IDLE;
        end
        //───────────────────────────────────────────────────────────────────────────
        default: 
            next_state = IDLE;
    endcase
end

//---------------------------------------------------------------------------------
//  Main FSM Sequential Block
//    – All registers are updated on the rising edge of clk.
//    – We use blocking assignments in states UNPACK→CALC→NORMALIZE→PACK→DONE
//      so that each state’s work is “committed” before moving on.
//---------------------------------------------------------------------------------
always @(posedge clk) begin
    if (rst) begin
        // Reset outputs and key registers
        busy       <= 1'b0;
        done       <= 1'b0;
        result     <= 32'd0;
        Sign       <= 1'b0;
        E1         <= 8'd0;
        E2         <= 8'd0;
        M1         <= 24'd0;
        M2         <= 24'd0;
        exp_diff   <= 8'd0;
        raw_mant   <= 24'd0;
        norm_count <= 5'd0;
    end
    else begin
        case (state)
        //────────────────────────────────────────────────────────────────────
        IDLE: begin
            busy   <= 1'b0;
            done   <= 1'b0;
            result <= 32'd0;
            // We wait here until start=1 → next_state = UNPACK
        end
        //────────────────────────────────────────────────────────────────────
        UNPACK: begin
            // As soon as start=1, we latch inputs and declare “busy”.
            busy <= 1'b1;
            done <= 1'b0;

            // Extract sign bits
            Sign  <= N1[31] ^ N2[31];      // Final sign = XOR

            // Extract unbiased exponent fields
            E1 <= N1[30:23];
            E2 <= N2[30:23];

            // Extract mantissas, inserting the implicit “1” if exponent≠0
            // (If E=0, input was zero or subnormal; here we treat subnormals as having leading 0.)
            if (N1[30:23] == 8'd0) 
                M1 <= {1'b0, N1[22:0]};  
            else 
                M1 <= {1'b1, N1[22:0]};

            if (N2[30:23] == 8'd0) 
                M2 <= {1'b0, N2[22:0]};  
            else 
                M2 <= {1'b1, N2[22:0]};

            // Pre‐compute biased exponent difference:
            //   exp_diff = (E1 – E2) + 127
            // We’ll correct for normalization below.
            
        end
        //────────────────────────────────────────────────────────────────────
        CALC: begin
            // In one cycle, compute the fixed‐point mantissa quotient:
            //   raw_mant = (M1 << 23) / M2
            //
            // M1 and M2 are each 24 bits wide (1.xxx), so (M1 << 23) is up to 47 bits.
            // We store only the top 24 bits of the quotient in raw_mant,
            // which corresponds to a 1.xxx or 0.xxx 24-bit fixed-point number.
            exp_diff <= (E1 >= E2) 
                        ? (E1 - E2 + 8'd127) 
                        : (8'd127 - (E2 - E1)); // (if E2>E1, this will underflow below if not normalized)
                  // 24 bits of M1 followed by 23 zero‐bits → 47 bits total
            raw_mant  <= { M1, 23'd0 } / M2;   // Now you really are doing (M1 << 23) / M2
            // Reset our normalization loop counter
            norm_count <= 5'd0;
        end
        //────────────────────────────────────────────────────────────────────
        NORMALIZE: begin
            // If the divisor was zero (M2==0), then raw_mant=undefined; we force output=0
            // (Alternatively, you could set an Infinity bit, but the flowchart says “Set exponent=0”.)
            if (M2 == 24'd0) begin
                exp_diff <= 8'd0;
                raw_mant <= 24'd0;
            end
            // If raw_mant == 0 (happens if M1 was zero), force result=0:
            else if (raw_mant == 24'd0) begin
                exp_diff <= 8'd0;
                raw_mant <= 24'd0;
            end
            else begin
                // If raw_mant >= 1.0 (i.e. top bit [23] is 1), we're already normalized:
                if (raw_mant[23] == 1'b1) begin
                    // No shift needed—just go to PACK
                end
                else begin
                    // raw_mant < 1.0: shift left until bit23=1 or exponent underflows
                    if (raw_mant[23] == 1'b0 && norm_count < 5'd23) begin
                        raw_mant   <= raw_mant << 1;
                        exp_diff   <= exp_diff - 8'd1;
                        norm_count <= norm_count + 5'd1;
                    end
                    // Once raw_mant[23]==1, we fall through to PACK on the next cycle.
                end
            end
        end
        //────────────────────────────────────────────────────────────────────
        PACK: begin
            // We only reach PACK once raw_mant is in 1.xxxx… form (or zero).
            // Slice off the low 23 bits as the fraction, and use exp_diff as the final exponent.
            result  <= { Sign, exp_diff[7:0], raw_mant[22:0] };
        end
        //────────────────────────────────────────────────────────────────────
        DONE: begin
            busy <= 1'b0;
            done <= 1'b1;
            // Stay here until start is de-asserted, then return to IDLE.
        end
        //────────────────────────────────────────────────────────────────────
        default: begin
            // Should never happen, but safe fallback to IDLE
            busy   <= 1'b0;
            done   <= 1'b0;
            result <= 32'd0;
        end
        endcase
    end
end

endmodule
