; Hello.asm

; The ROM enters the standalone image at 0040:7c00.
; Normalise the standalone entry; staged startup enters Hello directly.

hello_origin    equ	0
StandaloneCode  segment	at 0800h
                org	5
NormalisedHello label	far
StandaloneCode  ends
Image           segment	byte public use16 'CODE'

                assume	cs:Image, ds:nothing, es:nothing, ss:nothing

                org	hello_origin
ImageStart      label	byte
                jmp	far ptr NormalisedHello

Hello           proc	near
                push	cs
                pop	ds

                assume	ds:Image

                cld
                mov	si,offset HelloText
                xor	bx,bx
                mov	bl,07h
                jmp	short Hello2

Hello1:
                mov	ah,0eh
                push	si
                push	bx
                int	10h
                pop	bx
                pop	si
Hello2:
                lodsb
                or	al,al
                jnz	Hello1
Hello3:
                cli
                jmp	short Hello3
Hello           endp

HelloText       db	'Hello, world!',0

                if	($-ImageStart) gt 128
                .err
                endif
                org	hello_origin+128
Image           ends
                end
