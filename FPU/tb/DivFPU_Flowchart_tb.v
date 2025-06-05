`include "../src/DivFPU_Flowchart.v"

module DivFPU_Flowchart_tb;
reg [31:0] A,B;
wire [31:0] result;
real  value; 
DivFPU_Flowchart dut (
    .N1(A),
    .N2(B),
    .result(result)
);

initial  
begin
        $dumpfile("DivFPU_Flowchart.vcd");
        $dumpvars(0,DivFPU_Flowchart_tb);
A = 32'b0_10000000_10011001100110011001100;  // 3.2
B = 32'b0_10000001_00001100110011001100110;  // 4.2
#20
A = 32'b0_01111011_10011001100110011001101;
B = 32'b0_01111011_10011001100110011001101;
/*A = 32'b0_01111110_01010001111010111000011;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51*/
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b1_10000001_10011001100110011001100;  // -6.4
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
#20
A = 32'h4034b4b5;
B = 32'hbf70f0f1;
#20
A=32'b01000000000000000000000000000000;
B=32'b01000000010000000000000000000000;
end

initial
begin
#15
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Value : %h",3.2/4.2,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Value : %h",0.1/0.1,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Value : %h",-0.5/(-6.4),value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Value : %h",-0.5/6.4,value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Value : %h",2.82/(-0.94),value, result);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f Hex Value : %h",2/(3),value, result);
$finish;
end

endmodule