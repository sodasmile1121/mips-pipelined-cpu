`timescale 1ns / 1ps

module control (
    input  [5:0] opcode,      // the opcode field of a instruction is [31:26]
    output       reg_dst,     // select register destination: rt(0), rd(1)
    output       jump,        // this is a jump instruction or not
    output       alu_src,     // select 2nd operand of ALU: rt(0), sign-extended(1)
    output       mem_to_reg,  // select data write to register: ALU(0), memory(1)
    output       reg_write,   // enable write to register file
    output       mem_read,    // enable read form data memory
    output       mem_write,   // enable write to data memory
    output       branch,      // this is a branch instruction or not (work with alu.zero)
    output       [1:0] alu_op       // ALUOp passed to ALU Control unit
);

    assign reg_dst = (opcode == 6'b000000)? 1 : 0;
    assign jump = (opcode == 6'b000010)? 1 : 0;
    assign alu_src = (opcode == 6'b100011 || opcode == 6'b101011 || opcode == 6'b001111 || opcode == 6'b001101 || opcode == 6'b001000)? 1 : 0; 
    assign mem_to_reg = (opcode == 6'b100011) ? 1 : 0;
    assign reg_write = (opcode == 6'b000000 || opcode == 6'b100011 || opcode == 6'b001111 || opcode == 6'b001101 || opcode == 6'b001000)? 1 : 0;
    assign mem_read = (opcode == 6'b100011)? 1 : 0;
    assign mem_write = (opcode == 6'b101011)? 1 : 0;
    assign branch = (opcode == 6'b000100)? 1 : 0;
    assign alu_op = (opcode == 6'b100011 || opcode == 6'b101011 || opcode == 6'b001000)? 2'b00 : (opcode == 6'b000100)? 2'b01 : 2'b10;

endmodule