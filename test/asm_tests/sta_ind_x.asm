; Target: vasm6502_oldstyle
; Test: STA (indirect,X) ($81)
; Cycles: 129
; Done: $C057
; Checks the value lands at the right address and that the flags are unchanged.
; A store to the wrong address shows up as a stray non-zero byte.
; The pointer address (base + X) must wrap within the zero page, and a
; pointer at $FF must take its high byte from $00, not $0100.
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
        ; Pointers
        lda #$34
        sta $24
        lda #$12
        sta $25
        lda #$45
        sta $10
        lda #$23
        sta $11
        lda #$56
        sta $0110
        lda #$34
        sta $0111
        lda #$40
        sta $FF
        lda #$30
        sta $00
        lda #$50
        sta $0100
        lda #$FF
        sta $80
        lda #$7F
        sta $81
        lda #$FF        ; Pre-seed a zero-result location
        sta $3040

        ; --- Case 1: pointer at $20 + $04 = $24 -> $1234 ---
        ldx #$04
        lda #$5A
        sta ($20,x)     ; Expect $5A at $1234
        php             ; Expect $75 at $01FF (Flags must be unchanged by the store)

        ; --- Case 2: pointer at $F0 + $20 = $110 -> must wrap to $10 -> $2345 ---
        ldx #$20
        lda #$A5
        sta ($F0,x)     ; Expect $A5 at $2345
        php             ; Expect $F5 at $01FE (Flags must be unchanged by the store)

        ; --- Case 3: pointer at $00 + $FF = $FF, high byte from $00 -> $3040 ---
        ldx #$FF
        lda #$00
        sta ($00,x)     ; Expect $00 at $3040
        php             ; Expect $77 at $01FD (Flags must be unchanged by the store)

        ; --- Case 4: X = 0, pointer at $80 -> $7FFF ---
        ldx #$00
        lda #$7F
        sta ($80,x)     ; Expect $7F at $7FFF
        php             ; Expect $75 at $01FC (Flags must be unchanged by the store)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
