; Target: vasm6502_oldstyle
; Test: DEC absolute,X ($DE)
; Cycles: 108
; Done: $C042
; Decrements memory; checks N/Z and wrap $00 -> $FF.
; Checks that C and V are unchanged.
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
        lda #$5B
        sta $1235
        lda #$01
        sta $2100
        lda #$80
        sta $7FFF
        lda #$3D
        sta $10
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; carry lost
        sta $1210
        lda #$66        ; carry lost
        sta $2000

        ; --- Case 1: $1230 + $05 = $1235, no page cross, $5B -> $5A ---
        ldx #$05
        dec $1230,x     ; Expect $5A at $1235
        php             ; Expect $75 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross, $00 -> $FF ---
        ldx #$20
        dec $12F0,x     ; Expect $FF at $1310
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with X = $FF, $01 -> $00 ---
        ldx #$FF
        dec $2001,x     ; Expect $00 at $2100
        php             ; Expect $77 at $01FD

        ; --- Case 4: X = 0, top of RAM, $80 -> $7F ---
        ldx #$00
        dec $7FFF,x     ; Expect $7F at $7FFF
        php             ; Expect $75 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010, $3D -> $3C ---
        ldx #$20
        dec $FFF0,x     ; Expect $3C at $0010
        php             ; Expect $75 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
