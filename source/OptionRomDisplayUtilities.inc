; OptionRomDisplayUtilities.inc

InitializeDisplay               proc	near

                assume	ds:OptionRom, es:nothing
                mov	ax,cs
                cmp	ax,word ptr 0fe00h
                jne	InitializeBiosTextMode
                mov	dx,MONO_MODE_CONTROL_PORT
                mov	al,1
                out	dx,al
                mov	bx,dx
                mov	dx,MONO_CRTC_INDEX_PORT
                mov	di,MONO_CRTC_DATA_PORT
                mov	si,offset MonoCrtcRegisterValues
                mov	ax,MONO_VIDEO_SEGMENT
                mov	es,ax

                assume	es:ActiveTextBuffer
                mov	cx,10h
                xor	ah,ah
                jmp	ProgramCrtcRegisters

InitializeBiosTextMode:
                mov	ax,40h
                mov	es,ax

                assume	es:BiosDataArea
                mov	cx,MONO_VIDEO_SEGMENT
                mov	ax,BIOS_TEXT_MODE_80X25
                int	BIOS_VIDEO_INTERRUPT
                cmp	byte ptr es:[BDA_VIDEO_MODE],DEFAULT_TEXT_ATTRIBUTE
                je	SelectTextVideoSegment
                mov	cx,COLOR_VIDEO_SEGMENT
SelectTextVideoSegment:
                mov	di,word ptr es:[BDA_CRTC_PORT]
                mov	es,cx

                assume	es:ActiveTextBuffer
                mov	dx,di
                and	dx,word ptr 0fff0h
                or	dx,word ptr 8
                mov	al,1
                out	dx,al
                mov	bx,dx
                and	dx,word ptr 0fff0h
                or	dx,word ptr 5
                xchg	dx,di
                mov	cx,2
                mov	si,offset MonoCrtcCursorLocation
                mov	ah,0eh
ProgramCrtcRegisters:
                cld
ProgramCrtcRegisters1:
                mov	al,ah
                out	dx,al
                inc	ah
                xchg	dx,di
                lodsb
                out	dx,al
                xchg	dx,di
                loop	ProgramCrtcRegisters1
                mov	dx,bx
CompleteDisplayInitialization:
                call	ClearScreen
EnableTextDisplay:
                mov	al,29h
                out	dx,al
                ret
InitializeDisplay               endp

ClearScreen     proc	near

                assume	ds:OptionRom, es:ActiveTextBuffer
                xor	di,di
                mov	cx,TEXT_CELL_COUNT
                mov	ax,CLEAR_TEXT_CELL
                cld
ClearScreen_1:
                stosb
                xchg	al,ah
                stosb
                xchg	al,ah
                loop	ClearScreen_1
                ret
ClearScreen     endp

MonoCrtcRegisterValues:
                db	61h, 50h, 52h, 0fh, 19h, 06h, 19h, 19h
                db	02h, 0dh, 0bh, 0ch, 00h, 00h, 00h, 00h

MonoCrtcCursorLocation          equ	MonoCrtcRegisterValues+0ch

Display         proc	near

                assume	ds:OptionRomData, es:nothing
                push	ds
                mov	es,DisplaySegment

                assume	es:ActiveTextBuffer
                push	cs
                pop	ds

                assume	ds:OptionRom
                mov	di,word ptr [si]
                mov	bl,byte ptr [si+2]
                mov	cl,byte ptr [si+3]
                xor	ch,ch
                lea	si,[si+4]
                cld
Display_1:
                movsb
                mov	al,bl
                stosb
                loop	Display_1
                pop	ds

                assume	ds:OptionRomData
                push	ds
                pop	es

                assume	es:OptionRomData
                ret
Display         endp

DisplayAndReset proc	near
                call	Display
                mov	cx,5dch
DisplayReset1:
                mov	ax,7d0h
DisplayReset2:
                dec	ax
                jne	DisplayReset2
                loop	DisplayReset1
                jmp	far ptr ResetVector
DisplayAndReset endp
