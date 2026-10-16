; Target: vasm6502_oldstyle
; Test: DEC zeropage,X ($D6)
; Cycles: 84
; Done: $C031
; Decrements memory; checks N/Z and wrap $00 -> $FF.
; Checks that C and V are unchanged.
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
        lda #$5B
        sta $30
        lda #$01
        sta $80
        lda #$80
        sta $40
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; wrap failed
        sta $0110
        lda #$66        ; wrap failed
        sta $0180

        ; --- Case 1: $10 + $20 = $30, no wrap, $5B -> $5A ---
        ldx #$20
        dec $10,x       ; Expect $5A at $0030
        php             ; Expect $75 at $01FF

        ; --- Case 2: $F0 + $20 = $110 -> must wrap to $10, $00 -> $FF ---
        ldx #$20
        dec $F0,x       ; Expect $FF at $0010
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $81 + $FF = $180 -> must wrap to $80, $01 -> $00 ---
        ldx #$FF
        dec $81,x       ; Expect $00 at $0080
        php             ; Expect $77 at $01FD

        ; --- Case 4: X = 0, $80 -> $7F ---
        ldx #$00
        dec $40,x       ; Expect $7F at $0040
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
