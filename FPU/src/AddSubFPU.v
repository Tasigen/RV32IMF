`define FPU_ADD 1'b0
`define FPU_SUB 1'b1 

module AddSubFPU (
    input [31:0] N1,
    input [31:0] N2,
    input sel,
    output [31:0] result
);

//parameter for comparison
reg [31:0] N1_swap, N2_swap;
//paramter for preporcessing
reg [7:0] E1, E2;
reg [7:0] d;
//parameter for temporary resullt
reg [23:0] S1 , S2;
reg sign1, sign2;
reg carry;
reg [23:0] temp_mantissa;
// parameter for final result
reg [22:0] mantissa;
reg [7:0] exponent;
reg Sign;

integer i;

always @(*)
begin

N1_swap = N1;
N2_swap = N2;

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

//assign to the temporary values
S1 = {1'b1, N1_swap[22:0]};
S2 = {1'b1, N2_swap[22:0]};
sign1 = N1_swap[31];
sign2 = N2_swap[31];
E1 = N1_swap[30:23];
E2 = N2_swap[30:23];

//shifting by d
d = E1 - E2;
S2 = (d > 0)? (S2 >> d) : S2;
E2 = E2 + d;
exponent = E1;

case(sel)
    `FPU_ADD :{carry,temp_mantissa} = (sign1 ~^ sign2)? (S1 + S2) : (S1 - S2);
    `FPU_SUB : begin
                {carry,temp_mantissa} = (sign1 ~^ sign2)? S1 - S2 : S1 + S2;
                if (N2[30:23] > N1[30:23]) sign1 = ~sign1;
    end
     //default :temp_mantissa = 23'b0;
endcase

// check for the 1.xxxx format in mantissa
if(carry)
    begin
        temp_mantissa = temp_mantissa>>1;
        exponent = (exponent < 8'hff) ? exponent + 1 : 8'hff;  // protect exponent overflow
    end
else if(|temp_mantissa != 1'b1)  // mantissa contains no 1 or unknown value (result should be 0)
    begin
        temp_mantissa = 0;
    end
else
    begin
        // 1st bit is not 1, but there is some 1 in the mantissa (protecting exponent underflow)
        // fixed limit of iterations because Vivado saw this as an infinite loop
        for(i = 0; temp_mantissa[23] !== 1'b1 && exponent > 0 && i < 24; i = i + 1) begin
            temp_mantissa = temp_mantissa << 1;
            exponent = exponent - 1;
        end
    end
end

assign result = {sign1,exponent,temp_mantissa[22:0]};

endmodule