module dfc64_alu (
    input [7:0] src_data1,
    input [7:0] src_data2,
    output reg [7:0] result_data
);
    assign result_data = src_data1;
endmodule