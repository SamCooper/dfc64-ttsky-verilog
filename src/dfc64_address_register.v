module dfc64_address_register (
    input [7:0] input_byte,
    input set_low,
    input set_hi,
    output reg [16:0] address
);
    always @(*) begin
        if (set_low == 1)
            address[7:0] = input_byte;
        else if (set_high == 1)
            address[15:8] = input_byte;
    end
endmodule