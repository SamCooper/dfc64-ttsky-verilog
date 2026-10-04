module dfc64_program_counter (
    output reg [15:0] pc_output,
    input      [15:0] pc_input,
    input             rst_n,   // reset_n - low to reset
    input             jmp,     // store pci
    input             inc     // inc pc
);
    always @ (posedge jmp or posedge inc or negedge rst_n) begin
            if (!rst_n)
                pc_output <= 16'hFFFC;
            else begin
                if (jmp == 1) begin
                    $display("JMP to %h!", pc_input);
                    pc_output <= pc_input;
                end
                else if (inc == 1)
                    pc_output <= pc_output + 1;
            end
    end

endmodule
