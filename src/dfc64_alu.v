module dfc64_alu (
    input  wire        clk,
    input  wire        rst_n,

    input set_addr_c,
    input [7:0] src_data1,
    input [7:0] src_data2,
    output reg [7:0] result_data
);
    reg bit_addr_c;

    assign result_data = src_data1 + src_data2 + (set_addr_c ? bit_addr_c : 0);

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_addr_c <= 0;
        else begin
            bit_addr_c <= ((src_data1 + src_data2) < src_data1) ? 1 : 0;
            $display("%0t ADDR C REG set %b!", $realtime, bit_addr_c);
        end
    end

endmodule