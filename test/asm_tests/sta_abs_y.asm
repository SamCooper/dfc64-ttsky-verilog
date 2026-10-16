; Target: vasm6502_oldstyle
; Test: STA absolute,Y ($99)
; Cycles: 79
; Done: $C034
; Checks the value lands at the right address and that the flags are unchanged.
; A store to the wrong address shows up as a stray non-zero byte.
; Covers no page cross, page cross (carry into the high byte), Y = $FF,
; Y = 0, and wrap-around from $FFxx into the zero page.
; Cycle note: indexed stores always take the extra cycle (no page-cross variance).
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
        lda #$FF        ; Pre-seed a zero-result location
        sta $2100

        ; --- Case 1: $1230 + $05 = $1235, no page cross ---
        ldy #$05
        lda #$5A
        sta $1230,y     ; Expect $5A at $1235
        php             ; Expect $75 at $01FF (Flags must be unchanged by the store)

        ; --- Case 2: $12F0 + $20 = $1310, page cross ---
        ldy #$20
        lda #$A5
        sta $12F0,y     ; Expect $A5 at $1310
        php             ; Expect $F5 at $01FE (Flags must be unchanged by the store)

        ; --- Case 3: $2001 + $FF = $2100, page cross with Y = $FF ---
        ldy #$FF
        lda #$00
        sta $2001,y     ; Expect $00 at $2100
        php             ; Expect $77 at $01FD (Flags must be unchanged by the store)

        ; --- Case 4: Y = 0, top of RAM ---
        ldy #$00
        lda #$7F
        sta $7FFF,y     ; Expect $7F at $7FFF
        php             ; Expect $75 at $01FC (Flags must be unchanged by the store)

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010 ---
        ldy #$20
        lda #$3C
        sta $FFF0,y     ; Expect $3C at $0010
        php             ; Expect $75 at $01FB (Flags must be unchanged by the store)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
