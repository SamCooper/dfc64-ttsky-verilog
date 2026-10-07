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
    localparam MICRO_ROM_WORD_SIZE = 19;
    
    // Micro-Jump (uJump) Commands for the Sequencer
    localparam UJMP_STEP     = 2'b00; // micro_pc = micro_pc + 1
    localparam UJMP_DISPATCH = 2'b01; // micro_pc = opcode_mapper(opcode)
    localparam UJMP_FETCH    = 2'b10; // micro_pc = 0x00 (Start over)

    // =========================================================================
    // 2. THE MICROCODE ROM
    // =========================================================================
    
    // The ROM: 256 addresses, each holding a 7-bit micro-word.
    // Word Format: [6:5] uJump | [4] reg_write | [3] mem_read | [2] mem_write | [1:0] alu_op
    reg [MICRO_ROM_WORD_SIZE-1:0] micro_rom [0:255];

    initial begin
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
        micro_rom[8'h00] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h01] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h02] = {UJMP_DISPATCH, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR};

        // OP_JMP
        micro_rom[8'h10] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h11] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h12] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h13] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h14] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h15] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'h16] = {UJMP_FETCH,    1'b0, 1'b1, 1'b0, 1'b0, 1'b0,       4'b0, 4'b0, 4'b0};
        
        // OP_LDA IMM
        micro_rom[8'h20] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h21] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h22] = {UJMP_FETCH,    1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};
        
        // OP_LDX IMM
        micro_rom[8'h23] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h24] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h25] = {UJMP_FETCH,    1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        
        // OP_LDY IMM
        micro_rom[8'h26] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h27] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h28] = {UJMP_FETCH,    1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_LDA ZP
        micro_rom[8'h30] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h31] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h32] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h33] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h34] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h35] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};
        
        // OP_LDX ZP
        micro_rom[8'h36] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h37] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h38] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h39] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h3a] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h3b] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        
        // OP_LDY ZP
        micro_rom[8'h40] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h41] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h42] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h43] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h44] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h45] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_LDA ZP_X
        micro_rom[8'h46] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h47] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h48] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h49] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_X, REG_ALE};
        micro_rom[8'h4a] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h4b] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};
        
        // OP_LDX ZP_Y
        micro_rom[8'h50] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h51] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h52] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h53] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_Y, REG_ALE};
        micro_rom[8'h54] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h55] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        
        // OP_LDY ZP_X
        micro_rom[8'h56] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h57] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h58] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h59] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, REG_X, REG_ALE};
        micro_rom[8'h5a] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h5b] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_LDA ABS
        micro_rom[8'h60] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h61] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h62] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h63] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h64] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h65] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'h66] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h67] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h68] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_A};
        
        // OP_LDX ABS
        micro_rom[8'h70] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h71] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h72] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h73] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h74] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h75] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'h76] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h77] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h78] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_X};
        
        // OP_LDY ABS
        micro_rom[8'h80] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h81] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h82] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h83] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h84] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h85] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'h86] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h87] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'h88] = {UJMP_FETCH,    1'b0, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_Y};
        
        // OP_STA_ZP
        micro_rom[8'h90] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'h91] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'h92] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'h93] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'h94] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'h95] = {UJMP_FETCH,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_A,   4'b0, REG_MEM};
        
        // OP_STX_ZP
        micro_rom[8'ha0] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'ha1] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'ha2] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'ha3] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'ha4] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'ha5] = {UJMP_FETCH,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_X,   4'b0, REG_MEM};
        
        // OP_STY_ZP
        micro_rom[8'hb0] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'hb1] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'hb2] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'hb3] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'hb4] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_ZERO, 4'b0, REG_AHE};
        micro_rom[8'hb5] = {UJMP_FETCH,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_Y,   4'b0, REG_MEM};
        
        // OP_STA ABS
        micro_rom[8'hc0] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'hc1] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'hc2] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'hc3] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'hc4] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'hc5] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'hc6] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'hc7] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'hc8] = {UJMP_FETCH,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_A,   4'b0, REG_MEM};
        
        // OP_STX ABS
        micro_rom[8'hd0] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'hd1] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'hd2] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'hd3] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'hd4] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'hd5] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'hd6] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'hd7] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'hd8] = {UJMP_FETCH,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_X,   4'b0, REG_MEM};
        
        // OP_STY ABS
        micro_rom[8'he0] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'he1] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'he2] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_L};
        micro_rom[8'he3] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCL, 4'b0, REG_ALE};
        micro_rom[8'he4] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_PCH, 4'b0, REG_AHE};
        micro_rom[8'he5] = {UJMP_STEP,     1'b1, 1'b0, 1'b1, 1'b1, 1'b0, REG_MEM, 4'b0, REG_IR_H};
        micro_rom[8'he6] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_L, 4'b0, REG_ALE};
        micro_rom[8'he7] = {UJMP_STEP,     1'b0, 1'b0, 1'b0, 1'b0, 1'b0, REG_IR_H, 4'b0, REG_AHE};
        micro_rom[8'he8] = {UJMP_FETCH,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, REG_Y,   4'b0, REG_MEM};
    end

    // =========================================================================
    // 3. THE OPCODE MAPPER (Combinational)
    // =========================================================================
    reg [7:0] dispatch_address;
    wire [7:0] op = mem_in; // Opcode being fetched (not yet in IR)
    
    always @(*) begin
        case (op)
            OP_JMP_ABS: dispatch_address = 8'h10;
            OP_LDA_IMM: dispatch_address = 8'h20;
            OP_LDX_IMM: dispatch_address = 8'h23;
            OP_LDY_IMM: dispatch_address = 8'h26;
            OP_LDA_ZP: dispatch_address = 8'h30;
            OP_LDX_ZP: dispatch_address = 8'h36;
            OP_LDY_ZP: dispatch_address = 8'h40;
            OP_LDA_ZP_X: dispatch_address = 8'h46;
            OP_LDX_ZP_Y: dispatch_address = 8'h50;
            OP_LDY_ZP_X: dispatch_address = 8'h56;
            OP_LDA_ABS: dispatch_address = 8'h60;
            OP_LDX_ABS: dispatch_address = 8'h70;
            OP_LDY_ABS: dispatch_address = 8'h80;
            OP_STA_ZP:  dispatch_address = 8'h90;
            OP_STX_ZP:  dispatch_address = 8'ha0;
            OP_STY_ZP:  dispatch_address = 8'hb0;
            OP_STA_ABS: dispatch_address = 8'hc0;
            OP_STX_ABS: dispatch_address = 8'hd0;
            OP_STY_ABS: dispatch_address = 8'he0;
            
            // If unknown opcode, route to an error handler or back to fetch
            default: begin
                dispatch_address = 8'h00; 
            end
        endcase
    end

    // =========================================================================
    // 4. THE MICRO-SEQUENCER (Clocked)
    // =========================================================================
    reg [7:0] micro_pc;
    
    // Read the current micro-word out of the ROM
    wire [MICRO_ROM_WORD_SIZE-1:0] current_micro_word = micro_rom[micro_pc];
    
    // Extract the uJump command from the top 2 bits
    wire [1:0] uJump = current_micro_word[MICRO_ROM_WORD_SIZE-1:MICRO_ROM_WORD_SIZE-2];

    always @(posedge clk) begin
        if (!rst_n) begin
            $display("%0t Reset!", $realtime);
            micro_pc <= 8'h10; // On power-up, start at the Fetch Routine
        end else begin
            $display("%0t Stage: %b %b %h %h %h", $realtime, current_micro_word, uJump, micro_pc, op, dispatch_address);
            case (uJump)
                UJMP_STEP:     micro_pc <= micro_pc + 1;
                UJMP_DISPATCH: micro_pc <= dispatch_address;
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
