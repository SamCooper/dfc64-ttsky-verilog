; Target: vasm6502_oldstyle
; Test: ORA zeropage,X ($15)
; Cycles: 106
; Done: $C04A
; Checks the result and the N/Z flags, and that C and V are left unchanged.
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
        lda #$0A
        sta $30
        lda #$25
        sta $10
        lda #$0F
        sta $40
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; wrap failed
        sta $0110
        lda #$66        ; wrap failed
        sta $0180
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: $10 + $20 = $30, no wrap ---
        ldx #$20
        lda #$50
        ora $10,x
        sta $0300       ; Expect $5A
        php             ; Expect $75 at $01FF

        ; --- Case 2: $F0 + $20 = $110 -> must wrap to $10 ---
        ldx #$20
        lda #$80
        ora $F0,x
        sta $0301       ; Expect $A5 ($99 = wrap failed)
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $81 + $FF = $180 -> must wrap to $80 ---
        ldx #$FF
        lda #$00
        ora $81,x
        sta $0302       ; Expect $00 ($66 = wrap failed)
        php             ; Expect $77 at $01FD

        ; --- Case 4: X = 0 ---
        ldx #$00
        lda #$70
        ora $40,x
        sta $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
