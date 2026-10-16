; Target: vasm6502_oldstyle
; Test: BIT zeropage ($24)
; Cycles: 81
; Done: $C037
; Checks N=M7, V=M6, Z=(A AND M)=0, and that A and C are unchanged.
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
        lda #$C0
        sta $00
        lda #$3F
        sta $FF
        lda #$40
        sta $80
        lda #$80
        sta $7F

        ; --- Case 1: N=M7=1, V=M6=1, A AND M = 0 (Z=1) ---
        lda #$01
        bit $00
        sta $0300       ; Expect $01
        php             ; Expect $F7 at $01FF

        ; --- Case 2: N=0, V=0 (cleared), A AND M <> 0 ---
        lda #$FF
        bit $FF
        sta $0301       ; Expect $FF
        php             ; Expect $35 at $01FE

        ; --- Case 3: V=1 only ---
        lda #$40
        bit $80
        sta $0302       ; Expect $40
        php             ; Expect $75 at $01FD

        ; --- Case 4: N=1 only ---
        lda #$80
        bit $7F
        sta $0303       ; Expect $80
        php             ; Expect $B5 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
