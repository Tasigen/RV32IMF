module MulFPU (
    input [31:0] N1,
    input [31:0] N2,
    output [31:0]result
);

//paramter for preporcessing
reg [23:0] M1 , M2;
reg [7:0] E1, E2;
reg S1, S2;
integer i;
//parameter for temporary resullt
reg [47:0] M;
reg [8:0] E;
// parameter for final result
reg [22:0] mantissa;
reg [7:0] exponent;
reg Sign;

always @ (*) begin
// Initiialize the values
    M1 = {1'b1,N1[22:0]};
    M2 = {1'b1,N2[22:0]};

    E1 = N1[30:23];
    E2 = N2[30:23];

    S1 = N1[31];
    S2 = N2[31];

// compute sign 
    Sign = S1 ^ S2;

// Add E1 from E2
    E = E1 + E2 - 127;

// Multiply M1 and M2
    M = M1 * M2;
    // check for M overflows
    if (M == 0)
        E = 0;
    // check if there is is a carry
    else if (M[47]) begin
        M = M >> 1;
        E = E + 1;
    end
    else begin 
        // normalize the value
        for (i = 0; M[46] !== 1'b1 && E > 0 && i < 47; i = i + 1) begin
             M = M << 1;
             E = E - 1;
         end
    end

    //check for exponent overflow
    if (E[8])
        E[7:0] = 8'hFF;
    //final result for mantissa and exponent
    mantissa = M[45:23];
    exponent = E[7:0];
end

assign result = {Sign, exponent, mantissa};

endmodule