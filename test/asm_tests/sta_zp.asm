; Target: vasm6502_oldstyle
; Test: STA zeropage ($85)
; Cycles: 50
; Done: $C01F
; Checks the value lands at the right address and that the flags are unchanged.
; A store to the wrong address shows up as a stray non-zero byte.
; Uses both ends of the zero page ($00 and $FF).
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
        sta $80

        ; --- Case 1: lowest ZP address ---
        lda #$5A
        sta $00         ; Expect $5A at $0000
        php             ; Expect $75 at $01FF (Flags must be unchanged by the store)

        ; --- Case 2: highest ZP address ---
        lda #$A5
        sta $FF         ; Expect $A5 at $00FF
        php             ; Expect $F5 at $01FE (Flags must be unchanged by the store)

        ; --- Case 3: mid ZP address ---
        lda #$00
        sta $80         ; Expect $00 at $0080
        php             ; Expect $77 at $01FD (Flags must be unchanged by the store)

        ; --- Case 4: mid ZP address ---
        lda #$7F
        sta $7F         ; Expect $7F at $007F
        php             ; Expect $75 at $01FC (Flags must be unchanged by the store)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
