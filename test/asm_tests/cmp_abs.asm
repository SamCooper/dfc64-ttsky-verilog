; Target: vasm6502_oldstyle
; Test: CMP absolute ($CD)
; Cycles: 94
; Done: $C043
; Checks N/Z/C after the compare, and that the register and V are unchanged
; (the register is stored after each compare).
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
        lda #$01
        sta $0200
        lda #$02
        sta $0100
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00

        ; --- Case 1: absolute address ---
        lda #$5A
        cmp $1234
        sta $0300       ; Expect $5A
        php             ; Expect $77 at $01FF

        ; --- Case 2: top of RAM ---
        lda #$5A
        cmp $7FFF
        sta $0301       ; Expect $5A
        php             ; Expect $F4 at $01FE

        ; --- Case 3: absolute address ---
        lda #$80
        cmp $0200
        sta $0302       ; Expect $80
        php             ; Expect $75 at $01FD

        ; --- Case 4: $0100, just above the zero page ---
        lda #$01
        cmp $0100
        sta $0303       ; Expect $01
        php             ; Expect $F4 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
