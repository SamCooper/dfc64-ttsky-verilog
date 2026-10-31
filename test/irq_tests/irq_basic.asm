; Target: vasm6502_oldstyle
; Test: IRQ taken from a wait loop, RTI back
; Cycles: 94
; Done: $C014
; Checks the IRQ stack frame (return PC, status with B=0 and U=1), that I is set
; inside the handler while the other flags and A are kept, and that RTI restores the status.
; The IRQ is raised on a 'jmp wait' loop, so the pushed PC is 'wait' whichever instruction
; boundary takes it. The handler copies the pushed PC to $0302/$0303, then patches it to
; 'resume' and returns with RTI.
;
; Result layout:
;   $01FF-$01FD  IRQ frame: PCH (patched), PCL (patched), status
;   $01FC        status inside the handler (PHP)
;   $0300        A inside the handler
;   $0301        SP inside the handler, after its PHP
;   $0302/$0303  PCL/PCH as pushed by the IRQ
;   $01FF        status after RTI (PHP at 'resume' overwrites the patched PCH)
;   $0304        status after RTI (copy)
; Initial status (via PLP): N=1 V=1 Z=1 C=1 D=0 I=0

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$C3        ; N=1 V=1 Z=1 C=1 D=0 I=0
        pha
        lda #$5A
        plp
        jmp wait        ; enter by JMP: the PLP's dummy read must not fire the marker
wait:
        jmp wait        ; @irq

resume:
        php             ; Expect $F3 at $01FF
        pla
        sta $0304       ; Expect $F3

done:
        jmp done        ; Infinite loop to terminate

irq:
        php             ; @irq_off   Expect $F7 at $01FC (I set, B set by PHP)
        sta $0300       ; Expect $5A
        tsx
        stx $0301       ; Expect $FB
        lda $0103,x     ; PCL pushed by the IRQ
        sta $0302       ; Expect <wait
        lda $0104,x     ; PCH pushed by the IRQ
        sta $0303       ; Expect >wait
        lda #<resume
        sta $0103,x
        lda #>resume
        sta $0104,x
        pla             ; drop the handler's PHP
        lda #$01        ; change N/Z so RTI has to restore them
        rti             ; Expect $E3 at $01FD (B=0, U=1)

nmi_trap:
        lda #$EE
        sta $03FE       ; Unexpected NMI
        jmp done

        .org $FFFA
        .word nmi_trap  ; NMI vector
        .word reset     ; Reset vector
        .word irq       ; IRQ/BRK vector
