; Target: vasm6502_oldstyle
; Test: TSX implied ($BA)
; Cycles: 79
; Done: $C034
; Copies the stack pointer to X; checks the value and N/Z.
; Each case sets SP with TXS; the PHP then lands at $0100+SP.
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

        ; --- Case 1: SP = $5A ---
        ldx #$5A
        txs
        ldy #$80        ; Set N/Z opposite to the result
        tsx
        stx $0300       ; Expect $5A
        php             ; Expect $75 at $015A (Pushed at $0100+SP)

        ; --- Case 2: SP = $A5 ---
        ldx #$A5
        txs
        ldy #$00        ; Set N/Z opposite to the result
        tsx
        stx $0301       ; Expect $A5
        php             ; Expect $F5 at $01A5 (Pushed at $0100+SP)

        ; --- Case 3: SP = $00 ---
        ldx #$00
        txs
        ldy #$80        ; Set N/Z opposite to the result
        tsx
        stx $0302       ; Expect $00
        php             ; Expect $77 at $0100 (Pushed at $0100+SP)

        ; --- Case 4: SP = $7F ---
        ldx #$7F
        txs
        ldy #$80        ; Set N/Z opposite to the result
        tsx
        stx $0303       ; Expect $7F
        php             ; Expect $75 at $017F (Pushed at $0100+SP)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
