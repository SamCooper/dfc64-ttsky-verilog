; Target: vasm6502_oldstyle
; Test: PLA implied ($68)
; Cycles: 128
; Done: $C052
; Pulls A; checks the value, N/Z, and stack-page wrap ($01FF -> $0100).
; Each case points SP just below a seeded byte; the PHP afterwards overwrites that byte.
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
        lda #$5A
        sta $0181
        lda #$A5
        sta $0191
        lda #$7F
        sta $01B1
        lda #$3C
        sta $0100
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: SP = $80, pull $5A from $0181 ---
        ldx #$80
        txs
        ldy #$80        ; Set N/Z opposite to the result
        pla
        sta $0300       ; Expect $5A
        php             ; Expect $75 at $0181

        ; --- Case 2: SP = $90, pull $A5 from $0191 ---
        ldx #$90
        txs
        ldy #$00        ; Set N/Z opposite to the result
        pla
        sta $0301       ; Expect $A5
        php             ; Expect $F5 at $0191

        ; --- Case 3: SP = $A0, pull $00 from $01A1 ---
        ldx #$A0
        txs
        ldy #$80        ; Set N/Z opposite to the result
        pla
        sta $0302       ; Expect $00
        php             ; Expect $77 at $01A1

        ; --- Case 4: SP = $B0, pull $7F from $01B1 ---
        ldx #$B0
        txs
        ldy #$80        ; Set N/Z opposite to the result
        pla
        sta $0303       ; Expect $7F
        php             ; Expect $75 at $01B1

        ; --- Case 5: SP = $FF, pull $3C from $0100 (wrap) ---
        ldx #$FF
        txs
        ldy #$80        ; Set N/Z opposite to the result
        pla
        sta $0304       ; Expect $3C
        php             ; Expect $75 at $0100

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
