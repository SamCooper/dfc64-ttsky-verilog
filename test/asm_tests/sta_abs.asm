; Target: vasm6502_oldstyle
; Test: STA absolute ($8D)
; Cycles: 55
; Done: $C024
; Checks the value lands at the right address and that the flags are unchanged.
; A store to the wrong address shows up as a stray non-zero byte.
; Covers the top of RAM ($7FFF) and $0100, the lowest address outside the zero page.
; All operands are >= $0100 so the assembler cannot pick the zero-page opcode.
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
        sta $0200

        ; --- Case 1: absolute address ---
        lda #$5A
        sta $1234       ; Expect $5A at $1234
        php             ; Expect $75 at $01FF (Flags must be unchanged by the store)

        ; --- Case 2: top of RAM ---
        lda #$A5
        sta $7FFF       ; Expect $A5 at $7FFF
        php             ; Expect $F5 at $01FE (Flags must be unchanged by the store)

        ; --- Case 3: absolute address ---
        lda #$00
        sta $0200       ; Expect $00 at $0200
        php             ; Expect $77 at $01FD (Flags must be unchanged by the store)

        ; --- Case 4: $0100, just above the zero page ---
        lda #$7F
        sta $0100       ; Expect $7F at $0100
        php             ; Expect $75 at $01FC (Flags must be unchanged by the store)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
