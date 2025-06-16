`timescale 1ns/1ps

module MDU_tb;

  // Inputs
  reg [31:0] rs1;
  reg [31:0] rs2;
  reg [2:0] function3;

  // Output
  wire [31:0] mdu_result;

  // Instantiate the Unit Under Test (UUT)
  MDU uut (
    .rs1(rs1), 
    .rs2(rs2), 
    .function3(function3), 
    .mdu_result(mdu_result)
  );

  // Task for displaying results
  task display_result;
    input [255:0] opname;
    input [31:0] expected;
    begin
      $display("[%s] rs1 = %d, rs2 = %d => result = %d (hex = %h), expected = %d (hex = %h)",
               opname, rs1, rs2, mdu_result, mdu_result, expected, expected);
    end
  endtask

  initial begin
    $display("\n--- Starting MDU Testbench ---\n");

    // MUL: 10 * 5 = 50
    rs1 = 32'sd10; rs2 = 32'sd5; function3 = 3'b000; #10; display_result("MUL", 32'd50);

    // MULH: (123456 * 654321) >> 32 = 188192925
    rs1 = 32'sd123456; rs2 = 32'sd654321; function3 = 3'b001; #10; display_result("MULH", 32'd18);

    // MULHSU: (-1000 * 2000) >> 32 = 0xFFFFFFFF (since result is negative high bits = -1 = 0xFFFFFFFF)
    rs1 = -32'sd1000; rs2 = 32'd2000; function3 = 3'b010; #10; display_result("MULHSU", 32'hFFFFFFFF);

    // MULHU: (40000 * 30000) >> 32 = 0
    rs1 = 32'd40000; rs2 = 32'd30000; function3 = 3'b011; #10; display_result("MULHU", 32'd0);

    // DIV: -100 / 25 = -4
    rs1 = -32'sd100; rs2 = 32'sd25; function3 = 3'b100; #10; display_result("DIV", -32'sd4);

    // DIVU: 100 / 25 = 4
    rs1 = 32'd100; rs2 = 32'd25; function3 = 3'b101; #10; display_result("DIVU", 32'd4);

    // REM: -100 % 30 = -10
    rs1 = -32'sd100; rs2 = 32'sd30; function3 = 3'b110; #10; display_result("REM", -32'sd10);

    // REMU: 100 % 30 = 10
    rs1 = 32'd100; rs2 = 32'd30; function3 = 3'b111; #10; display_result("REMU", 32'd10);

    $display("\n--- MDU Testbench Complete ---\n");
    $finish;
  end

endmodule
