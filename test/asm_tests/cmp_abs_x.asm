; Target: vasm6502_oldstyle
; Test: CMP absolute,X ($DD)
; Cycles: 132
; Done: $C060
; Checks N/Z/C after the compare, and that the register and V are unchanged
; (the register is stored after each compare).
; Covers no page cross, page cross (carry into the high byte), X = $FF,
; X = 0, and wrap-around from $FFxx into the zero page.
; Trap values catch a CPU that fails to carry into the high byte.
; Cycle note: cases 2 and 3 cross a page (+1 cycle on the 6502).
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
        sta $1235
        lda #$A5
        sta $1310
        lda #$01
        sta $2100
        lda #$02
        sta $7FFF
        lda #$1C
        sta $10
        ; Trap values (used only by a faulty CPU)
        lda #$33        ; carry lost
        sta $1210
        lda #$CC        ; carry lost
        sta $2000

        ; --- Case 1: $1230 + $05 = $1235, no page cross ---
        ldx #$05
        lda #$5A
        cmp $1230,x
        sta $0300       ; Expect $5A
        php             ; Expect $77 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross ---
        ldx #$20
        lda #$5A
        cmp $12F0,x
        sta $0301       ; Expect $5A
        php             ; Expect $F4 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with X = $FF ---
        ldx #$FF
        lda #$80
        cmp $2001,x
        sta $0302       ; Expect $80
        php             ; Expect $75 at $01FD

        ; --- Case 4: X = 0, top of RAM ---
        ldx #$00
        lda #$01
        cmp $7FFF,x
        sta $0303       ; Expect $01
        php             ; Expect $F4 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010 ---
        ldx #$20
        lda #$3C
        cmp $FFF0,x
        sta $0304       ; Expect $3C
        php             ; Expect $75 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
