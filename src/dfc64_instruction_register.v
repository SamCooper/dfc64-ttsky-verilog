module dfc64_instruction_register (
    input [7:0] input_byte,
    input rst_n,
    input set_ir,
    input set_drl,
    input set_drh,
    output reg [23:0] instruction
);
    always @(*) begin
        if (!rst_n)
            instruction[7:0] = OP_JMP_ABS; 
        else if (set_ir == 1) begin
            $display("IR read %h!", input_byte);
            instruction[7:0] = input_byte;
        end
        else if (set_drl == 1) begin
            $display("IR DL read %h!", input_byte);
            instruction[15:8] = input_byte;
        end
        else if (set_drh == 1) begin
            $display("IR DH read %h!", input_byte);
            instruction[23:16] = input_byte;
        end
    end
endmodule