module DivFPU_Flowchart (
    input  [31:0] N1,
    input  [31:0] N2,
    output [31:0] result
);

    // Internal variables
    reg [23:0] M1, M2;
    reg [24:0] M;        // Mantissa result after division
    reg [8:0] E;
    reg [47:0] raw_mant;
    reg [22:0] mantissa;
    reg [7:0] exponent;
    reg Sign;
    wire [7:0] E1, E2;
    wire S1, S2;
    integer i;

    assign E1 = N1[30:23];
    assign E2 = N2[30:23];
    assign S1 = N1[31];
    assign S2 = N2[31];

    always @(*) begin
        // Step 1: Compute Sign
        Sign = S1 ^ S2;

        // Step 2: Extract mantissas with hidden bit
        M1 = {1'b1, N1[22:0]};
        M2 = {1'b1, N2[22:0]};

        // Step 3: Subtract exponents and add bias
        E = E1 - E2 + 127;

        // Step 4: Fixed-point division (scaled)
        raw_mant <= {M1,23'b0};
        M = raw_mant / M2;  // 47-bit numerator


        // Step 5: Zero check
        if (M == 0) begin
            E = 8'd0;
            mantissa = 23'd0;
        end else begin
            if (M[24]) begin
                M = M >> 1;
                E = E + 1;
            end
            // Step 6: Normalize using a for loop
            else begin
            for (i = 0;!M[23] && E > 0 && i < 23; i = i + 1) begin
                M = M << 1;
                E = E - 1;
            end
            end

            // Step 7: Check for exponent overflow
            if (E[8]) begin
                exponent = 8'hFF;
                mantissa = 23'd0;
            end else begin
                exponent = E[7:0];
                mantissa = M; // Extract top 23 bits
            end
        end
    end

    assign result = {Sign, exponent, mantissa};

endmodule
