; Target: vasm6502_oldstyle
; Test: NOP implied ($EA)
; Cycles: 68
; Done: $C02D
; Must change nothing: A, X, Y, the flags and memory are checked afterwards.
; Also checks that NOP is one byte long (the next instruction runs).
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Case 1: status $FF, A=$5A X=$A5 Y=$7F ---
        lda #$FF
        pha
        ldx #$A5
        ldy #$7F
        lda #$5A
        plp             ; Set flags last (A, X, Y are kept)
        nop
        php             ; Expect $FF at $01FF
        sta $0300       ; Expect $5A
        stx $0301       ; Expect $A5
        sty $0302       ; Expect $7F

        ; --- Case 2: status $00, A=$3C X=$C3 Y=$81 ---
        lda #$00
        pha
        ldx #$C3
        ldy #$81
        lda #$3C
        plp             ; Set flags last (A, X, Y are kept)
        nop
        php             ; Expect $30 at $01FE
        sta $0303       ; Expect $3C
        stx $0304       ; Expect $C3
        sty $0305       ; Expect $81

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
