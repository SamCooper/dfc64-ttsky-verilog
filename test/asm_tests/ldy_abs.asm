; Target: vasm6502_oldstyle
; Test: LDY absolute ($AC)
; Cycles: 86
; Done: $C03B
; Loads Y. Checks the result and the N/Z flags, and that C and V are left unchanged.
; Covers the top of RAM ($7FFF) and $0100, the lowest address outside the zero page.
; All operands are >= $0100 so the assembler cannot pick the zero-page opcode.
; Trap values catch a CPU that drops the high byte.
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
        sta $1234
        lda #$A5
        sta $7FFF
        lda #$7F
        sta $0100
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: absolute address ---
        ldy $1234
        sty $0300       ; Expect $5A ($00 = high byte dropped)
        php             ; Expect $75 at $01FF

        ; --- Case 2: top of RAM ---
        ldy $7FFF
        sty $0301       ; Expect $A5 ($00 = high byte dropped)
        php             ; Expect $F5 at $01FE

        ; --- Case 3: absolute address ---
        ldy $0200
        sty $0302       ; Expect $00 ($99 = high byte dropped)
        php             ; Expect $77 at $01FD

        ; --- Case 4: $0100, just above the zero page ---
        ldy $0100
        sty $0303       ; Expect $7F ($99 = high byte dropped)
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
