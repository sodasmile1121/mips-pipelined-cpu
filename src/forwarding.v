`timescale 1ns / 1ps

module forwarding (
    input      [4:0] ID_EX_rs,         
    input      [4:0] ID_EX_rt,
    input            EX_MEM_reg_write,
    input      [4:0] EX_MEM_rd,
    input            MEM_WB_reg_write,
    input      [4:0] MEM_WB_rd,
    output reg [1:0] forward_A,       
    output reg [1:0] forward_B
);

    always @(*) begin  // `*` auto captures sensitivity ports, now it's combinational logic
        if (EX_MEM_reg_write == 1'b1 && EX_MEM_rd != 5'b0 && EX_MEM_rd == ID_EX_rs)
            forward_A = 2'b10;
        else if (MEM_WB_reg_write == 1'b1 && MEM_WB_rd != 5'b0 && MEM_WB_rd == ID_EX_rs)
            forward_A = 2'b01;
        else
            forward_A = 2'b00;
        
        if (EX_MEM_reg_write == 1'b1 && EX_MEM_rd != 5'b0 && EX_MEM_rd == ID_EX_rt)
            forward_B = 2'b10;
        else if (MEM_WB_reg_write == 1'b1 && MEM_WB_rd != 5'b0 && MEM_WB_rd == ID_EX_rt)
            forward_B = 2'b01;
        else
            forward_B = 2'b00;
    end
endmodule
