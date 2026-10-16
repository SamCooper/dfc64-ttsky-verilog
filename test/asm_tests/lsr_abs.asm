; Target: vasm6502_oldstyle
; Test: LSR absolute ($4E)
; Cycles: 78
; Done: $C02F
; Shifts right; bit 0 goes to C, bit 7 becomes 0 (N is always 0).
; Checks the result and the N/Z/C flags, and that V is unchanged.
; Covers the top of RAM ($7FFF) and $0100, the lowest address outside the zero page.
; All operands are >= $0100 so the assembler cannot pick the zero-page opcode.
; Trap values sit where a CPU that drops the high byte would modify memory instead.
; The result is the modified memory location itself.
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
        lda #$B4
        sta $1234
        lda #$FF
        sta $7FFF
        lda #$01
        sta $0200
        lda #$FE
        sta $0100
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00

        ; --- Case 1: absolute address, $B4 -> $5A ---
        lsr $1234       ; Expect $5A at $1234
        php             ; Expect $74 at $01FF

        ; --- Case 2: top of RAM, $FF -> $7F, C=1 ---
        lsr $7FFF       ; Expect $7F at $7FFF
        php             ; Expect $75 at $01FE

        ; --- Case 3: absolute address, $01 -> $00, C=1 ---
        lsr $0200       ; Expect $00 at $0200
        php             ; Expect $77 at $01FD

        ; --- Case 4: $0100, just above the zero page, $FE -> $7F ---
        lsr $0100       ; Expect $7F at $0100
        php             ; Expect $74 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
