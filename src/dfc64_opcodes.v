// --- ADC: Add with Carry ---
parameter OP_ADC_IMM   = 8'h69;
parameter OP_ADC_ZP    = 8'h65;
parameter OP_ADC_ZP_X  = 8'h75;
parameter OP_ADC_ABS   = 8'h6D;
parameter OP_ADC_ABS_X = 8'h7D;
parameter OP_ADC_ABS_Y = 8'h79;
parameter OP_ADC_IND_X = 8'h61;
parameter OP_ADC_IND_Y = 8'h71;

// --- AND: Logical AND ---
parameter OP_AND_IMM   = 8'h29;
parameter OP_AND_ZP    = 8'h25;
parameter OP_AND_ZP_X  = 8'h35;
parameter OP_AND_ABS   = 8'h2D;
parameter OP_AND_ABS_X = 8'h3D;
parameter OP_AND_ABS_Y = 8'h39;
parameter OP_AND_IND_X = 8'h21;
parameter OP_AND_IND_Y = 8'h31;

// --- ASL: Arithmetic Shift Left ---
parameter OP_ASL_ACC   = 8'h0A;
parameter OP_ASL_ZP    = 8'h06;
parameter OP_ASL_ZP_X  = 8'h16;
parameter OP_ASL_ABS   = 8'h0E;
parameter OP_ASL_ABS_X = 8'h1E;

// --- BRANCH INSTRUCTIONS ---
parameter OP_BCC_REL   = 8'h90; // Branch if Carry Clear
parameter OP_BCS_REL   = 8'hB0; // Branch if Carry Set
parameter OP_BEQ_REL   = 8'hF0; // Branch if Equal
parameter OP_BMI_REL   = 8'h30; // Branch if Minus
parameter OP_BNE_REL   = 8'hD0; // Branch if Not Equal
parameter OP_BPL_REL   = 8'h10; // Branch if Positive
parameter OP_BVC_REL   = 8'h50; // Branch if Overflow Clear
parameter OP_BVS_REL   = 8'h70; // Branch if Overflow Set

// --- BIT: Bit Test ---
parameter OP_BIT_ZP    = 8'h24;
parameter OP_BIT_ABS   = 8'h2C;

// --- BRK: Force Interrupt ---
parameter OP_BRK_IMP   = 8'h00;

// --- CLEAR FLAG INSTRUCTIONS ---
parameter OP_CLC_IMP   = 8'h18; // Clear Carry Flag
parameter OP_CLD_IMP   = 8'hD8; // Clear Decimal Mode
parameter OP_CLI_IMP   = 8'h58; // Clear Interrupt Disable
parameter OP_CLV_IMP   = 8'hB8; // Clear Overflow Flag

// --- CMP: Compare Accumulator ---
parameter OP_CMP_IMM   = 8'hC9;
parameter OP_CMP_ZP    = 8'hC5;
parameter OP_CMP_ZP_X  = 8'hD5;
parameter OP_CMP_ABS   = 8'hCD;
parameter OP_CMP_ABS_X = 8'hDD;
parameter OP_CMP_ABS_Y = 8'hD9;
parameter OP_CMP_IND_X = 8'hC1;
parameter OP_CMP_IND_Y = 8'hD1;

// --- CPX: Compare X Register ---
parameter OP_CPX_IMM   = 8'hE0;
parameter OP_CPX_ZP    = 8'hE4;
parameter OP_CPX_ABS   = 8'hEC;

// --- CPY: Compare Y Register ---
parameter OP_CPY_IMM   = 8'hC0;
parameter OP_CPY_ZP    = 8'hC4;
parameter OP_CPY_ABS   = 8'hCC;

// --- DEC: Decrement Memory ---
parameter OP_DEC_ZP    = 8'hC6;
parameter OP_DEC_ZP_X  = 8'hD6;
parameter OP_DEC_ABS   = 8'hCE;
parameter OP_DEC_ABS_X = 8'hDE;

// --- DEX/DEY: Decrement X/Y ---
parameter OP_DEX_IMP   = 8'hCA;
parameter OP_DEY_IMP   = 8'h88;

// --- EOR: Exclusive OR ---
parameter OP_EOR_IMM   = 8'h49;
parameter OP_EOR_ZP    = 8'h45;
parameter OP_EOR_ZP_X  = 8'h55;
parameter OP_EOR_ABS   = 8'h4D;
parameter OP_EOR_ABS_X = 8'h5D;
parameter OP_EOR_ABS_Y = 8'h59;
parameter OP_EOR_IND_X = 8'h41;
parameter OP_EOR_IND_Y = 8'h51;

// --- INC: Increment Memory ---
parameter OP_INC_ZP    = 8'hE6;
parameter OP_INC_ZP_X  = 8'hF6;
parameter OP_INC_ABS   = 8'hEE;
parameter OP_INC_ABS_X = 8'hFE;

// --- INX/INY: Increment X/Y ---
parameter OP_INX_IMP   = 8'hE8;
parameter OP_INY_IMP   = 8'hC8;

// --- JMP: Jump ---
parameter OP_JMP_ABS   = 8'h4C;
parameter OP_JMP_IND   = 8'h6C;

// --- JSR: Jump to Subroutine ---
parameter OP_JSR_ABS   = 8'h20;

