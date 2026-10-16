; Target: vasm6502_oldstyle
; Test: ROR zeropage,X ($76)
; Cycles: 125
; Done: $C045
; Rotates right through carry; each case sets C first (via PLP).
; Checks the result and the N/Z/C flags, and that V is unchanged.
; Base + X must wrap within the zero page ($00xx), never cross into $01xx.
; Trap values sit where a CPU that fails to wrap would modify memory instead.
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
        sta $30
        lda #$4A
        sta $10
        lda #$01
        sta $80
        lda #$FE
        sta $40
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; wrap failed
        sta $0110
        lda #$66        ; wrap failed
        sta $0180

        ; --- Case 1: $10 + $20 = $30, no wrap, C=0: $B4 -> $5A ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$20
        ror $10,x       ; Expect $5A at $0030
        php             ; Expect $34 at $01FF

        ; --- Case 2: $F0 + $20 = $110 -> must wrap to $10, C=1: $4A -> $A5 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$20
        ror $F0,x       ; Expect $A5 at $0010
        php             ; Expect $B4 at $01FE

        ; --- Case 3: $81 + $FF = $180 -> must wrap to $80, C=0: $01 -> $00, C=1 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$FF
        ror $81,x       ; Expect $00 at $0080
        php             ; Expect $37 at $01FD

        ; --- Case 4: X = 0, C=0: $FE -> $7F ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$00
        ror $40,x       ; Expect $7F at $0040
        php             ; Expect $34 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
