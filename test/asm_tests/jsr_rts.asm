; Target: vasm6502_oldstyle
; Test: JSR/RTS pair ($20) ($60)
; Cycles: 295
; Done: $C056
; Each JSR must be undone by its RTS: execution resumes at the instruction after the JSR
; (not skipped, not repeated), SP is back where it started and the flags are untouched.
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$45        ; V=1 I=1 C=1 N=0 D=0 Z=0
        pha
        plp

        ; --- Setup ---
        lda #$FF        ; Pre-seed zero-result locations
        sta $0308
        sta $030C

        ; --- Case 1: simple call and return, marker after the JSR runs exactly once ---
        jsr s1
        inc $0300       ; Expect $01 (runs once, after the return)
        tsx
        stx $0301       ; Expect $FF (SP restored)

        ; --- Case 2: A, X, Y and flags survive a subroutine that changes nothing ---
        lda #$12
        ldx #$34
        ldy #$56
        jsr s_empty
        sta $0302       ; Expect $12
        stx $0303       ; Expect $34
        sty $0304       ; Expect $56
        php
        pla
        sta $030C       ; Expect $75 (Flags unchanged by JSR/RTS)
        jsr s_flags

        ; --- Case 3: nested calls three deep, returns unwind in reverse order ---
        jsr n1
        tsx
        stx $0305       ; Expect $FF (SP restored)

        ; --- Case 4: two calls to the same subroutine return to different places ---
        jsr s_count
        jsr s_count
        lda $0306
        sta $0307       ; Expect $02

        ; --- Case 5: SP = $00, return address wraps in the stack page ---
        ldx #$00
        txs
        jsr s_wrap
        tsx
        stx $0308       ; Expect $00 (SP restored)
        ldx #$FF
        txs

        ; --- Case 6: JSR at $C2FE (return address $C300 needs a carry), backward subroutine ---
        jmp c6

done:
        jmp done        ; Infinite loop to terminate

        .org $C2FE
c6:
        jsr s_back      ; Expect $C3 pushed high, $00 pushed low
        inc $0309       ; Expect $01 (runs once, at $C301)
        jmp done

        .org $C400
s_back:
        lda #$06
        sta $030A       ; Expect $06
        rts

        .org $C600
s1:
        lda #$01
        sta $0310       ; Expect $01
        rts
s_empty:
        rts
s_flags:
        php
        pla
        sta $030D       ; Expect $75 (Flags unchanged on entry, before the RTS)
        rts
n1:
        lda #$01
        sta $0311       ; Expect $01 (entered level 1)
        jsr n2
        lda #$05
        sta $0315       ; Expect $05 (back in level 1)
        rts
n2:
        lda #$02
        sta $0312       ; Expect $02 (entered level 2)
        jsr n3
        lda #$04
        sta $0314       ; Expect $04 (back in level 2)
        rts
n3:
        lda #$03
        sta $0313       ; Expect $03 (entered level 3)
        rts
s_count:
        inc $0306
        rts
s_wrap:
        lda #$07
        sta $030B       ; Expect $07
        rts

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
