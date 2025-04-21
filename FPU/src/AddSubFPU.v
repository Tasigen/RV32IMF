module AddSubFPU (
    input [31:0] N1,
    input [31:0] N2,
    output [31:0] result
);

//parameter for comparison
reg [31:0] N1_swap, N2_swap;
wire comp;
// parameter for final result
reg [23:0] mantissa;
reg [7:0] exponent;
reg Sign;

always @(*)
begin

end
endmodule