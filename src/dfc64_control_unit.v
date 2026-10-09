module dfc64_control_unit (
    input clk,     // clock
    input rst_n,   // reset_n - low to reset
    input [23:0] ir,
    input [7:0]  mem_in,   // byte on the data bus (opcode being fetched)
    output reg pc_jmp,
    output reg pc_inc,

    output        mem_write_en,
    output        mem_read_en,
    output        write_en,
    output [3:0]  read_reg_sel1,
    output [3:0]  read_reg_sel2,
    output [3:0]  write_reg_sel
);
    // =========================================================================
    // 1. PARAMETERS & DEFINITIONS
    // =========================================================================
    localparam MICRO_ROM_WORD_SIZE = 20;
    
    // Micro-Jump (uJump) Commands for the Sequencer
    localparam UJMP_STEP       = 3'b000; // micro_pc = micro_pc + 1
    localparam UJMP_DISPATCH_1 = 3'b001; // micro_pc = opcode_mapper(opcode)
    localparam UJMP_DISPATCH_2 = 3'b010; // micro_pc = opcode_mapper(opcode)
    localparam UJMP_DISPATCH_3 = 3'b011; // micro_pc = opcode_mapper(opcode)
    localparam UJMP_FETCH      = 3'b111; // micro_pc = 0x00 (Start over)

    reg [7:0] micro_pc;
    reg [7:0] dispatch_address;

    // =========================================================================
    // 2. THE MICROCODE ROM
    // =========================================================================
    
    // The ROM: 256 addresses, each holding a 7-bit micro-word.
    // Word Format: [6:5] uJump | [4] reg_write | [3] mem_read | [2] mem_write | [1:0] alu_op
    reg [MICRO_ROM_WORD_SIZE-1:0] micro_rom [0:255];

    localparam RESET_MICRO_PC  = 8'h03;

    initial begin
        micro_pc = 8'h0;
        // --- 0x00: INSTRUCTION FETCH ROUTINE ---
        // Every CPU cycle starts here. We read RAM, increment PC, and decode.
    // assign pc_inc        = current_micro_word[16];
    // assign pc_jmp        = current_micro_word[15];
    // assign write_en      = current_micro_word[14];
    // assign mem_read_en   = current_micro_word[13];
    // assign mem_write_en  = current_micro_word[12];
    // assign read_reg_sel1 = current_micro_word[11:8];
    // assign read_reg_sel2 = current_micro_word[7:4];
    // assign write_reg_sel = current_micro_word[3:0];
        // Address 0x00: Read RAM into Instruction Register (IR)
        micro_rom[8'h00] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h01] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h02] = {UJMP_DISPATCH_1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR};
        micro_rom[8'h03] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h04] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h05] = {UJMP_DISPATCH_2, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h06] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h07] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h08] = {UJMP_DISPATCH_3, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};

        // OP_JMP
        micro_rom[8'h10] = {UJMP_FETCH,      1'b0, 1'b1, 1'b0, 1'b0, 1'b0,       4'b0, 4'b0, 4'b0};
        
        // These currently read mem into IR_L and then into register, could save a cycle by loading direct into mem
        // OP_LDA IMM
        micro_rom[8'h11] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_A};
        // OP_LDX IMM
        micro_rom[8'h12] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_X};
        // OP_LDY IMM
        micro_rom[8'h13] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_Y};
        
        // OP_LDA ZP
        micro_rom[8'h14] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h15] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h16] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};        
        // OP_LDX ZP
        micro_rom[8'h17] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h18] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h19] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};        
        // OP_LDY ZP
        micro_rom[8'h1a] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h1b] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h1c] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_LDA ZP_X
        micro_rom[8'h1d] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_X, REG_ALE};
        micro_rom[8'h1e] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h1f] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};        
        // OP_LDX ZP_Y
        micro_rom[8'h20] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_Y, REG_ALE};
        micro_rom[8'h21] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h22] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        // OP_LDY ZP_X
        micro_rom[8'h23] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_X, REG_ALE};
        micro_rom[8'h24] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h25] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_LDA ABS
        micro_rom[8'h30] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h31] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h32] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};        
        // OP_LDX ABS
        micro_rom[8'h33] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h34] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h35] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        // OP_LDY ABS
        micro_rom[8'h36] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h37] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h38] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_LDA ABS_X
        micro_rom[8'h39] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_X, REG_ALE};
        micro_rom[8'h3a] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h3b] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};        
        // OP_LDA ABS_Y
        micro_rom[8'h3c] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_Y, REG_ALE};
        micro_rom[8'h3d] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h3e] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};        
        // OP_LDX ABS_Y
        micro_rom[8'h3f] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_Y, REG_ALE};
        micro_rom[8'h40] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h41] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        // OP_LDY ABS_X
        micro_rom[8'h42] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_X, REG_ALE};
        micro_rom[8'h43] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h44] = {UJMP_FETCH,      1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_STA_ZP
        micro_rom[8'h49] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h4a] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h4b] = {UJMP_FETCH,      1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_A,   4'b0, REG_MEM};
        // OP_STX_ZP
        micro_rom[8'h4c] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h4d] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h4e] = {UJMP_FETCH,      1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_X,   4'b0, REG_MEM};
        // OP_STY_ZP
        micro_rom[8'h4f] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h50] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h51] = {UJMP_FETCH,      1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_Y,   4'b0, REG_MEM};
        
        // OP_STA ABS
        micro_rom[8'h52] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h53] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h54] = {UJMP_FETCH,      1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_A,   4'b0, REG_MEM};
        // OP_STX ABS
        micro_rom[8'h55] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h56] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h57] = {UJMP_FETCH,      1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_X,   4'b0, REG_MEM};
        // OP_STY ABS
        micro_rom[8'h58] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h59] = {UJMP_STEP,       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h5a] = {UJMP_FETCH,      1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_Y,   4'b0, REG_MEM};
    end

    // =========================================================================
    // 3. THE OPCODE MAPPER (Combinational)
    // =========================================================================
    wire [7:0] op = (micro_pc == 8'h02) ? mem_in : ir[7:0]; // Opcode being fetched (not yet in IR)
    
   // 0 Extra Bytes: BRK/RTI/RTS, or ends in 8 or A
    wire needs_zero_extra = (op == 8'h00) || (op == 8'h40) || (op == 8'h60) || 
                            ({op[3], op[2], op[0]} == 3'b100);

    // 2 Extra Bytes: JSR (0x20), or ends in 9, C, D, or E
    wire needs_two_extra = (op == 8'h20) || 
                        ((op[3:0] == 4'h9) && (op[4] == 1'b1)) || 
                        (op[3:2] == 2'b11);

    // Default to 1 Extra Byte
    wire needs_one_extra = !(needs_two_extra || needs_zero_extra);

    always @(*) begin
        if (needs_zero_extra) begin
            case (op)
                // If unknown opcode, route to an error handler or back to fetch
                default: begin
                    dispatch_address = 8'h00; 
                end
            endcase
        end else begin
            if (needs_one_extra) begin
                case (op)
                    OP_LDA_IMM: dispatch_address = 8'h11;
                    OP_LDX_IMM: dispatch_address = 8'h12;
                    OP_LDY_IMM: dispatch_address = 8'h13;
                    OP_LDA_ZP: dispatch_address = 8'h14;
                    OP_LDX_ZP: dispatch_address = 8'h17;
                    OP_LDY_ZP: dispatch_address = 8'h1a;
                    OP_LDA_ZP_X: dispatch_address = 8'h1d;
                    OP_LDX_ZP_Y: dispatch_address = 8'h20;
                    OP_LDY_ZP_X: dispatch_address = 8'h23;
                    OP_STA_ZP:  dispatch_address = 8'h49;
                    OP_STX_ZP:  dispatch_address = 8'h4c;
                    OP_STY_ZP:  dispatch_address = 8'h4f;
                    
                    // If unknown opcode, route to an error handler or back to fetch
                    default: begin
                        dispatch_address = 8'h00; 
                    end
                endcase
            end else begin
                case (op)
                    OP_JMP_ABS: dispatch_address = 8'h10;
                    OP_LDA_ABS: dispatch_address = 8'h30;
                    OP_LDX_ABS: dispatch_address = 8'h33;
                    OP_LDY_ABS: dispatch_address = 8'h36;
                    OP_LDA_ABS_X: dispatch_address = 8'h39;
                    OP_LDA_ABS_Y: dispatch_address = 8'h3c;
                    OP_LDX_ABS_Y: dispatch_address = 8'h3f;
                    OP_LDY_ABS_X: dispatch_address = 8'h42;
                    OP_STA_ABS: dispatch_address = 8'h52;
                    OP_STX_ABS: dispatch_address = 8'h55;
                    OP_STY_ABS: dispatch_address = 8'h58;
                    
                    // If unknown opcode, route to an error handler or back to fetch
                    default: begin
                        dispatch_address = 8'h00; 
                    end
                endcase
            end
        end
    end

    // =========================================================================
    // 4. THE MICRO-SEQUENCER (Clocked)
    // =========================================================================
    // Read the current micro-word out of the ROM
    wire [MICRO_ROM_WORD_SIZE-1:0] current_micro_word = micro_rom[micro_pc];
    
    // Extract the uJump command from the top 3 bits
    wire [2:0] uJump = current_micro_word[MICRO_ROM_WORD_SIZE-1:MICRO_ROM_WORD_SIZE-3];

    always @(posedge clk) begin
        if (!rst_n) begin
            $display("%0t Reset!", $realtime);
            micro_pc <= RESET_MICRO_PC; // On power-up, start at the Fetch Routine
        end else begin
            $display("%0t Stage: %b %b %h %h %h", $realtime, current_micro_word, uJump, micro_pc, op, dispatch_address);
            case (uJump)
                UJMP_STEP:     micro_pc <= micro_pc + 1;
                UJMP_DISPATCH_1: begin
                    micro_pc <= (needs_zero_extra) ? dispatch_address : micro_pc + 1;
                end
                UJMP_DISPATCH_2: begin
                    micro_pc <= (needs_one_extra) ? dispatch_address : micro_pc + 1;
                end
                UJMP_DISPATCH_3: begin
                    micro_pc <= (needs_two_extra) ? dispatch_address : micro_pc + 1;
                end
                UJMP_FETCH:    micro_pc <= 8'h00;
                default:       micro_pc <= 8'h00;
            endcase
        end
    end

    // =========================================================================
    // 5. OUTPUT LOGIC (Combinational slicing)
    // =========================================================================
    assign pc_inc        = current_micro_word[16];
    assign pc_jmp        = current_micro_word[15];
    assign write_en      = current_micro_word[14];
    assign mem_read_en   = current_micro_word[13];
    assign mem_write_en  = current_micro_word[12];
    assign read_reg_sel1 = current_micro_word[11:8];
    assign read_reg_sel2 = current_micro_word[7:4];
    assign write_reg_sel = current_micro_word[3:0];

endmodule
