module dfc64_alu (
    input  wire        clk,
    input  wire        rst_n,

    input sub,
    input set_addr_c,
    
    input [7:0] src_data1,
    input [7:0] src_data2,

    output wire alu_carry,
    output wire alu_zero,
    output wire alu_negative,

    output reg [7:0] result_data
);
    reg bit_addr_c;

    assign result_data = (sub == 0) ? (src_data1 + src_data2 + (set_addr_c ? bit_addr_c : 0)) : src_data1 - src_data2;

    assign alu_carry = 0;
    assign alu_negative = result_data[7];
    assign alu_zero = (result_data == 8'b0) ? 1 : 0;

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