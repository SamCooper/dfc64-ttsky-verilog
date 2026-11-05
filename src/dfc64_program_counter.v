module dfc64_program_counter (
    input             clk,
    input             rst_n,   // reset_n - low to reset
    input      [1:0]  pc_op,
    input             sr_c,
    input             sr_n,
    input             sr_v,
    input             sr_z,
    input             is_nmi,
    input             brn_op,
    input      [2:0]  jmp_op,
    input      [15:0] pc_input,
    output reg [15:0] pc_output
);
    localparam PC_OP_INC = 2'b01;
    localparam PC_OP_DEC = 2'b10;
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

    wire [15:0] jmp_vec = is_nmi ? 16'hFFFA : 16'hFFFE;

    always @ (posedge clk) begin
        if (!rst_n) begin
            pc_output <= 16'hFFFC;
            `ifdef SIM
                $display("%0t PC %h!", $realtime, pc_output);
            `endif
        end
        else begin
            case (pc_op)
                PC_OP_INC: begin
                    `ifdef SIM
                        $display("%0t PC INC to %h!", $realtime, (pc_output + 1));
                    `endif
                    pc_output <= pc_output + 1;
                end
                PC_OP_DEC: begin
                    `ifdef SIM
                        $display("%0t PC DEC to %h!", $realtime, (pc_output - 1));
                    `endif
                    pc_output <= pc_output - 1;
                end
                PC_OP_BRN: begin
                    if (brn_op) begin
                        `ifdef SIM
                            $display("%0t PC BRN (%b) %b %h to %h!", $realtime, jmp_op, sr_c, b_mux, (pc_output + b_mux));
                        `endif
                        pc_output <= pc_output + b_mux;
                    end else begin
                        if (jmp_op == 3'b000 && pc_output != jmp_vec) begin
                            `ifdef SIM
                                $display("%0t PC SET BRK! %h %h", $realtime, pc_output, pc_input);
                            `endif
                            pc_output <= jmp_vec;
                        end else begin
                            `ifdef SIM
                                $display("%0t PC JMP to %h!", $realtime, pc_input);
                            `endif
                            pc_output <= pc_input;
                        end
                    end
                end
                default: ;
            endcase
        end
    end
endmodule
