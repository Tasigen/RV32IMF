module MulFPU(
    input         clk,
    input         rst,
    input         start,
    input  [31:0] a,
    input  [31:0] b,
    output        ready,
    output [31:0] result
);

    // Stage 1: Unpack
    reg          sign_a, sign_b;
    reg  [7:0]   exp_a, exp_b;
    reg  [23:0]  mant_a, mant_b;

    // Stage 2: Multiply mantissas
    reg          sign_res;
    reg  [47:0]  mant_mul;
    reg  [7:0]   exp_sum;

    // Stage 3: Normalize
    reg  [7:0]   exp_norm;
    reg  [22:0]  mant_norm;

    // Stage 4: Round & Pack
    reg  [31:0]  result_reg;
    reg  [3:0]   valid_pipeline;

    assign ready  = valid_pipeline[3];
    assign result = result_reg;

    // Pipeline valid control
    always @(posedge clk or posedge rst) begin
        if (rst)
            valid_pipeline <= 4'b0;
        else
            valid_pipeline <= {valid_pipeline[2:0], start};
    end

    // Stage 1: Unpack
    always @(posedge clk) begin
        if (start) begin
            sign_a = a[31];
            sign_b = b[31];
            exp_a  = a[30:23];
            exp_b  = b[30:23];
            mant_a = (exp_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
            mant_b = (exp_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
        end
    end

    // Stage 2: Multiply mantissas
    always @(posedge clk) begin
        if (valid_pipeline[0]) begin
            sign_res <= sign_a ^ sign_b;
            exp_sum  <= exp_a + exp_b - 8'd127;
            mant_mul <= mant_a * mant_b; // 24x24 = 48-bit result
        end
    end

    // Stage 3: Normalize
    always @(posedge clk) begin
        if (valid_pipeline[1]) begin
            if (mant_mul[47]) begin
                mant_norm <= mant_mul[46:24];
                exp_norm  <= exp_sum + 1;
            end else begin
                mant_norm <= mant_mul[45:23];
                exp_norm  <= exp_sum;
            end
        end
    end

    // Stage 4: Pack
    always @(posedge clk) begin
        if (valid_pipeline[2]) begin
            result_reg <= {sign_res, exp_norm, mant_norm};
        end
    end

endmodule