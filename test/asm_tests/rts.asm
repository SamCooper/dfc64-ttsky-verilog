; Target: vasm6502_oldstyle
; Test: RTS implied ($60)
; Cycles: 124
; Done: $C03C
; Pulls an address and continues at address + 1. Return addresses are pushed by
; hand (PHA) so JSR is not needed. Each target stores a marker and records SP.
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
        sta $0312

        ; --- Case 1: return to r1 ---
        lda #>(r1-1)
        pha
        lda #<(r1-1)
        pha
        rts
        lda #$EE
        sta $0300
r1:
        tsx
        stx $0310       ; Expect $FF (SP after the RTS)
        php             ; Expect $F5 at $01FF (Flags unchanged by RTS)
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: pulled address $C4FF; +1 must carry into the high byte -> $C500 ---
        lda #>(r2-1)
        pha
        lda #<(r2-1)
        pha
        rts

        ; --- Case 3: SP = $FE, pulls from $01FF and $0100 (wrap) ---
c3:
        lda #<(r3-1)
        sta $01FF
        lda #>(r3-1)
        sta $0100
        ldx #$FE
        txs
        rts
        lda #$EE
        sta $0302

done:
        jmp done        ; Infinite loop to terminate

        .org $C400
r2_bad:
        lda #$E2        ; Wrong: no carry into the high byte
        sta $0301
        jmp c3

        .org $C500
r2:
        tsx
        stx $0311       ; Expect $FE (SP after the RTS)
        php             ; Expect $F5 at $01FE (Flags unchanged by RTS)
        lda #$02
        sta $0301       ; Expect $02
        jmp c3

        .org $C600
r3:
        tsx
        stx $0312       ; Expect $00 (SP after the RTS)
        php             ; Expect $77 at $0100 (Flags unchanged by RTS)
        lda #$03
        sta $0302       ; Expect $03
        jmp done

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
