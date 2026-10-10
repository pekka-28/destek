; OptionRomTransportProtocol.inc

; Fixed PC-NET service stubs; no in-ROM callers are identified.

PcNetServiceStubTable:
                jmp	StartTransportOutput

PcNetServicePollOutput:
                jmp	PollTransportOutput

PcNetServiceReceiveData:
                jmp	near ptr ReceiveSerialData

PcNetServiceDispatchOutput:
                jmp	near ptr DispatchTransportOutput

PcNetServiceAdapterService:
                jmp	near ptr ServiceTransportAdapter

DispatchTransportOutput:
                mov	dx,word ptr AdapterDataPort ; cd0c: 8bh, 16h, 1ah, 00h
                xor	ax,ax                   ; cd10: 33h, c0h
                mov	al,TransportState       ; cd12: a0h, 4fh, 00h
                shl	ax,1                    ; cd15: d1h, e0h
                call	DispatchTransportOutputState ; cd17: e8h, 14h, 00h

SerialOutputStateDispatchOffsets:
                dw	01a9h, 00e0h, 0116h, 0114h, 00edh
                dw	00efh, 00f2h, 00d4h, 00e1h, 0170h

DispatchTransportOutputState:
                pop	bx                      ; cd2e: 5bh
                add	bx,ax                   ; cd2f: 03h, d8h
                add	bx,word ptr cs:[bx]     ; cd31: 2eh, 03h, 1fh
                jmp	bx                      ; cd34: ffh, e3h

ServiceTransportAdapter:
                mov	dx,word ptr AdapterDataPort ; cd36: 8bh, 16h, 1ah, 00h
                call	word ptr TransportServiceCallback ; cd3a: ffh, 16h, 22h, 00h
LCD3E:
                test	byte ptr ds:[56h],40h   ; cd3e: f6h, 06h, 56h, 00h, 40h
                mov	byte ptr ds:[56h],0h    ; cd43: c6h, 06h, 56h, 00h, 00h
                jne	LCD4B                   ; cd48: 75h, 01h
LCD4A:
                ret                             ; cd4a: c3h

LCD4B:
                test	byte ptr ds:[55h],0ffh  ; cd4b: f6h, 06h, 55h, 00h, ffh
                jne	LCD4A                   ; cd50: 75h, f8h
                inc	byte ptr ds:[55h]       ; cd52: feh, 06h, 55h, 00h
                mov	al,3h                   ; cd56: b0h, 03h
                mov	si,QueueSessionControl  ; cd58: beh, 7eh, 06h
                jmp	si                      ; cd5b: ffh, e6h

; Read serial data and assemble a received runtime record.

ReceiveSerialData:
                mov	dx,word ptr AdapterDataPort ; cd5d: 8bh, 16h, 1ah, 00h
                in	al,dx                   ; cd61: ech
                test	byte ptr ds:[56h],80h   ; cd62: f6h, 06h, 56h, 00h, 80h
                je	LCDC6                   ; cd67: 74h, 5dh
                and	byte ptr ds:[56h],7fh   ; cd69: 80h, 26h, 56h, 00h, 7fh
                cmp	al,0f0h                 ; cd6e: 3ch, f0h
                jb	LCDC1                   ; cd70: 72h, 4fh
                cmp	al,0feh                 ; cd72: 3ch, feh
                ja	LCDD0                   ; cd74: 77h, 5ah
                jb	LCD94                   ; cd76: 72h, 1ch
                test	byte ptr ds:[56h],40h   ; cd78: f6h, 06h, 56h, 00h, 40h
                je	LCDCF                   ; cd7d: 74h, 50h
                test	word ptr SerialReceiveCrc16,0ffffh ; cd7f: f7h, 06h, 3eh, 00h, ffh, ffh
                jne	LCD3E                   ; cd85: 75h, b7h
                mov	byte ptr ds:[55h],0h    ; cd87: c6h, 06h, 55h, 00h, 00h
                mov	byte ptr ds:[56h],0h    ; cd8c: c6h, 06h, 56h, 00h, 00h
                jmp	near ptr LCEDF          ; cd91: e9h, 4bh, 01h

LCD94:
                cmp	al,0f6h                 ; cd94: 3ch, f6h
                ja	LCD3E                   ; cd96: 77h, a6h
                test	byte ptr ds:[56h],40h   ; cd98: f6h, 06h, 56h, 00h, 40h
                je	LCDA4                   ; cd9d: 74h, 05h
                push	ax                      ; cd9f: 50h
                call	LCD3E                   ; cda0: e8h, 9bh, ffh
                pop	ax                      ; cda3: 58h
