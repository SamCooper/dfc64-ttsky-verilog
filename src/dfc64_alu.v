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

    reg bit_addr_c;

    wire is_sub = (alu_op == ALU_OP_SBC);
    wire [7:0] b_mux = is_sub ? ~src_data2 : src_data2;

    wire local_carry;
    wire [7:0] add_sub_result;
    assign {local_carry, add_sub_result} = src_data1 + b_mux + carry_in;


    always @(*) begin
        case (alu_op)
            ALU_OP_ADD: result_data = src_data1 + src_data2 + (set_addr_c ? bit_addr_c : 0);
            ALU_OP_SUB: result_data = src_data1 - src_data2;
            ALU_OP_ADC: begin
                result_data = add_sub_result;
                alu_carry = local_carry;
            end
            ALU_OP_SBC: begin
                result_data = add_sub_result;
                alu_carry = local_carry;
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
            bit_addr_c <= 0;
        else begin
            if (!set_addr_c) 
                bit_addr_c <= ((src_data1 + src_data2) < src_data1) ? 1 : 0;
            $display("%0t ADDR C REG set %b %h %h!", $realtime, bit_addr_c, src_data1, src_data2);
        end
    end

endmodule