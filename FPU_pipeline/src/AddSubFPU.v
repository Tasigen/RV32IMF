module AddSubFPU (
    input         clk,
    input         rst,
    input         start,
    input         add_sub, // 0: add, 1: subtract
    input  [31:0] a,
    input  [31:0] b,
    output        ready,
    output [31:0] result
);

    // Pipeline valid tracking (5 stages)
    reg [4:0] valid;
    always @(posedge clk or posedge rst)
        if (rst) valid <= 0;
        else     valid <= {valid[3:0], start};

    assign ready = valid[4];

    // Stage 1: Unpack
    reg [7:0]  exp_a1, exp_b1;
    reg [23:0] mant_a1, mant_b1;
    reg        sign_a1, sign_b1, add_sub1;
    always @(posedge clk)
        if (start) begin
            exp_a1  <= a[30:23];
            exp_b1  <= b[30:23];
            mant_a1 <= (a[30:23] == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
            mant_b1 <= (b[30:23] == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
            sign_a1 <= a[31];
            sign_b1 <= b[31];
            add_sub1 <= add_sub;
        end

    // Stage 2: Align
    reg [23:0] mant_a2, mant_b2;
    reg [7:0]  exp_diff2, exp_large2;
    reg        sign_large2, sign_small2, op2;
    always @(posedge clk)
        if (valid[0]) begin
            if (exp_a1 > exp_b1) begin
                mant_a2 <= mant_a1;
                mant_b2 <= mant_b1 >> (exp_a1 - exp_b1);
                exp_diff2 <= exp_a1 - exp_b1;
                exp_large2 <= exp_a1;
                sign_large2 <= sign_a1;
                sign_small2 <= sign_b1;
            end else begin
                mant_a2 <= mant_a1 >> (exp_b1 - exp_a1);
                mant_b2 <= mant_b1;
                exp_diff2 <= exp_b1 - exp_a1;
                exp_large2 <= exp_b1;
                sign_large2 <= sign_b1;
                sign_small2 <= sign_a1;
            end
            op2 <= add_sub1;
        end

    // Stage 3: Add/Subtract
    reg [24:0] mant_res3;
    reg [7:0]  exp_res3;
    reg        sign_res3;
    always @(posedge clk)
        if (valid[1]) begin
            if (sign_large2 == sign_small2 ^ op2) begin
                mant_res3 <= {1'b0, mant_a2} + {1'b0, mant_b2};
                sign_res3 <= sign_large2;
            end else begin
                if (mant_a2 >= mant_b2) begin
                    mant_res3 <= {1'b0, mant_a2} - {1'b0, mant_b2};
                    sign_res3 <= sign_large2;
                end else begin
                    mant_res3 <= {1'b0, mant_b2} - {1'b0, mant_a2};
                    sign_res3 <= ~sign_large2;
                end
            end
            exp_res3 <= exp_large2;
        end

    // Stage 4: Normalize
    reg [22:0] mant_norm4;
    reg [7:0]  exp_norm4;
    reg        sign_norm4;
    always @(posedge clk)
        if (valid[2]) begin
            if (mant_res3[24]) begin
                mant_norm4 <= mant_res3[23:1];
                exp_norm4 <= exp_res3 + 1;
            end else begin
                mant_norm4 <= mant_res3[22:0];
                exp_norm4 <= exp_res3;
            end
            sign_norm4 <= sign_res3;
        end

    // Stage 5: Pack
    reg [31:0] result_reg;
    always @(posedge clk)
        if (valid[3])
            result_reg <= {sign_norm4, exp_norm4, mant_norm4};

    assign result = result_reg;

endmodule