LCDA4:
                or	byte ptr ds:[56h],40h   ; cda4: 80h, 0eh, 56h, 00h, 40h
                mov	bx,79h                  ; cda9: bbh, 79h, 00h
                mov	word ptr ds:[16h],bx    ; cdac: 89h, 1eh, 16h, 00h
                mov	byte ptr ds:[57h],88h   ; cdb0: c6h, 06h, 57h, 00h, 88h
                xor	bx,bx                   ; cdb5: 33h, dbh
                mov	byte ptr ds:[58h],bl    ; cdb7: 88h, 1eh, 58h, 00h
                mov	SerialReceiveCrc16,bx   ; cdbb: 89h, 1eh, 3eh, 00h
                jmp	LCDD9                   ; cdbf: ebh, 18h

LCDC1:
                push	ax                      ; cdc1: 50h
                call	LCDD0                   ; cdc2: e8h, 0bh, 00h
                pop	ax                      ; cdc5: 58h
LCDC6:
                cmp	al,0aah                 ; cdc6: 3ch, aah
                jne	LCDD2                   ; cdc8: 75h, 08h
                or	byte ptr ds:[56h],80h   ; cdca: 80h, 0eh, 56h, 00h, 80h
LCDCF:
                ret                             ; cdcf: c3h

LCDD0:
                mov	al,0aah                 ; cdd0: b0h, aah
LCDD2:
                test	byte ptr ds:[56h],40h   ; cdd2: f6h, 06h, 56h, 00h, 40h
                je	LCDCF                   ; cdd7: 74h, f6h
LCDD9:
                dec	byte ptr ds:[57h]       ; cdd9: feh, 0eh, 57h, 00h
                jne	LCDE2                   ; cddd: 75h, 03h
                jmp	near ptr LCD3E          ; cddf: e9h, 5ch, ffh

LCDE2:
                inc	byte ptr ds:[58h]       ; cde2: feh, 06h, 58h, 00h
                mov	si,word ptr ds:[16h]    ; cde6: 8bh, 36h, 16h, 00h
                mov	byte ptr [si],al        ; cdea: 88h, 04h
                inc	word ptr ds:[16h]       ; cdec: ffh, 06h, 16h, 00h
                mov	cx,SerialReceiveCrc16   ; cdf0: 8bh, 0eh, 3eh, 00h
                call	UpdateCrc16             ; cdf4: e8h, d4h, 00h
                mov	SerialReceiveCrc16,cx   ; cdf7: 89h, 0eh, 3eh, 00h
LCDFB:
                ret                             ; cdfb: c3h

SerialTransmitPreamble:
                mov	al,0aah                 ; cdfc: b0h, aah
                mov	byte ptr ds:[50h],0ffh  ; cdfe: c6h, 06h, 50h, 00h, ffh
LCE03:
                inc	byte ptr TransportState ; ce03: feh, 06h, 4fh, 00h
LCE07:
                jmp	word ptr TransportOutputCallback ; ce07: ffh, 26h, 1ch, 00h
                mov	al,0feh                 ; ce0b: b0h, feh
                jmp	LCE03                   ; ce0d: ebh, f4h
                inc	byte ptr TransportState ; ce0f: feh, 06h, 4fh, 00h
LCE13:
                mov	al,byte ptr SerialTransmitCrc16 ; ce13: a0h, 40h, 00h
                jmp	LCE1B                   ; ce16: ebh, 03h
                mov	al,byte ptr SerialTransmitCrc16+1 ; ce18: a0h, 41h, 00h
LCE1B:
                call	LCE24                   ; ce1b: e8h, 06h, 00h
                inc	byte ptr TransportState ; ce1e: feh, 06h, 4fh, 00h
                jmp	LCE8F                   ; ce22: ebh, 6bh

LCE24:
                cmp	al,byte ptr ds:[50h]    ; ce24: 3ah, 06h, 50h, 00h
                mov	byte ptr ds:[50h],0ffh  ; ce28: c6h, 06h, 50h, 00h, ffh
                jbe	LCDFB                   ; ce2d: 76h, cch
                pop	ax                      ; ce2f: 58h
                mov	al,0ffh                 ; ce30: b0h, ffh
                jmp	LCE07                   ; ce32: ebh, d3h
                test	byte ptr ds:[54h],0ffh  ; ce34: f6h, 06h, 54h, 00h, ffh
                je	LCE46                   ; ce39: 74h, 0bh
                inc	byte ptr ds:[40h]       ; ce3b: feh, 06h, 40h, 00h
                mov	byte ptr TransportState,5h ; ce3f: c6h, 06h, 4fh, 00h, 05h
                jmp	LCE13                   ; ce44: ebh, cdh

