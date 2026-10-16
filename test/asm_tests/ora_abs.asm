; Target: vasm6502_oldstyle
; Test: ORA absolute ($0D)
; Cycles: 94
; Done: $C043
; Checks the result and the N/Z flags, and that C and V are left unchanged.
; Covers the top of RAM ($7FFF) and $0100, the lowest address outside the zero page.
; All operands are >= $0100 so the assembler cannot pick the zero-page opcode.
; Trap values catch a CPU that drops the high byte.
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
        lda #$0A
        sta $1234
        lda #$25
        sta $7FFF
        lda #$0F
        sta $0100
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: absolute address ---
        lda #$50
        ora $1234
        sta $0300       ; Expect $5A ($50 = high byte dropped)
        php             ; Expect $75 at $01FF

        ; --- Case 2: top of RAM ---
        lda #$80
        ora $7FFF
        sta $0301       ; Expect $A5 ($80 = high byte dropped)
        php             ; Expect $F5 at $01FE

        ; --- Case 3: absolute address ---
        lda #$00
        ora $0200
        sta $0302       ; Expect $00 ($99 = high byte dropped)
        php             ; Expect $77 at $01FD

        ; --- Case 4: $0100, just above the zero page ---
        lda #$70
        ora $0100
        sta $0303       ; Expect $7F ($F9 = high byte dropped)
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
