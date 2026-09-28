module dfc64_program_counter (
    output reg [15:0] pc_output,
    input      [15:0] pc_input,
    input             clk,     // clock
    input             rst_n,   // reset_n - low to reset
    input             jmp,     // store pci
    input             inc,     // inc pc
    input             out      // output pc
);
    reg [15:0] pc;

    always @ (posedge clk) begin
            if (!rst_n)
                pc <= 16'hFFFC;
            else begin
                if (jmp == 1)
                    pc <= pc_input;
                else begin
                    if (inc == 1)
                        pc <= pc + 1;
                    else if (out == 1) 
                        pc_output <= pc;
                end
            end
    end

endmodule
