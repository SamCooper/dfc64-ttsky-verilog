module dfc64_sr (
    input            clk,
    input            rst_n,   // reset_n - low to reset

    input  wire      flags_opcode, // 0 = Update individual flags, 1 = Overwrite all
    input  wire      ctl_carry,
    input  wire      ctl_nz,

    // Data Inputs
    input  wire [7:0]  opcode_in,     
    input  wire [7:0]  full_word_in,     // From standard data bus (e.g., for POP instruction)
    input  wire        alu_carry_in,    // From ALU
    input  wire        alu_negative_in, // From ALU
    input  wire        alu_overflow_in, // From ALU
    input  wire        alu_zero_in,     // From ALU
    
    // Output
    output reg  [7:0] status_out
);
    localparam FLAG_N = 7;	// Negative
    localparam FLAG_V = 6;	// Overflow
    localparam FLAG_B = 4;	// Break
    localparam FLAG_D = 3;	// Decimal (use BCD for arithmetics)
    localparam FLAG_I = 2;	// Interrupt (IRQ disable)
    localparam FLAG_Z = 1;	// Zero
    localparam FLAG_C = 0;	// Carry   

    wire [3:0] is_v_op;
    assign is_v_op[1:0] = opcode_in[1:0];
    assign is_v_op[3:2] = opcode_in[6:5];

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_out <= 8'h0;
        end else begin
            status_out[5] <= 1;
            status_out[FLAG_B] <= 1;

            if (flags_opcode) begin
                case (opcode_in)
                    OP_CLC_IMP: status_out[FLAG_C] <= 0;
                    OP_CLD_IMP: status_out[FLAG_D] <= 0;
                    OP_CLI_IMP: status_out[FLAG_I] <= 0;
                    OP_CLV_IMP: status_out[FLAG_V] <= 0;
                    OP_SEC_IMP: status_out[FLAG_C] <= 1;
                    OP_SED_IMP: status_out[FLAG_D] <= 1;
                    OP_SEI_IMP: status_out[FLAG_I] <= 1;
                    OP_PLP_IMP: begin
                        `ifdef SIM
                            $display("%0t SR full set %h!", $realtime, full_word_in);
                        `endif
                        status_out <= full_word_in;                
                        status_out[5] <= 1;
                        status_out[4] <= 1;
                    end
                endcase
            end else begin
                if (ctl_carry == 1) status_out[FLAG_C] <= alu_carry_in;

                if (ctl_nz == 1) begin
                    `ifdef SIM
                        $display("%0t SR set C%b Z%b N%b V%b!", $realtime, alu_carry_in, alu_zero_in, alu_negative_in, alu_overflow_in);
                    `endif

                    // need to handle V case of ADC and SBC
                    if (is_v_op == 4'b1101) begin
                        `ifdef SIM
                            $display("%0t SR set V opcode %b V%b!", $realtime, opcode_in, alu_overflow_in);
                        `endif
                        status_out[FLAG_V] <= alu_overflow_in;
                    end

                    status_out[FLAG_N] <= alu_negative_in;
                    status_out[FLAG_Z] <= alu_zero_in;
                end
            end
        end
    end
endmodule