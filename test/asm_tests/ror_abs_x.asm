; Target: vasm6502_oldstyle
; Test: ROR absolute,X ($7E)
; Cycles: 159
; Done: $C05B
; Rotates right through carry; each case sets C first (via PLP).
; Checks the result and the N/Z/C flags, and that V is unchanged.
; Covers no page cross, page cross (carry into the high byte), X = $FF,
; X = 0, and wrap-around from $FFxx into the zero page.
; Trap values sit where a CPU that fails to carry into the high byte would modify memory instead.
; The result is the modified memory location itself.
; Cycle note: read-modify-write abs,X always takes 7 cycles (no page-cross variance).
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
        sta $1235
        lda #$4A
        sta $1310
        lda #$01
        sta $2100
        lda #$FE
        sta $7FFF
        lda #$78
        sta $10
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; carry lost
        sta $1210
        lda #$66        ; carry lost
        sta $2000

        ; --- Case 1: $1230 + $05 = $1235, no page cross, C=0: $B4 -> $5A ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$05
        ror $1230,x     ; Expect $5A at $1235
        php             ; Expect $34 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross, C=1: $4A -> $A5 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$20
        ror $12F0,x     ; Expect $A5 at $1310
        php             ; Expect $B4 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with X = $FF, C=0: $01 -> $00, C=1 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$FF
        ror $2001,x     ; Expect $00 at $2100
        php             ; Expect $37 at $01FD

        ; --- Case 4: X = 0, top of RAM, C=0: $FE -> $7F ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$00
        ror $7FFF,x     ; Expect $7F at $7FFF
        php             ; Expect $34 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010, C=1: $78 -> $BC ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$20
        ror $FFF0,x     ; Expect $BC at $0010
        php             ; Expect $B4 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
