; Target: vasm6502_oldstyle
; Test: LDY #immediate ($A0)
; Cycles: 55
; Done: $C024
; Loads Y. Checks the result and the N/Z flags, and that C and V are left unchanged.
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
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
        sta $0302

        ; --- Case 1:  ---
        ldy #$5A
        sty $0300       ; Expect $5A
        php             ; Expect $75 at $01FF

        ; --- Case 2:  ---
        ldy #$A5
        sty $0301       ; Expect $A5
        php             ; Expect $F5 at $01FE

        ; --- Case 3:  ---
        ldy #$00
        sty $0302       ; Expect $00
        php             ; Expect $77 at $01FD

        ; --- Case 4:  ---
        ldy #$7F
        sty $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
