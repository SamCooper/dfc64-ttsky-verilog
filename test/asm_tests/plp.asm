; Target: vasm6502_oldstyle
; Test: PLP implied ($28)
; Cycles: 74
; Done: $C026
; Pulls the status; N V D I Z C come from the stack, B and bit 5 are ignored.
; The PHP after each PLP shows the resulting status.
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Case 1: pull $FF ---
        lda #$FF
        pha
        ldy #$00        ; Make N/Z differ before the pull
        plp
        php             ; Expect $FF at $01FF

        ; --- Case 2: pull $00 ---
        lda #$00
        pha
        ldy #$80        ; Make N/Z differ before the pull
        plp
        php             ; Expect $30 at $01FE

        ; --- Case 3: pull $C3 ---
        lda #$C3
        pha
        ldy #$00        ; Make N/Z differ before the pull
        plp
        php             ; Expect $F3 at $01FD

        ; --- Case 4: pull $3C ---
        lda #$3C
        pha
        ldy #$80        ; Make N/Z differ before the pull
        plp
        php             ; Expect $3C at $01FC

        ; --- Case 5: pull $CF ---
        lda #$CF
        pha
        ldy #$00        ; Make N/Z differ before the pull
        plp
        php             ; Expect $FF at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
