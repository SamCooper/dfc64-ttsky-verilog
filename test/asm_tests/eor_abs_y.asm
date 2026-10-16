; Target: vasm6502_oldstyle
; Test: EOR absolute,Y ($59)
; Cycles: 138
; Done: $C065
; Checks the result and the N/Z flags, and that C and V are left unchanged.
; Covers no page cross, page cross (carry into the high byte), Y = $FF,
; Y = 0, and wrap-around from $FFxx into the zero page.
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
        lda #$A5
        sta $1235
        lda #$AA
        sta $1310
        lda #$C3
        sta $2100
        lda #$FF
        sta $7FFF
        lda #$33
        sta $10
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; carry lost
        sta $1210
        lda #$66        ; carry lost
        sta $2000
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: $1230 + $05 = $1235, no page cross ---
        ldy #$05
        lda #$FF
        eor $1230,y
        sta $0300       ; Expect $5A
        php             ; Expect $75 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross ---
        ldy #$20
        lda #$0F
        eor $12F0,y
        sta $0301       ; Expect $A5 ($96 = carry lost)
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with Y = $FF ---
        ldy #$FF
        lda #$C3
        eor $2001,y
        sta $0302       ; Expect $00 ($A5 = carry lost)
        php             ; Expect $77 at $01FD

        ; --- Case 4: Y = 0, top of RAM ---
        ldy #$00
        lda #$80
        eor $7FFF,y
        sta $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010 ---
        ldy #$20
        lda #$0F
        eor $FFF0,y
        sta $0304       ; Expect $3C ($0F = carry lost)
        php             ; Expect $75 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
