; Target: vasm6502_oldstyle
; Test: NMI taken through $FFFA with I=1, RTI back
; Cycles: 94
; Done: $C014
; Checks the NMI stack frame (return PC, status with B=0 and U=1), that NMI ignores I,
; that I stays set inside the handler with the other flags and A kept, and that RTI
; restores the status. The handler copies the pushed PC to $0302/$0303, then patches it
; to 'resume' and returns.
;
; Result layout:
;   $01FF-$01FD  NMI frame: PCH (patched), PCL (patched), status
;   $01FC        status inside the handler (PHP)
;   $0300        A inside the handler
;   $0301        SP inside the handler, after its PHP
;   $0302/$0303  PCL/PCH as pushed by the NMI
;   $01FF        status after RTI (PHP at 'resume' overwrites the patched PCH)
;   $0304        status after RTI (copy)
; Initial status (via PLP): N=1 D=1 I=1 C=1 V=0 Z=0

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$8D        ; N=1 D=1 I=1 C=1 V=0 Z=0
        pha
        lda #$66
        plp
        jmp wait        ; enter by JMP: the PLP's dummy read must not fire the marker
wait:
        jmp wait        ; @nmi

resume:
        php             ; Expect $BD at $01FF
        pla
        sta $0304       ; Expect $BD

done:
        jmp done        ; Infinite loop to terminate

nmi:
        php             ; Expect $BD at $01FC
        sta $0300       ; Expect $66
        tsx
        stx $0301       ; Expect $FB
        lda $0103,x     ; PCL pushed by the NMI
        sta $0302       ; Expect <wait
        lda $0104,x     ; PCH pushed by the NMI
        sta $0303       ; Expect >wait
        lda #<resume
        sta $0103,x
        lda #>resume
        sta $0104,x
        pla             ; drop the handler's PHP
        lda #$00        ; change N/Z so RTI has to restore them
        rti             ; Expect $AD at $01FD (B=0, U=1)

irq_trap:
        lda #$EE
        sta $03FF       ; Unexpected IRQ/BRK
        jmp done

        .org $FFFA
        .word nmi       ; NMI vector
        .word reset     ; Reset vector
        .word irq_trap  ; IRQ/BRK vector
