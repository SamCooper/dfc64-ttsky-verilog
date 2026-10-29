module dfc64_program_counter (
    input             clk,
    input             rst_n,   // reset_n - low to reset
    input      [1:0]  pc_op,
    input             sr_c,
    input             sr_n,
    input             sr_v,
    input             sr_z,
    input      [2:0]  jmp_op,
    input      [15:0] pc_input,
    output reg [15:0] pc_output
);
    localparam PC_OP_INC = 2'b01;
    localparam PC_OP_JMP = 2'b10;
    localparam PC_OP_BRN = 2'b11;

    reg [15:0] b_mux;

    always @(*) begin
        case (jmp_op)
            3'b000: b_mux = sr_n ? 16'b0 : {{8{pc_input[7]}}, pc_input[7:0]};
            3'b001: b_mux = sr_n ? {{8{pc_input[7]}}, pc_input[7:0]} : 16'b0;
            3'b010: b_mux = sr_v ? 16'b0 : {{8{pc_input[7]}}, pc_input[7:0]};
            3'b011: b_mux = sr_v ? {{8{pc_input[7]}}, pc_input[7:0]} : 16'b0;
            3'b100: b_mux = sr_c ? 16'b0 : {{8{pc_input[7]}}, pc_input[7:0]};
            3'b101: b_mux = sr_c ? {{8{pc_input[7]}}, pc_input[7:0]} : 16'b0;
            3'b110: b_mux = sr_z ? 16'b0 : {{8{pc_input[7]}}, pc_input[7:0]};
            3'b111: b_mux = sr_z ? {{8{pc_input[7]}}, pc_input[7:0]} : 16'b0;
        endcase
    end


    always @ (posedge clk) begin
        if (!rst_n) begin
            pc_output <= 16'hFFFC;
            `ifdef SIM
                $display("%0t PC %h!", $realtime, pc_output);
            `endif
        end
        else begin
            case (pc_op)
                PC_OP_JMP: begin
                    `ifdef SIM
                        $display("%0t JMP to %h!", $realtime, pc_input);
                    `endif
                    pc_output <= pc_input;
                end
                PC_OP_INC: begin
                    `ifdef SIM
                        $display("%0t INC to %h!", $realtime, (pc_output + 1));
                    `endif
                    pc_output <= pc_output + 1;
                end
                PC_OP_BRN: begin
                    `ifdef SIM
                        $display("%0t BRN (%b) %b %h to %h!", $realtime, jmp_op, sr_c, b_mux, (pc_output + b_mux));
                    `endif
                    pc_output <= pc_output + b_mux;
                end
                default: ;
            endcase
        end
    end
endmodule
