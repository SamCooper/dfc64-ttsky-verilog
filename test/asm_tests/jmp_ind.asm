; Target: vasm6502_oldstyle
; Test: JMP (indirect) ($6C)
; Cycles: 74
; Done: $C03C
; Jumps through a pointer in RAM. Case 2 checks the NMOS page-wrap bug:
; JMP ($04FF) takes the low byte from $04FF and the high byte from $0400, not $0500.
; A CPU without the bug lands on the $E2 marker.
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
        ; Case 1 pointer at $0410 -> t1
        lda #<t1
        sta $0410
        lda #>t1
        sta $0411
        ; Case 2 pointer at $04FF: low $40, high from $0400 = $C5 (NMOS), $0500 = $C6 (fixed)
        lda #$40
        sta $04FF
        lda #$C5
        sta $0400
        lda #$C6
        sta $0500

        ; --- Case 1: pointer within one page ---
        jmp ($0410)
        lda #$EE
        sta $0300
        jmp c2
t1:
        php             ; Expect $F5 at $01FF
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: pointer at a page end ($04FF), NMOS wrap bug ---
c2:
        jmp ($04FF)
        lda #$EE
        sta $0301
        jmp done

done:
        jmp done        ; Infinite loop to terminate

        .org $C540
t2:
        php             ; Expect $75 at $01FE
        lda #$02        ; NMOS: high byte from $0400
        sta $0301       ; Expect $02
        jmp done

        .org $C640
t2_fixed:
        lda #$E2        ; Wrong: high byte from $0500
        sta $0301
        jmp done

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
