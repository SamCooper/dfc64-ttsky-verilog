; Target: vasm6502_oldstyle
; Test: CMP zeropage ($C5)
; Cycles: 81
; Done: $C037
; Checks N/Z/C after the compare, and that the register and V are unchanged
; (the register is stored after each compare).
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
        ; Operand values (correct locations)
        lda #$5A
        sta $00
        lda #$A5
        sta $FF
        lda #$01
        sta $80
        lda #$02
        sta $7F

        ; --- Case 1: lowest ZP address ---
        lda #$5A
        cmp $00
        sta $0300       ; Expect $5A
        php             ; Expect $77 at $01FF

        ; --- Case 2: highest ZP address ---
        lda #$5A
        cmp $FF
        sta $0301       ; Expect $5A
        php             ; Expect $F4 at $01FE

        ; --- Case 3: mid ZP address ---
        lda #$80
        cmp $80
        sta $0302       ; Expect $80
        php             ; Expect $75 at $01FD

        ; --- Case 4: mid ZP address ---
        lda #$01
        cmp $7F
        sta $0303       ; Expect $01
        php             ; Expect $F4 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
