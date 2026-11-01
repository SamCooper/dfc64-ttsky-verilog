; Target: vasm6502_oldstyle
; Test: BRK/RTI pair ($00) ($40)
; Cycles: 523
; Done: $C07C
; RTI must undo a BRK: execution resumes at BRK+2 (the padding byte is skipped), the
; status is restored (the handler deliberately changes N, Z, C, D and I), and SP is
; back where it started. The padding byte is INX so that returning to BRK+1 shows up.
; The handler mode byte at $0320 selects: 0 = plain, 1 = BRK again once, 2 = call a subroutine.
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Setup ---
        lda #$FF        ; Pre-seed zero-result locations
        sta $0309
        sta $0301

        ; --- Case 1: registers reach the handler unchanged, flags and PC come back ---
        ldx #$34
        ldy #$56
        lda #$CB        ; N=1 V=1 D=1 Z=1 C=1 I=0
        pha
        plp
        brk
        inx             ; Padding byte (skipped)
        stx $0300       ; Expect $34 (X untouched, so the INX was skipped)
        php
        pla
        sta $0301       ; Expect $FB (Status restored: N V D Z C set, I clear)
        tsx
        stx $0302       ; Expect $FF (SP restored)
        lda $0330
        sta $0340       ; Expect $CB (A as the handler saw it)
        lda $0331
        sta $0341       ; Expect $34
        lda $0332
        sta $0342       ; Expect $56
        lda $0333
        sta $0343       ; Expect $FF (Handler status: B and I set, D still set)

        ; --- Case 2: nested BRK inside the handler, two RTIs unwind it ---
        lda #$00
        sta $0310       ; Handler entry counter
        lda #$01
        sta $0320       ; Mode: BRK again once
        ldx #$FF
        txs
        lda #$00        ; All flags clear
        pha
        plp
        brk
        inx             ; Padding byte (skipped)
        php
        pla
        sta $0304       ; Expect $30 (Status restored: all clear)
        tsx
        stx $0303       ; Expect $FF (SP restored after both RTIs)
        lda $0310
        sta $0306       ; Expect $02 (handler ran twice)

        ; --- Case 3: handler calls a subroutine (JSR/RTS inside BRK/RTI) ---
        ldx #$FF
        txs
        lda #$02
        sta $0320       ; Mode: call a subroutine
        lda #$41        ; V=1 C=1
        pha
        plp
        brk
        inx             ; Padding byte (skipped)
        php
        pla
        sta $0307       ; Expect $71 (Status restored)
        tsx
        stx $0308       ; Expect $FF (SP restored)
        lda #$00
        sta $0320       ; Mode: plain
        ldx #$00

        ; --- Case 4: BRK at $C2FE (return address $C300 needs a carry) ---
        jmp c4

done:
        jmp done        ; Infinite loop to terminate

        .org $C2FE
c4:
        brk
        inx             ; Padding byte (skipped)
        stx $0309       ; Expect $00 (INX skipped)
        lda #$04
        sta $030A       ; Expect $04 (continued at $C300)
        jmp done

        .org $C600
handler:
        sta $0330       ; Record the registers as the handler sees them
        stx $0331
        sty $0332
        php
        pla
        sta $0333       ; Status as pushed-then-seen: B and I set, D unchanged
        inc $0310       ; Count handler entries
        lda $0320
        beq h_exit      ; Mode 0: plain
        cmp #$02
        beq h_call
        lda $0310       ; Mode 1: nest once
        cmp #$02
        beq h_exit
        brk
        nop             ; Padding byte (skipped)
        jmp h_exit
h_call:
        jsr sub
h_exit:
        lda #$7F        ; Clobber the flags so that RTI has something to restore
        sec
        cld
        sei
        rti
sub:
        lda #$99
        sta $0321       ; Expect $99
        rts

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word handler   ; IRQ/BRK vector
