; Target: vasm6502_oldstyle
; Test: TXS implied ($9A)
; Cycles: 57
; Done: $C027
; Copies X to the stack pointer and must not change any flags.
; The PHP after each TXS shows where SP points ($0100+X).
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

        ; --- Case 1: X = $80 ---
        ldy #$00        ; N/Z opposite to what X would give
        ldx #$80
        ldy #$00        ; Restore N/Z opposite to X
        txs
        php             ; Expect $77 at $0180 (Lands at $0100+X, flags unchanged)

        ; --- Case 2: X = $00 ---
        ldy #$80        ; N/Z opposite to what X would give
        ldx #$00
        ldy #$80        ; Restore N/Z opposite to X
        txs
        php             ; Expect $F5 at $0100 (Lands at $0100+X, flags unchanged)

        ; --- Case 3: X = $FF ---
        ldy #$00        ; N/Z opposite to what X would give
        ldx #$FF
        ldy #$00        ; Restore N/Z opposite to X
        txs
        php             ; Expect $77 at $01FF (Lands at $0100+X, flags unchanged)

        ; --- Case 4: X = $7F ---
        ldy #$80        ; N/Z opposite to what X would give
        ldx #$7F
        ldy #$80        ; Restore N/Z opposite to X
        txs
        php             ; Expect $F5 at $017F (Lands at $0100+X, flags unchanged)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
