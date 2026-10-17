module dfc64_sr (
    input            clk,
    input            rst_n,   // reset_n - low to reset

    input  wire        write_enable,
    input  wire        full_write_mode, // 0 = Update individual flags, 1 = Overwrite all
    
    // Data Inputs
    input  wire [7:0] full_word_in,     // From standard data bus (e.g., for POP instruction)
    input  wire        alu_carry_in,    // From ALU
    input  wire        alu_zero_in,     // From ALU
    input  wire        alu_negative_in, // From ALU
    
    // Output
    output reg  [7:0] status_out
);
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_out <= 8'h0;
        end else if (write_enable) begin            
            if (full_write_mode) begin
                status_out <= full_word_in;                
                status_out[5] <= 1;
                status_out[4] <= 1;
                $display("%0t SR full set %h!", $realtime, full_word_in);
            end else begin
                $display("%0t SR set C%b Z%b N%b!", $realtime, alu_carry_in, alu_zero_in, alu_negative_in);
                status_out[7] <= alu_negative_in;
                status_out[5] <= 1;
                status_out[4] <= 1;
                status_out[1] <= alu_zero_in;
                //status_out[0] <= alu_carry_in;
            end            
        end
    end
endmodule