LCE46:
                mov	si,word ptr ds:[14h]    ; ce46: 8bh, 36h, 14h, 00h
                mov	al,byte ptr [si]        ; ce4a: 8ah, 04h
                call	LCE24                   ; ce4c: e8h, d5h, ffh
                inc	word ptr ds:[14h]       ; ce4f: ffh, 06h, 14h, 00h
                dec	byte ptr ds:[51h]       ; ce53: feh, 0eh, 51h, 00h
                jne	LCE84                   ; ce57: 75h, 2bh
                cmp	byte ptr TransportState,2h ; ce59: 80h, 3eh, 4fh, 00h, 02h
                jne	LCE80                   ; ce5e: 75h, 20h
                mov	si,word ptr ds:[12h]    ; ce60: 8bh, 36h, 12h, 00h
                or	si,si                   ; ce64: 0bh, f6h
                je	LCE78                   ; ce66: 74h, 10h
                mov	cl,byte ptr [si+2h]     ; ce68: 8ah, 4ch, 02h
                mov	byte ptr ds:[51h],cl    ; ce6b: 88h, 0eh, 51h, 00h
                lea	si,[si+4h]              ; ce6f: 8dh, 74h, 04h
                mov	word ptr ds:[14h],si    ; ce72: 89h, 36h, 14h, 00h
                jmp	LCE80                   ; ce76: ebh, 08h

LCE78:
                inc	byte ptr TransportState ; ce78: feh, 06h, 4fh, 00h
                inc	byte ptr TransportState ; ce7c: feh, 06h, 4fh, 00h
LCE80:
                inc	byte ptr TransportState ; ce80: feh, 06h, 4fh, 00h
LCE84:
                mov	cx,SerialTransmitCrc16  ; ce84: 8bh, 0eh, 40h, 00h
                call	UpdateCrc16             ; ce88: e8h, 40h, 00h
                mov	SerialTransmitCrc16,cx  ; ce8b: 89h, 0eh, 40h, 00h
LCE8F:
                cmp	al,0aah                 ; ce8f: 3ch, aah
                jne	LCE98                   ; ce91: 75h, 05h
                mov	byte ptr ds:[50h],0efh  ; ce93: c6h, 06h, 50h, 00h, efh
LCE98:
                jmp	word ptr TransportOutputCallback ; ce98: ffh, 26h, 1ch, 00h
                mov	byte ptr ds:[54h],0h    ; ce9c: c6h, 06h, 54h, 00h, 00h
                mov	al,ds:[52h]             ; cea1: a0h, 52h, 00h
                or	al,al                   ; cea4: 0ah, c0h
                je	LCEB3                   ; cea6: 74h, 0bh
                cmp	al,byte ptr PendingControlClass ; cea8: 3ah, 06h, 53h, 00h
                jne	LCEB3                   ; ceac: 75h, 05h
                mov	byte ptr PendingControlClass,0h ; ceae: c6h, 06h, 53h, 00h, 00h
LCEB3:
                mov	byte ptr TransportState,0h ; ceb3: c6h, 06h, 4fh, 00h, 00h
                call	LCEFF                   ; ceb8: e8h, 44h, 00h
                test	byte ptr TransportState,0ffh ; cebb: f6h, 06h, 4fh, 00h, ffh
                je	LCEC3                   ; cec0: 74h, 01h
                ret                             ; cec2: c3h

LCEC3:
                mov	dx,word ptr AdapterStatusPort ; cec3: 8bh, 16h, 18h, 00h
                jmp	word ptr TransportReturnCallback ; cec7: ffh, 26h, 24h, 00h

UpdateCrc16     proc	near
                xor	bx,bx
                mov	bl,al
                mov	ah,ch
                xor	bl,cl
                shl	bx,1
                les	si,dword ptr Crc16TablePointer
                mov	cx,word ptr es:[bx+si]
                xor	cl,ah
                ret
UpdateCrc16     endp

LCEDF:
                mov	bl,byte ptr ds:[79h]    ; cedf: 8ah, 1eh, 79h, 00h
                and	bl,0fh                  ; cee3: 80h, e3h, 0fh
                cmp	bl,5h                   ; cee6: 80h, fbh, 05h
                jne	LCEF8                   ; cee9: 75h, 0dh
                mov	byte ptr StartupControlClass,0h ; ceeb: c6h, 06h, 59h, 00h, 00h
                mov	al,ds:[7ah]             ; cef0: a0h, 7ah, 00h
                mov	byte ptr NodeAddress,al ; cef3: a2h, 2ch, 00h
                jmp	LCF04                   ; cef6: ebh, 0ch

