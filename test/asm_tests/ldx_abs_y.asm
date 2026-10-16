; Target: vasm6502_oldstyle
; Test: LDX absolute,Y ($BE)
; Cycles: 122
; Done: $C056
; Loads X. Checks the result and the N/Z flags, and that C and V are left unchanged.
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
        lda #$5A
        sta $1235
        lda #$A5
        sta $1310
        lda #$7F
        sta $7FFF
        lda #$3C
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
        ldx $1230,y
        stx $0300       ; Expect $5A
        php             ; Expect $75 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross ---
        ldy #$20
        ldx $12F0,y
        stx $0301       ; Expect $A5 ($99 = carry lost)
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with Y = $FF ---
        ldy #$FF        ; Also leaves N=1, so LDX must clear it
        ldx $2001,y
        stx $0302       ; Expect $00 ($66 = carry lost)
        php             ; Expect $77 at $01FD

        ; --- Case 4: Y = 0, top of RAM ---
        ldy #$00        ; Also leaves Z=1, so LDX must clear it
        ldx $7FFF,y
        stx $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010 ---
        ldy #$20
        ldx $FFF0,y
        stx $0304       ; Expect $3C ($00 = carry lost)
        php             ; Expect $75 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
