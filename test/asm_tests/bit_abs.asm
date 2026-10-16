; Target: vasm6502_oldstyle
; Test: BIT absolute ($2C)
; Cycles: 94
; Done: $C043
; Checks N=M7, V=M6, Z=(A AND M)=0, and that A and C are unchanged.
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
        lda #$C0
        sta $1234
        lda #$3F
        sta $7FFF
        lda #$40
        sta $0200
        lda #$80
        sta $0100
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00

        ; --- Case 1: N=M7=1, V=M6=1, A AND M = 0 (Z=1) ---
        lda #$01
        bit $1234
        sta $0300       ; Expect $01
        php             ; Expect $F7 at $01FF

        ; --- Case 2: N=0, V=0 (cleared), A AND M <> 0 ---
        lda #$FF
        bit $7FFF
        sta $0301       ; Expect $FF
        php             ; Expect $35 at $01FE

        ; --- Case 3: V=1 only ---
        lda #$40
        bit $0200
        sta $0302       ; Expect $40
        php             ; Expect $75 at $01FD

        ; --- Case 4: N=1 only ---
        lda #$80
        bit $0100
        sta $0303       ; Expect $80
        php             ; Expect $B5 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
