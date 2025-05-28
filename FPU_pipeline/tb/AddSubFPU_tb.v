`include "../src/AddSubFPU.v"

module AddSubFPU_tb;
reg [31:0] A,B;
reg sel;
wire [31:0] result;
real  value; 
AddSubFPU dut (
    .N1(A),
    .N2(B),
    .sel(sel),
    .result(result)
);

initial  
begin
        $dumpfile("AddSubFPU.vcd");
        $dumpvars(0,AddSubFPU_tb);
A = 32'b0_10000000_10011001100110011001100;  // 3.2
B = 32'b0_10000001_00001100110011001100110;  // 4.2
sel = 1'b1;
#20
A = 32'b0_01111011_10011001100110011001101;
B = 32'b0_01111011_10011001100110011001101;
/*A = 32'b0_01111110_01010001111010111000011;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51*/
sel = 1'b1;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b1_10000001_10011001100110011001100;  // -6.4
sel = 1'b1;
#20
A = 32'b1_01111110_00000000000000000000000;  // -0.5
B = 32'b0_10000001_10011001100110011001100;  //  6.4
sel = 1'b1;
#20
A = 32'h4034b4b5;
B = 32'hbf70f0f1;
sel = 1'b1;
end

initial
begin
#15
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",3.2-4.2,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",0.1-0.1,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5-(-6.4),value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",-0.5-6.4,value);
#20
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",2.82-(-0.94),value);
$finish;
end

endmodule