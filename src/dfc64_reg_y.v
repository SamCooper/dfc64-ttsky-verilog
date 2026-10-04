module dfc64_reg_y (
    input clk,
    input rst_n,
    input input_enable,
    input [7:0] data_input,
    output reg [7:0] reg_value
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_value <= 8'b0;
        else if (input_enable == 1) 
            $display("Write Y %h!", data_input);
            reg_value <= data_input;            
    end
endmodule