; Target: vasm6502_oldstyle
; Tests STA across ABS_X, ABS_Y, and IND_Y addressing modes.
; Includes standard offsets and page-crossing offsets.

        .org $C000
reset:
        ; --- 1. Test ABSOLUTE, X ---
        lda #$11
        ldx #$05
        sta $2000, X  ; Store to $2005 (No page cross)
        
        ldx #$80
        sta $20C0, X  ; Store to $2140 (Crosses page boundary)

        ; --- 2. Test ABSOLUTE, Y ---
        lda #$22
        ldy #$05
        sta $3000, Y  ; Store to $3005 (No page cross)
        
        ldy #$80
        sta $30C0, Y  ; Store to $3140 (Crosses page boundary)

        ; --- 3. Test INDIRECT, Y ---
        ; Setup Indirect Pointer at ZP $10 to point to $40C0
        lda #$C0
        sta $10       ; Pointer LSB
        lda #$40
        sta $11       ; Pointer MSB
        
        lda #$33
        ldy #$05
        sta ($10), Y  ; Store to $40C5 (No page cross)
        
        ldy #$80
        sta ($10), Y  ; Store to $4140 (Crosses page boundary)

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
