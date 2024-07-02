`timescale 1ns / 1ps

module alu_control (
    input  [1:0] alu_op,    // ALUOp
    input  [5:0] funct,     // Funct field
    output [3:0] operation  // Operation
);
  
    assign operation = (alu_op == 2'b00)? 4'b0010 :
        (alu_op == 2'b01)? 4'b0110 :
        (funct == 6'b000000 || funct == 6'b100000)? 4'b0010 : // nop
        (funct == 6'b100010)? 4'b0110 :
        (funct == 6'b100100)? 4'b0000 :
        (funct == 6'b100101)? 4'b0001 : 
        4'b0111; 

endmodule
