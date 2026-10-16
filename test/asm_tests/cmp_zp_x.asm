; Target: vasm6502_oldstyle
; Test: CMP zeropage,X ($D5)
; Cycles: 105
; Done: $C049
; Checks N/Z/C after the compare, and that the register and V are unchanged
; (the register is stored after each compare).
; Base + X must wrap within the zero page ($00xx), never cross into $01xx.
; Trap values catch a CPU that fails to wrap.
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
        sta $30
        lda #$A5
        sta $10
        lda #$01
        sta $80
        lda #$02
        sta $40
        ; Trap values (used only by a faulty CPU)
        lda #$33        ; wrap failed
        sta $0110
        lda #$CC        ; wrap failed
        sta $0180

        ; --- Case 1: $10 + $20 = $30, no wrap ---
        ldx #$20
        lda #$5A
        cmp $10,x
        sta $0300       ; Expect $5A
        php             ; Expect $77 at $01FF

        ; --- Case 2: $F0 + $20 = $110 -> must wrap to $10 ---
        ldx #$20
        lda #$5A
        cmp $F0,x
        sta $0301       ; Expect $5A
        php             ; Expect $F4 at $01FE

        ; --- Case 3: $81 + $FF = $180 -> must wrap to $80 ---
        ldx #$FF
        lda #$80
        cmp $81,x
        sta $0302       ; Expect $80
        php             ; Expect $75 at $01FD

        ; --- Case 4: X = 0 ---
        ldx #$00
        lda #$01
        cmp $40,x
        sta $0303       ; Expect $01
        php             ; Expect $F4 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
