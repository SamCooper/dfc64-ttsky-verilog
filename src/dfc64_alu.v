module dfc64_alu (
    input  wire        clk,
    input  wire        rst_n,

    input [3:0] alu_op,
    input set_addr_c,
    
    input  carry_in,
    input [7:0] src_data1,
    input [7:0] src_data2,

    output reg alu_carry,
    output wire alu_negative,
    output wire alu_overflow,
    output wire alu_zero,

    output reg [7:0] result_data
);
    localparam ALU_OP_ADD = 4'b0000;
    localparam ALU_OP_SUB = 4'b0001;
    localparam ALU_OP_ADC = 4'b0010;
    localparam ALU_OP_SBC = 4'b0011;
    localparam ALU_OP_CMP = 4'b0100;
    localparam ALU_OP_AND = 4'b0101;
    localparam ALU_OP_EOR = 4'b0110;
    localparam ALU_OP_OR  = 4'b0111;
    localparam ALU_OP_ASL = 4'b1000;
    localparam ALU_OP_LSR = 4'b1001;
    localparam ALU_OP_ROL = 4'b1010;
    localparam ALU_OP_ROR = 4'b1011;

    reg bit_addr_c;

    wire is_sub = (alu_op == ALU_OP_SUB) || (alu_op == ALU_OP_SBC) || (alu_op == ALU_OP_CMP);
    wire [7:0] b_mux = is_sub ? ~src_data2 : src_data2;

    reg add_cin;
    always @(*) begin
        case (alu_op)
            ALU_OP_ADD: add_cin = set_addr_c & bit_addr_c;
            ALU_OP_SUB,
            ALU_OP_CMP: add_cin = 1'b1;
            default:    add_cin = carry_in;
        endcase
    end

    wire local_carry;
    wire [7:0] add_sub_result;
    assign {local_carry, add_sub_result} = src_data1 + b_mux + add_cin;

    always @(*) begin
        result_data = 8'b0;
        alu_carry   = 1'b0;

        case (alu_op)
            ALU_OP_ADD,
            ALU_OP_SUB: result_data = add_sub_result;
            ALU_OP_ADC,
            ALU_OP_SBC,
            ALU_OP_CMP: begin
                result_data = add_sub_result;
                alu_carry   = local_carry;
            end
            ALU_OP_AND: result_data = src_data1 & src_data2;
            ALU_OP_EOR: result_data = src_data1 ^ src_data2;
            ALU_OP_OR:  result_data = src_data1 | src_data2;
            ALU_OP_ASL: begin
                result_data[7:1] = src_data1[6:0];
                alu_carry   = src_data1[7];
            end
            ALU_OP_LSR: begin
                result_data[6:0] = src_data1[7:1];
                alu_carry   = src_data1[0];
            end
            ALU_OP_ROL: begin
                result_data[0] = carry_in;
                result_data[7:1] = src_data1[6:0];
                alu_carry   = src_data1[7];
            end
            ALU_OP_ROR: begin
                result_data[7] = carry_in;
                result_data[6:0] = src_data1[7:1];
                alu_carry   = src_data1[0];
            end
            default: result_data = 8'b0;
        endcase
    end

    wire a_sign = src_data1[7];
    wire b_sign = b_mux[7];
    wire res_sign = result_data[7];

    assign alu_negative = result_data[7];
    assign alu_overflow = (a_sign == b_sign) && (res_sign != a_sign);
    assign alu_zero = (result_data == 8'b0);

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_addr_c <= 1'b0;
        else begin
            if (alu_op == ALU_OP_ADD && !set_addr_c)
                bit_addr_c <= local_carry;
            `ifdef SIM
                $display("%0t ADDR C REG set %b %h %h!", $realtime, bit_addr_c, src_data1, src_data2);
            `endif
        end
    end

endmodule