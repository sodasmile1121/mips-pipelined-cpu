`timescale 1ns / 1ps

module hazard_detection (
    input  [5:0] opcode,
    input        ID_EX_mem_read,
    input        ID_EX_reg_write,
    input        ID_EX_alu_src,
    input        EX_MEM_mem_read,
    input  [4:0] ID_EX_rt,
    input  [4:0] ID_EX_rd,
    input  [4:0] IF_ID_rs,
    input  [4:0] IF_ID_rt,
    input  [4:0] EX_MEM_rt,
    output       pc_write,        // only update PC when this is set
    output       IF_ID_write,     // only update IF/ID stage registers when this is set
    output       stall            // insert a stall (bubble) in ID/EX when this is set
);

    wire normal_stall = (ID_EX_mem_read == 1'b1 && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)))? 1 : 0;
    wire beq_stall = (opcode == 6'b000100 && ID_EX_reg_write == 1'b1 && ((ID_EX_mem_read == 1'b0 && ((ID_EX_rd == IF_ID_rs) || (ID_EX_rd == IF_ID_rt))) || (ID_EX_mem_read == 1'b1 && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)) )) )? 1 : 0;
    wire beq_lw_stall = (opcode == 6'b000100 && EX_MEM_mem_read == 1'b1 && ((EX_MEM_rt == IF_ID_rs) || (EX_MEM_rt == IF_ID_rt)))? 1 : 0;
    assign pc_write = (normal_stall || beq_stall || beq_lw_stall)? 0 : 1;
    assign IF_ID_write = (normal_stall || beq_stall || beq_lw_stall)? 0 : 1;
    assign stall = (normal_stall || beq_stall || beq_lw_stall)? 1 : 0;

endmodule