// --- LDA: Load Accumulator ---
parameter OP_LDA_IMM   = 8'hA9;
parameter OP_LDA_ZP    = 8'hA5;
parameter OP_LDA_ZP_X  = 8'hB5;
parameter OP_LDA_ABS   = 8'hAD;
parameter OP_LDA_ABS_X = 8'hBD;
parameter OP_LDA_ABS_Y = 8'hB9;
parameter OP_LDA_IND_X = 8'hA1;
parameter OP_LDA_IND_Y = 8'hB1;

// --- LDX: Load X Register ---
parameter OP_LDX_IMM   = 8'hA2;
parameter OP_LDX_ZP    = 8'hA6;
parameter OP_LDX_ZP_Y  = 8'hB6;
parameter OP_LDX_ABS   = 8'hAE;
parameter OP_LDX_ABS_Y = 8'hBE;

// --- LDY: Load Y Register ---
parameter OP_LDY_IMM   = 8'hA0;
parameter OP_LDY_ZP    = 8'hA4;
parameter OP_LDY_ZP_X  = 8'hB4;
parameter OP_LDY_ABS   = 8'hAC;
parameter OP_LDY_ABS_X = 8'hBC;

// --- LSR: Logical Shift Right ---
parameter OP_LSR_ACC   = 8'h4A;
parameter OP_LSR_ZP    = 8'h46;
parameter OP_LSR_ZP_X  = 8'h56;
parameter OP_LSR_ABS   = 8'h4E;
parameter OP_LSR_ABS_X = 8'h5E;

// --- NOP: No Operation ---
parameter OP_NOP_IMP   = 8'hEA;

// --- ORA: Logical Inclusive OR ---
parameter OP_ORA_IMM   = 8'h09;
parameter OP_ORA_ZP    = 8'h05;
parameter OP_ORA_ZP_X  = 8'h15;
parameter OP_ORA_ABS   = 8'h0D;
parameter OP_ORA_ABS_X = 8'h1D;
parameter OP_ORA_ABS_Y = 8'h19;
parameter OP_ORA_IND_X = 8'h01;
parameter OP_ORA_IND_Y = 8'h11;

// --- REGISTER PUSH/PULL (STACK) ---
parameter OP_PHA_IMP   = 8'h48; // Push Accumulator
parameter OP_PHP_IMP   = 8'h08; // Push Processor Status
parameter OP_PLA_IMP   = 8'h68; // Pull Accumulator
parameter OP_PLP_IMP   = 8'h28; // Pull Processor Status

// --- ROL: Rotate Left ---
parameter OP_ROL_ACC   = 8'h2A;
parameter OP_ROL_ZP    = 8'h26;
parameter OP_ROL_ZP_X  = 8'h36;
parameter OP_ROL_ABS   = 8'h2E;
parameter OP_ROL_ABS_X = 8'h3E;

// --- ROR: Rotate Right ---
parameter OP_ROR_ACC   = 8'h6A;
parameter OP_ROR_ZP    = 8'h66;
parameter OP_ROR_ZP_X  = 8'h76;
parameter OP_ROR_ABS   = 8'h6E;
parameter OP_ROR_ABS_X = 8'h7E;

// --- RETURNS ---
parameter OP_RTI_IMP   = 8'h40; // Return from Interrupt
parameter OP_RTS_IMP   = 8'h60; // Return from Subroutine

// --- SBC: Subtract with Carry ---
parameter OP_SBC_IMM   = 8'hE9;
parameter OP_SBC_ZP    = 8'hE5;
parameter OP_SBC_ZP_X  = 8'hF5;
parameter OP_SBC_ABS   = 8'hED;
parameter OP_SBC_ABS_X = 8'hFD;
parameter OP_SBC_ABS_Y = 8'hF9;
parameter OP_SBC_IND_X = 8'hE1;
parameter OP_SBC_IND_Y = 8'hF1;

// --- SET FLAG INSTRUCTIONS ---
parameter OP_SEC_IMP   = 8'h38; // Set Carry Flag
parameter OP_SED_IMP   = 8'hF8; // Set Decimal Flag
parameter OP_SEI_IMP   = 8'h78; // Set Interrupt Disable

// --- STA: Store Accumulator ---
parameter OP_STA_ZP    = 8'h85;
parameter OP_STA_ZP_X  = 8'h95;
parameter OP_STA_ABS   = 8'h8D;
parameter OP_STA_ABS_X = 8'h9D;
parameter OP_STA_ABS_Y = 8'h99;
parameter OP_STA_IND_X = 8'h81;
parameter OP_STA_IND_Y = 8'h91;

// --- STX: Store X Register ---
parameter OP_STX_ZP    = 8'h86;
parameter OP_STX_ZP_Y  = 8'h96;
parameter OP_STX_ABS   = 8'h8E;

// --- STY: Store Y Register ---
parameter OP_STY_ZP    = 8'h84;
parameter OP_STY_ZP_X  = 8'h94;
parameter OP_STY_ABS   = 8'h8C;

// --- REGISTER TRANSFERS ---
parameter OP_TAX_IMP   = 8'hAA; // Transfer A to X
parameter OP_TAY_IMP   = 8'hA8; // Transfer A to Y
parameter OP_TSX_IMP   = 8'hBA; // Transfer Stack Pointer to X
parameter OP_TXA_IMP   = 8'h8A; // Transfer X to A
parameter OP_TXS_IMP   = 8'h9A; // Transfer X to Stack Pointer
parameter OP_TYA_IMP   = 8'h98; // Transfer Y to A
