; Target: vasm6502_oldstyle
; Test: BRK implied ($00)
; Cycles: 90
; Done: $C01D
; Pushes PC+2 (skipping a padding byte) and the status with B set, sets I, and
; jumps through the IRQ/BRK vector. On the NMOS 6502, D is not cleared.
; The handler records its own status with PHP, drops it with PLA, and returns with RTI.
; Case 2 runs with SP = $EF so its stack frame does not overwrite case 1.
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Setup ---
        lda #$FF        ; Pre-seed a zero-result location
        sta $01EE

        ; --- Case 1: status N V D Z C set, I clear ---
        lda #$CB        ; N=1 V=1 D=1 Z=1 C=1 I=0
        pha
        plp
        brk             ; Expect $C0 at $01FF, $0E at $01FE, $FB at $01FD
        nop             ; Padding byte (skipped)
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: SP = $EF, status clear, BRK at $C2FE (PC+2 = $C300 needs a carry) ---
        ldx #$EF
        txs
        lda #$00        ; N=0 V=0 D=0 I=0 Z=0 C=0
        pha
        plp
        jmp c2

done:
        jmp done        ; Infinite loop to terminate

        .org $C2FE
c2:
        brk             ; Expect $C3 at $01EF, $00 at $01EE, $30 at $01ED
        nop             ; Padding byte (skipped)
        lda #$02
        sta $0301       ; Expect $02
        jmp done

        .org $C600
handler:
        php             ; Expect $FF at $01FC, $34 at $01EC (Status inside the handler: I set, D unchanged)
        pla
        rti

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word handler   ; IRQ/BRK vector