LCEF8:
                test	byte ptr StartupControlClass,0ffh ; cef8: f6h, 06h, 59h, 00h, ffh
                je	LCF04                   ; cefd: 74h, 05h
LCEFF:
                mov	si,RunTransportStateMachine ; ceff: beh, 87h, 06h
                jmp	si                      ; cf02: ffh, e6h

LCF04:
                mov	si,ProcessSessionHeader ; cf04: beh, 35h, 06h
                call	si                      ; cf07: ffh, d6h
                je	LCF1D                   ; cf09: 74h, 12h
                test	byte ptr TransportState,0ffh ; cf0b: f6h, 06h, 4fh, 00h, ffh
                je	LCF18                   ; cf10: 74h, 06h
                mov	al,ds:[52h]             ; cf12: a0h, 52h, 00h
                mov	ds:[54h],al             ; cf15: a2h, 54h, 00h
LCF18:
                mov	si,ResumeTransportSession ; cf18: beh, f3h, 06h
                jmp	si                      ; cf1b: ffh, e6h

LCF1D:
                mov	al,ds:[4eh]             ; cf1d: a0h, 4eh, 00h
                sub	al,byte ptr ds:[7ah]    ; cf20: 2ah, 06h, 7ah, 00h
                jns	LCF2D                   ; cf24: 79h, 07h
                inc	al                      ; cf26: feh, c0h
                je	LCF32                   ; cf28: 74h, 08h
                jmp	near ptr LCD4B          ; cf2a: e9h, 1eh, feh

LCF2D:
                mov	si,RequestSessionAck    ; cf2d: beh, 7ch, 06h
                jmp	si                      ; cf30: ffh, e6h

; Copy the completed serial payload into an acquired record.

LCF32:
                mov	si,AcquireReceiveBuffer ; cf32: beh, fah, 06h
                call	si                      ; cf35: ffh, d6h
                je	LCF5D                   ; cf37: 74h, 24h
                mov	si,7dh                  ; cf39: beh, 7dh, 00h
                xor	cx,cx                   ; cf3c: 33h, c9h
                mov	cl,byte ptr ds:[58h]    ; cf3e: 8ah, 0eh, 58h, 00h
                sub	cx,word ptr 7h          ; cf42: 81h, e9h, 07h, 00h
                mov	byte ptr es:[di+2h],cl  ; cf46: 26h, 88h, 4dh, 02h
                mov	bx,di                   ; cf4a: 8bh, dfh
                lea	di,[di+4h]              ; cf4c: 8dh, 7dh, 04h
                cld                             ; cf4f: fch
                RepneMovsb                      ; cf50: f2h, a4h
                mov	al,byte ptr [si]        ; cf52: 8ah, 04h
                mov	byte ptr es:[bx+3h],al  ; cf54: 26h, 88h, 47h, 03h
                mov	si,ProcessReceivedBuffer ; cf58: beh, 2dh, 07h
                call	si                      ; cf5b: ffh, d6h
LCF5D:
                jmp	near ptr LCEFF          ; cf5d: e9h, 9fh, ffh

PollTransportOutput:
                test	byte ptr TransportState,0ffh ; cf60: f6h, 06h, 4fh, 00h, ffh
                ret                             ; cf65: c3h

StartTransportOutput:
                mov	byte ptr ds:[52h],bl    ; cf66: 88h, 1eh, 52h, 00h
                or	bl,0f0h                 ; cf6a: 80h, cbh, f0h
                mov	byte ptr ds:[101h],bl   ; cf6d: 88h, 1eh, 01h, 01h
                mov	word ptr ds:[12h],si    ; cf71: 89h, 36h, 12h, 00h
                mov	ax,101h                 ; cf75: b8h, 01h, 01h
                mov	ds:[14h],ax             ; cf78: a3h, 14h, 00h
                mov	byte ptr ds:[51h],4h    ; cf7b: c6h, 06h, 51h, 00h, 04h
                mov	SerialTransmitCrc16,0h  ; cf80: c7h, 06h, 40h, 00h, 00h, 00h
                mov	byte ptr TransportState,1h ; cf86: c6h, 06h, 4fh, 00h, 01h
                jmp	near ptr DispatchTransportOutput ; cf8b: e9h, 7eh, fdh

PcNetServiceStubUnknownWord:
                dw	0291h

LocalAreaNetworkRestart:
                jmp	LocalAreaNetworkRestartHandler

LocalAreaNetworkStep:
                jmp	ReadLocalAreaNetworkStatus

LocalAreaNetworkReceiveService:
                jmp	near ptr ReadLocalAreaNetworkFrame
