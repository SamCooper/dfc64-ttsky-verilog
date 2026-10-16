module dfc64_program_counter (
    input             clk,
    output reg [15:0] pc_output,
    input      [15:0] pc_input,
    input             rst_n,   // reset_n - low to reset
    input             jmp,     // load pc_input on next clk edge
    input             inc      // increment pc on next clk edge
);
    always @ (posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                pc_output <= 16'hFFFC;
                $display("%0t PC %h!", $realtime, pc_output);
            end
            else begin
                if (jmp == 1) begin
                    $display("%0t JMP to %h!", $realtime, pc_input);
                    pc_output <= pc_input;
                end
                else if (inc == 1) begin
                    $display("%0t INC to %h!", $realtime, (pc_output + 1));
                    pc_output <= pc_output + 1;
                end
            end
    end

endmodule
