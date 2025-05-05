`include "../src/registerFPU.v"

module registerFPU_tb;
reg clk, rst;
reg rw;
reg [4:0] RR1,RR2;
reg [4:0] WR;
reg [31:0] WD;
wire [31:0] RD1, RD2;
real  value;

registerFPU dut (
    .clk(clk),
    .rst(rst),
    .reg_write(rw),
    .read_reg1(RR1),
    .read_reg2(RR2),
    .write_reg(WR),
    .write_data(WD),
    .read_data1(RD1),
    .read_data2(RD2)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    $dumpfile("registerFPU.vcd");
    $dumpvars(0,registerFPU_tb);


    rst = 1;
    #10
    rst = 0;

    RR1 = 5'b00000;
    rw = 1;
    WR = 5'b00000;
    WD = 1;
    #10
    RR1 = 5'b00001;


    #100

    $finish;
end


initial
begin
    $monitor("Time = %0t | clk = %b | rst = %b | count = %d", $time, clk, rst, RD1);
/*$display("Expected Value : %f Result : %f",2.82-(-0.94),value);*/
end

endmodule