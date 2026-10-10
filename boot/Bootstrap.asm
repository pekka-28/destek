; Bootstrap.asm

; A 256-byte preamble, entered at 0040:7c00 before the bulk image.

bootstrap_entry equ	7c00h
BulkCode        segment	at 0050h
                org	5
BulkImage       label	far
BulkCode        ends
BootstrapCode   segment	byte public use16 'CODE'

                assume	cs:BootstrapCode, ds:nothing, es:nothing, ss:nothing

                org	bootstrap_entry

Startup         proc	near
                cli
                cld
                push	cs
                pop	ds

                assume	ds:BootstrapCode

; Write at the ROM's Loading position without clearing any cells.

                mov	ah,02h
                mov	bx,0007h
                mov	dx,0a1fh
                int	10h
                mov	si,offset StartingText
Startup1:
                lodsb
                or	al,al
                jz	short Startup2
                mov	ah,0eh
                push	si
                push	bx
                int	10h
                pop	bx
                pop	si
                jmp	short Startup1

Startup2:
                mov	ah,02h
                mov	dx,0c21h
                int	10h
                call	Initialise
                jmp	far ptr BulkImage
Startup         endp

StartingText    db	'Starting ...   ',0

                org	bootstrap_entry+128

Initialise      proc	near
                ret
Initialise      endp

; Place image-specific data after Initialise, within this preamble.

                org	bootstrap_entry+256
BootstrapCode   ends
                end
