`timescale 1ns / 1ps

module msb_bit_alu (
    input        a,          // 1 bit, a
    input        b,          // 1 bit, b
    input        less,       // 1 bit, Less
    input        a_invert,   // 1 bit, Ainvert
    input        b_invert,   // 1 bit, Binvert
    input        carry_in,   // 1 bit, CarryIn
    input  [1:0] operation,  // 2 bit, Operation
    output reg   result,     // 1 bit, Result (Must it be a reg?)
    output       set,        // 1 bit, Set
    output       overflow    // 1 bit, Overflow
);
    wire ai, bi; 
    assign ai = (a_invert == 0) ? a : !a;
    assign bi = (!b & b_invert) | (b & !b_invert); 

    wire sum, carry_out;
    assign carry_out = (ai & bi) | (ai & carry_in) | (bi & carry_in);
    assign overflow  = (operation == 2'b10) ? carry_in ^ carry_out : 0;
    assign sum       = (ai & (!bi) & (!carry_in)) | ((!ai) & (bi) & (!carry_in)) | ((!ai) & (!bi) & (carry_in)) | (ai & bi & carry_in);
    assign set       = (a == 1 & b == 0)? 1 : ( a == 0 & b == 1)? 0 : sum;
    
    always @(*) begin  
        case (operation) 
            2'b00:   result <= ai & bi;  // AND
            2'b01:   result <= ai | bi;  // OR
            2'b10:   result <= sum;  // ADD
            2'b11:   result <= less;  // SLT
            default: result <= 0;  // should not happened
        endcase
    end

endmodule
