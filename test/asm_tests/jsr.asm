; Target: vasm6502_oldstyle
; Test: JSR absolute ($20)
; Cycles: 133
; Done: $C01E
; Pushes the address of its own last byte (PC+2), high byte first, then jumps.
; Subroutines record SP (via TSX) and return with JMP, so RTS is not needed.
; Case 1 starts with SP = $00 to check the stack-page wrap.
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
        sta $01F9

        ; --- Case 1: SP = $00, pushes to $0100 and $01FF (wrap) ---
        ldx #$00
        txs
        jsr sub1        ; Expect $C0 at $0100, $11 at $01FF
ret1:

        ; --- Case 2: JSR in mid-page, SP = $FD ---
        ldx #$FD
        txs
        jsr sub2        ; Expect $C0 at $01FD, $17 at $01FC
ret2:

        ; --- Case 3: SP = $FA, JSR at $C2FE; its last byte is $C300, so the pushed address needs a carry ---
        ldx #$FA
        txs
        jmp c3

done:
        jmp done        ; Infinite loop to terminate

        .org $C2FE
c3:
        jsr sub3        ; Expect $C3 at $01FA, $00 at $01F9
ret3:
        jmp done

        .org $C600
sub1:
        php
        pla
        sta $0320       ; Expect $77 (Flags unchanged by JSR)
        tsx
        stx $0310       ; Expect $FE (SP after the JSR)
        lda #$01
        sta $0300       ; Expect $01
        jmp ret1
sub2:
        php
        pla
        sta $0321       ; Expect $F5 (Flags unchanged by JSR)
        tsx
        stx $0311       ; Expect $FB (SP after the JSR)
        lda #$02
        sta $0301       ; Expect $02
        jmp ret2
sub3:
        php
        pla
        sta $0322       ; Expect $F5 (Flags unchanged by JSR)
        tsx
        stx $0312       ; Expect $F8 (SP after the JSR)
        lda #$03
        sta $0302       ; Expect $03
        jmp ret3

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
