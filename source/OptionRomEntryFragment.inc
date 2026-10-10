; OptionRomEntryFragment.inc

OptionRomEntry:
                cli                             ; c049: fah
                mov	bx,ss                   ; c04a: 8ch, d3h
                mov	cx,sp                   ; c04c: 8bh, cch
                mov	ax,cs                   ; c04e: 8ch, c8h
                mov	ds,ax                   ; c050: 8eh, d8h

                assume	ds:OptionRom
                mov	es,ax                   ; c052: 8eh, c0h

                assume	es:OptionRom
                mov	ax,1fe0h                ; c054: b8h, e0h, 1fh
                mov	ss,ax                   ; c057: 8eh, d0h

                assume	ss:InitializationStack
                mov	sp,100h                 ; c059: bch, 00h, 01h
                push	bx                      ; c05c: 53h
                push	cx                      ; c05d: 51h

; Mask IRQs, initialise the keyboard PPI, and discard a scan code.

                mov	al,0ffh                 ; c05e: b0h, ffh
                out	PIC_DATA_PORT,al        ; c060: e6h, 21h
                mov	al,99h                  ; c062: b0h, 99h
                out	PPI_CONTROL_PORT,al     ; c064: e6h, 63h
                mov	al,80h                  ; c066: b0h, 80h
                out	PPI_PORT_B,al           ; c068: e6h, 61h
                in	al,KBD_DATA_PORT        ; c06a: e4h, 60h
                call	InitializeDisplay       ; c06c: e8h, e2h, 08h
                push	dx                      ; c06f: 52h
                push	es                      ; c070: 06h
                call	InstallInterruptVectors ; c071: e8h, 74h, 00h
                call	InitializePitChannels   ; c074: e8h, c1h, 08h

RelocatePcNetRuntimeStash:

; Relocate the PC-NET runtime template into the OptionRomData workspace.

                mov	ax,0ff69h               ; c077: b8h, 69h, ffh
                sub	ax,word ptr 0fe00h      ; c07a: 2dh, 00h, feh
                mov	bx,cs                   ; c07d: 8ch, cbh
                add	ax,bx                   ; c07f: 03h, c3h
                mov	ds,ax                   ; c081: 8eh, d8h

                assume	ds:PcNetRelocationSource
                mov	ax,1fa0h                ; c083: b8h, a0h, 1fh
                mov	es,ax                   ; c086: 8eh, c0h

                assume	es:OptionRomData
                mov	si,offset PcNetRelocationPayload ; c088: beh, 00h, 00h
                xor	di,di                   ; c08b: 33h, ffh
                mov	cx,PcNetRelocationPayloadLength ; c08d: 8bh, 0eh, 0fh, 03h
                cld                             ; c091: fch
                RepneMovsb                      ; c092: f2h, a4h
                push	es                      ; c094: 06h
                pop	ds                      ; c095: 1fh

                assume	ds:OptionRomData

; Save the entry register values in the runtime workspace.

                pop	word ptr DisplaySegment ; c096: 8fh, 06h, 2ah, 00h
                pop	word ptr DisplayModeControlPort ; c09a: 8fh, 06h, 30h, 00h
                pop	word ptr CallerStackPointer ; c09e: 8fh, 06h, 3ch, 00h
                pop	word ptr CallerStackSegment ; c0a2: 8fh, 06h, 3ah, 00h
                mov	si,Version_2_20         ; c0a6: beh, 3bh, 01h
                call	Display                 ; c0a9: e8h, 42h, 09h
                mov	si,Loading              ; c0ac: beh, 4dh, 01h
                call	Display                 ; c0af: e8h, 3ch, 09h
                call	SelectTransport         ; c0b2: e8h, 95h, 01h
                mov	word ptr ds:[38h],40h   ; c0b5: c7h, 06h, 38h, 00h, 40h, 00h
                mov	byte ptr ds:[4dh],0ah   ; c0bb: c6h, 06h, 4dh, 00h, 0ah
                mov	byte ptr PcNetRuntimeByte0107,5h ; c0c0: c6h, 06h, 07h, 01h, 05h
                mov	byte ptr SessionFlags,80h ; c0c5: c6h, 06h, 5eh, 00h, 80h
                mov	byte ptr PcNetRuntimeByte010D,0ch ; c0ca: c6h, 06h, 0dh, 01h, 0ch
                mov	word ptr BootTimeoutTicks,258h ; c0cf: c7h, 06h, 2eh, 00h, 58h, 02h
                mov	byte ptr PcNetRuntimeWord0109,1h ; c0d5: c6h, 06h, 09h, 01h, 01h
                mov	al,byte ptr cs:[FunctionKeyEnableMask] ; c0da: 2eh, a0h, 1fh, 00h
                mov	byte ptr PcNetRuntimeWord010B,al ; c0de: a2h, 0bh, 01h
                call	RunTransportStateMachine ; c0e1: e8h, a3h, 05h
                sti                             ; c0e4: fbh
                jmp	near ptr ShowAddress    ; c0e5: e9h, 21h, 07h
