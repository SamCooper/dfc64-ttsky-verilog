; Target: vasm6502_oldstyle
; Test: ASL absolute,X ($1E)
; Cycles: 114
; Done: $C047
; Shifts left; bit 7 goes to C, bit 0 becomes 0.
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
        lda #$2D
        sta $1235
        lda #$52
        sta $1310
        lda #$80
        sta $2100
        lda #$3F
        sta $7FFF
        lda #$9E
        sta $10
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; carry lost
        sta $1210
        lda #$66        ; carry lost
        sta $2000

        ; --- Case 1: $1230 + $05 = $1235, no page cross, $2D -> $5A ---
        ldx #$05
        asl $1230,x     ; Expect $5A at $1235
        php             ; Expect $74 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross, $52 -> $A4 ---
        ldx #$20
        asl $12F0,x     ; Expect $A4 at $1310
        php             ; Expect $F4 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with X = $FF, $80 -> $00, C=1 ---
        ldx #$FF
        asl $2001,x     ; Expect $00 at $2100
        php             ; Expect $77 at $01FD

        ; --- Case 4: X = 0, top of RAM, $3F -> $7E ---
        ldx #$00
        asl $7FFF,x     ; Expect $7E at $7FFF
        php             ; Expect $74 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010, $9E -> $3C, C=1 ---
        ldx #$20
        asl $FFF0,x     ; Expect $3C at $0010
        php             ; Expect $75 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
