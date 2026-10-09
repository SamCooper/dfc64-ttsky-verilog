; Target: vasm6502_oldstyle
; Tests basic stores (STA, STX, STY) across ZP and ABS addressing modes.

        .org $C000
reset:
        ; --- 0. Initialize Registers ---
        lda #$AA
        ldx #$BB
        ldy #$CC
        
        ; --- 1. Test ZERO PAGE Stores ---
        sta $10       ; Store A ($AA) to ZP $0010
        stx $11       ; Store X ($BB) to ZP $0011
        sty $12       ; Store Y ($CC) to ZP $0012
        
        ; --- 2. Test ABSOLUTE Stores ---
        sta $2010     ; Store A ($AA) to ABS $2010
        stx $2011     ; Store X ($BB) to ABS $2011
        sty $2012     ; Store Y ($CC) to ABS $2012

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
