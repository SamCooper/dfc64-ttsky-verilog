; Target: vasm6502_oldstyle
; Test: PHA implied ($48)
; Cycles: 75
; Done: $C02E
; Pushes A; checks the pushed bytes, the SP decrement (via TSX) and stack-page wrap
; ($0100 -> $01FF), and that the flags are unchanged.
; Initial status (via PLP): V=1 I=1 C=1 N=0 D=0 Z=0
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$45        ; V=1 I=1 C=1 N=0 D=0 Z=0
        pha
        plp

        ; --- Setup ---
        lda #$FF        ; Pre-seed a zero-result location
        sta $017E

        ; --- Cases 1-3: SP = $80, push $5A, $A5, $00 ---
        ldx #$80
        txs
        lda #$5A
        pha             ; Expect $5A at $0180
        lda #$A5
        pha             ; Expect $A5 at $017F
        lda #$00
        pha             ; Expect $00 at $017E
        tsx
        stx $0300       ; Expect $7D
        php             ; Expect $75 at $017D

        ; --- Cases 4-6: SP = $01, push across the wrap ---
        ldx #$01
        txs
        lda #$C3
        pha             ; Expect $C3 at $0101
        lda #$3C
        pha             ; Expect $3C at $0100
        lda #$81
        pha             ; Expect $81 at $01FF
        tsx
        stx $0301       ; Expect $FE
        php             ; Expect $F5 at $01FE

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
