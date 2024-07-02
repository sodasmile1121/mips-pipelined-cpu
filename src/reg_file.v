`timescale 1ns / 1ps

module reg_file (
    input         clk,          // clock
    input         rstn,         // negative reset
    input  [ 4:0] read_reg_1,   // Read Register 1 (address)
    input  [ 4:0] read_reg_2,   // Read Register 2 (address)
    input         reg_write,    // RegWrite: write data when posedge clk
    input  [ 4:0] write_reg,    // Write Register (address)
    input  [31:0] write_data,   // Write Data
    output [31:0] read_data_1,  // Read Data 1
    output [31:0] read_data_2   // Read Data 2
);

    reg [31:0] registers[0:31];  // do not change its name

    assign read_data_1 = (read_reg_1 == 5'b0) ? 0 : registers[read_reg_1];
    assign read_data_2 = (read_reg_2 == 5'b0) ? 0 : registers[read_reg_2];

    always @(posedge clk)
        if (rstn) begin  // make sure to check reset!
            if (reg_write) begin
                registers[write_reg] <= write_data;
            end
        end

    integer i;
    always @(negedge rstn) begin
        if (~rstn) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0; 
            end
        end
    end

endmodule