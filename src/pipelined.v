`timescale 1ns / 1ps

module pipelined #(
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
) (
    input clk,  // clock
    input rstn  // negative reset
);

    /* Instruction Memory */
    wire [31:0] instr_mem_address, instr_mem_instr;
    instr_mem #(
        .BYTES(TEXT_BYTES),
        .START(TEXT_START)
    ) instr_mem (
        .address(instr_mem_address),
        .instr  (instr_mem_instr)
    );

    /* Register Rile */
    wire [4:0] reg_file_read_reg_1, reg_file_read_reg_2, reg_file_write_reg;
    wire reg_file_reg_write;
    wire [31:0] reg_file_write_data, reg_file_read_data_1, reg_file_read_data_2;
    reg_file reg_file (
        .clk        (~clk),                  // only write when negative edge
        .rstn       (rstn),
        .read_reg_1 (reg_file_read_reg_1),
        .read_reg_2 (reg_file_read_reg_2),
        .reg_write  (reg_file_reg_write),
        .write_reg  (reg_file_write_reg),
        .write_data (reg_file_write_data),
        .read_data_1(reg_file_read_data_1),
        .read_data_2(reg_file_read_data_2)
    );

    /* ALU */
    wire [31:0] alu_a, alu_b, alu_pre_b, alu_result;
    wire [3:0] alu_ALU_ctl;
    wire alu_zero, alu_overflow;
    alu alu (
        .a       (alu_a),
        .b       (alu_b),
        .ALU_ctl (alu_ALU_ctl),
        .result  (alu_result),
        .zero    (alu_zero),
        .overflow(alu_overflow)
    );

    /* Data Memory */
    wire data_mem_mem_read, data_mem_mem_write;
    wire [31:0] data_mem_address, data_mem_write_data, data_mem_read_data;
    data_mem #(
        .BYTES(DATA_BYTES),
        .START(DATA_START)
    ) data_mem (
        .clk       (~clk),                 // only write when negative edge
        .mem_read  (data_mem_mem_read),
        .mem_write (data_mem_mem_write),
        .address   (data_mem_address),
        .write_data(data_mem_write_data),
        .read_data (data_mem_read_data)
    );

    /* ALU Control */
    wire [1:0] alu_control_alu_op;
    wire [5:0] alu_control_funct;
    wire [3:0] alu_control_operation;
    alu_control alu_control (
        .alu_op   (alu_control_alu_op),
        .funct    (alu_control_funct),
        .operation(alu_control_operation)
    );

    /* (Main) Control */
    wire [5:0] control_opcode;
    // Execution/address calculation stage control lines
    wire control_reg_dst, control_alu_src;
    wire [1:0] control_alu_op;
    // Memory access stage control lines
    wire control_branch, control_mem_read, control_mem_write;
    // Wire-back stage control lines
    wire control_reg_write, control_mem_to_reg;
    control control (
        .opcode    (control_opcode),
        .reg_dst   (control_reg_dst),
        .alu_src   (control_alu_src),
        .mem_to_reg(control_mem_to_reg),
        .reg_write (control_reg_write),
        .mem_read  (control_mem_read),
        .mem_write (control_mem_write),
        .branch    (control_branch),
        .alu_op    (control_alu_op)
    );

    wire [1:0] forward_A, forward_B;
    forwarding forwarding (
        .ID_EX_rs        (ID_EX_rs),
        .ID_EX_rt        (ID_EX_rt),
        .EX_MEM_reg_write(EX_MEM_WB[0]),
        .EX_MEM_rd       (EX_MEM_rd),
        .MEM_WB_reg_write(MEM_WB_WB[0]),
        .MEM_WB_rd       (MEM_WB_rd),
        .forward_A       (forward_A),
        .forward_B       (forward_B)
    );

    wire [1:0] forward_C, forward_D;
    forwarding forwarding2 (
        .ID_EX_rs        (reg_file_read_reg_1),
        .ID_EX_rt        (reg_file_read_reg_2),
        .EX_MEM_reg_write(EX_MEM_WB[0]),
        .EX_MEM_rd       (EX_MEM_rd),
        .MEM_WB_reg_write(MEM_WB_WB[0]),
        .MEM_WB_rd       (MEM_WB_rd),
        .forward_A       (forward_C),
        .forward_B       (forward_D)
    );

    wire pc_write, IF_ID_write, stall;
    hazard_detection hazard_detection (
        .opcode             (IF_ID_instr[31:26]),
        .ID_EX_mem_read     (ID_EX_MEM[0]),
        .ID_EX_reg_write    (ID_EX_WB[0]),
        .EX_MEM_mem_read    (EX_MEM_MEM[0]),
        .ID_EX_rt           (ID_EX_rt),
        .ID_EX_rd           (write_reg), // need to observe
        .IF_ID_rs           (IF_ID_instr[25:21]),
        .IF_ID_rt           (IF_ID_instr[20:16]),
        .EX_MEM_rt          (EX_MEM_rt),
        .pc_write           (pc_write),           
        .IF_ID_write        (IF_ID_write),         
        .stall              (stall)               
    );

    reg [31:0] pc;  
    assign instr_mem_address = pc;
    wire [31:0] pc_4;
    assign pc_4 = pc+4;
    reg [31:0] IF_ID_instr, IF_ID_pc_4;
    always @(posedge clk)
        if (rstn) begin
            IF_ID_instr <= (IF_ID_write == 0)? IF_ID_instr : instr_mem_instr;  // a.
            IF_ID_pc_4  <= (IF_ID_write == 0)? IF_ID_pc_4 : pc_4;  // b. 
        end
    always @(negedge rstn) begin
        IF_ID_instr <= 0;  // a.
        IF_ID_pc_4  <= 0;  // b.
    end

    assign control_opcode = IF_ID_instr[31:26];

    assign reg_file_read_reg_1 = IF_ID_instr[25:21];
    assign reg_file_read_reg_2 = IF_ID_instr[20:16];

    wire [31:0] sign_extend_addr;
    assign sign_extend_addr = {{16{IF_ID_instr[15]}}, IF_ID_instr[15:0]};

    reg [1:0] ID_EX_WB;
    reg [2:0] ID_EX_MEM;
    reg [3:0] ID_EX_EX;
    reg [31:0] ID_EX_pc_4, ID_EX_read_data_1, ID_EX_read_data_2, ID_EX_sign_extend_addr;
    reg [4:0] ID_EX_rs, ID_EX_rt, ID_EX_rd;
    wire [31:0] branch_addr, branch_rs, branch_rt;
    wire branch_zero, pc_src;
    assign branch_addr = {sign_extend_addr[29:0], 2'b0} + IF_ID_pc_4;
    assign branch_rs = (forward_C[1] == 0)? reg_file_read_data_1 : EX_MEM_alu_result;
    assign branch_rt = (forward_D[1] == 0)? reg_file_read_data_2 : EX_MEM_alu_result;
    assign branch_zero = (branch_rs == branch_rt)? 1 : 0;
    assign pc_src = (control_branch == 1 && branch_zero == 1)? 1 : 0;
    always @(posedge clk)
        if (rstn) begin
            ID_EX_WB <= (stall == 1)? 2'b0 : {control_mem_to_reg, control_reg_write};
            ID_EX_MEM <= (stall == 1)? 3'b0 : {control_branch, control_mem_write, control_mem_read};
            ID_EX_EX <= (stall == 1)? 4'b0 : {control_alu_op, control_alu_src, control_reg_dst};

            ID_EX_pc_4 <= IF_ID_pc_4;

            ID_EX_read_data_1 <= reg_file_read_data_1;
            ID_EX_read_data_2 <= reg_file_read_data_2;

            ID_EX_sign_extend_addr <= sign_extend_addr;

            ID_EX_rs <= IF_ID_instr[25:21];
            ID_EX_rt <= IF_ID_instr[20:16];
            ID_EX_rd <= IF_ID_instr[15:11];

            pc <= (pc_write == 0)? pc : (pc_src == 1)? branch_addr : pc_4;  // 5.  
        end
    always @(negedge rstn) begin
        ID_EX_WB <= 2'b0;
        ID_EX_MEM <= 3'b0;
        ID_EX_EX <= 4'b0;

        ID_EX_pc_4 <= 32'b0;

        ID_EX_read_data_1 <= 32'b0;
        ID_EX_read_data_2 <= 32'b0;

        ID_EX_sign_extend_addr <= 32'b0;

        ID_EX_rs <= 5'b0;
        ID_EX_rt <= 5'b0;
        ID_EX_rd <= 5'b0;

        pc <= 32'h00400000;
    end

    assign alu_a = (forward_A == 2'b00)? ID_EX_read_data_1 : (forward_A == 2'b10)? EX_MEM_alu_result : (MEM_WB_WB[1] == 1)? MEM_WB_read_data : MEM_WB_alu_result;  // forward 1st operand
    assign alu_pre_b = (forward_B == 2'b00)? ID_EX_read_data_2 : (forward_B == 2'b10)? EX_MEM_alu_result : (MEM_WB_WB[1] == 1)? MEM_WB_read_data : MEM_WB_alu_result;
    assign alu_b = (ID_EX_EX[1] == 1)? ID_EX_sign_extend_addr : alu_pre_b;  // forward 2nd operand

    assign alu_control_alu_op = ID_EX_EX[3:2];
    assign alu_control_funct = ID_EX_sign_extend_addr[5:0];
    assign alu_ALU_ctl = alu_control_operation;

    wire [5:0] write_reg;
    assign write_reg = (ID_EX_EX[0] == 1)? ID_EX_rd : ID_EX_rt;
    
    reg [1:0] EX_MEM_WB;
    reg [2:0] EX_MEM_MEM;
    reg [31:0] EX_MEM_alu_result, EX_MEM_read_data_2;
    reg EX_MEM_zero;
    reg [4:0] EX_MEM_rs, EX_MEM_rt, EX_MEM_rd;
    always @(posedge clk)
        if (rstn) begin
            EX_MEM_WB <= ID_EX_WB;
            EX_MEM_MEM <= ID_EX_MEM;
            EX_MEM_zero <= alu_zero;
            EX_MEM_alu_result <= alu_result;
            EX_MEM_read_data_2 <= (forward_B == 2'b00)? ID_EX_read_data_2 : (forward_B == 2'b10)? EX_MEM_alu_result : (MEM_WB_WB[1] == 1)? MEM_WB_read_data : MEM_WB_alu_result;
            EX_MEM_rs <= ID_EX_rs;
            EX_MEM_rt <= ID_EX_rt;
            EX_MEM_rd <= write_reg;
        end
    always @(negedge rstn) begin
        EX_MEM_WB <= 2'b0;
        EX_MEM_MEM <= 3'b0;
        EX_MEM_zero <= 1'b0;
        EX_MEM_alu_result <= 32'b0;
        EX_MEM_read_data_2 <= 32'b0;
        EX_MEM_rs <= 5'b0;
        EX_MEM_rt <= 5'b0;
        EX_MEM_rd <= 5'b0;
    end

    assign data_mem_address = EX_MEM_alu_result;
    assign data_mem_write_data = EX_MEM_read_data_2;
    assign data_mem_mem_read = EX_MEM_MEM[0];
    assign data_mem_mem_write = EX_MEM_MEM[1];

    reg [1:0] MEM_WB_WB;
    reg [31:0] MEM_WB_read_data, MEM_WB_alu_result;
    reg [4:0] MEM_WB_rd;
    always @(posedge clk)
        if (rstn) begin
            MEM_WB_WB <= EX_MEM_WB;  
            MEM_WB_read_data <= data_mem_read_data;
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_rd <= EX_MEM_rd;
        end
    always @(negedge rstn) begin
        MEM_WB_WB <= 2'b0;
        MEM_WB_read_data <= 32'b0;
        MEM_WB_alu_result <= 32'b0;
        MEM_WB_rd <= 5'b0;
    end

    assign reg_file_reg_write = (MEM_WB_rd == 5'b0)? 0 : MEM_WB_WB[0];
    assign reg_file_write_data = (MEM_WB_WB[1] == 1)? MEM_WB_read_data : MEM_WB_alu_result;
    assign reg_file_write_reg = MEM_WB_rd;

endmodule  
