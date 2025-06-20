`include "../src/FPU.v"

`include "../../FPU/src/DivFPU_Flowchart.v"
`include "../../FPU/src/MulFPU.v"
`include "../../FPU/src/AddSubFPU.v"
module FPU_tb;
reg [31:0] A,B;
reg fpu_sel;
reg [2:0] fpu_control;
reg [2:0] funct3;
wire [31:0] result;
real  value; 
FPU dut (
    .rs1(A),
    .rs2(B),
    .fpu_control(fpu_control),
    .funct3(funct3),
    .fpu_sel(fpu_sel),
    .fpu_result(result)
);

initial  
begin
        $dumpfile("FPU.vcd");
        $dumpvars(0,FPU_tb);
//addition
A = 32'b0_10000000_10011001100110011001100;  // 3.2
B = 32'b0_10000001_00001100110011001100110;  // 4.2
fpu_control = 3'b000;
fpu_sel = 1'b0;
#20
A = 32'b0_01111110_01010001111010111000011;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51
fpu_control = 3'b000;
fpu_sel = 1'b0;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b1_10000001_10011001100110011001100;  // -6.4
fpu_control = 3'b000;
fpu_sel = 1'b0;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
fpu_control = 3'b000;
fpu_sel = 1'b0;
#20
A = 32'h4034b4b5;
B = 32'hbf70f0f1;
fpu_control = 3'b000;
fpu_sel = 1'b0;
//subtraction
#20
A = 32'b0_10000000_10011001100110011001100;  // 3.2
B = 32'b0_10000001_00001100110011001100110;  // 4.2
fpu_control = 3'b001;
fpu_sel = 1'b1;
#20
A = 32'b0_01111110_01010001111010111000011;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51
fpu_control = 3'b001;
fpu_sel = 1'b1;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b1_10000001_10011001100110011001100;  // -6.4
fpu_control = 3'b001;
fpu_sel = 1'b1;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
fpu_control = 3'b001;
fpu_sel = 1'b1;
#20
A = 32'h4034b4b5;
B = 32'hbf70f0f1;
fpu_control = 3'b001;
fpu_sel = 1'b1;
//Multiplication
#20
A = 32'b0_10000000_10011001100110011001100;  // 3.2
B = 32'b0_10000001_00001100110011001100110;  // 4.2
fpu_control = 3'b010;
#20
A = 32'b0_01111110_01010001111010111000011;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51
fpu_control = 3'b010;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b1_10000001_10011001100110011001100;  // -6.4
fpu_control = 3'b010;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
fpu_control = 3'b010;
#20
A = 32'h4034b4b5;
B = 32'hbf70f0f1;
fpu_control = 3'b010;
//Division
#20
B = 32'b0_10000000_10011001100110011001100;  // 3.2
A = 32'b0_10000001_00001100110011001100110;  // 4.2
fpu_control = 3'b011;
#20
A = 32'b0_01111110_01010001111010111000011;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51
fpu_control = 3'b011;
#20
B = 32'b1_01111110_00000000000000000000000;  // -0.5
A = 32'b1_10000001_10011001100110011001100;  // -6.4
fpu_control = 3'b011;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
fpu_control = 3'b011;
#20
A = 32'h4034b4b5;
B = 32'hbf70f0f1;
fpu_control = 3'b011;
#20

//sign injections
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
fpu_control = 3'b100;
funct3 = 3'b000;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
fpu_control = 3'b100;
funct3 = 3'b010;

end

initial
begin
#15
$display("===== Addition =====");
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",3.2+4.2,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",0.66+0.51,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5+(-6.4),value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5+6.4,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",2.82+(-0.94),value);


#20
$display("===== Subtraction =====");
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",3.2-4.2,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",0.66-0.51,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5-(-6.4),value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5-6.4,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",2.82-(-0.94),value);


#20
$display("===== Multiplication =====");
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",3.2*4.2,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",0.66*0.51,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5*(-6.4),value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5*6.4,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",2.82*(-0.94),value);


$display("===== Division =====");
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",4.2/3.2,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",0.66/0.51,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",(-6.4)/(-0.5),value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",(-0.5)/6.4,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",2.82/(-0.94),value, result);

#20
$display("===== Sign Injection =====");
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",0.5,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Values : %h",-0.5,value, result);


$finish;
end

endmodule