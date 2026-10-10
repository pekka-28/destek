; OptionRomUtilities.inc

; Shared MASM data-definition utilities for the option-ROM listing.

; MASM shortens these encodings even with explicit operand sizes.

IncCxLong       macro
                db	0ffh,0c1h

                endm

ZeroDisp        macro	prefix, opcode, modrm, value:=<>, size:=<>
                if	prefix
                db	prefix

                endif
                db	opcode,modrm,0

                ifnb	<value>
                size	value
                endif
                endm

; Preserve the ROM's F2 repeat prefix, which MASM rejects on MOVS/STOS.

RepneMovsb      macro
                db	0f2h

                movsb
                endm

RepneMovsw      macro
                db	0f2h

                movsw
                endm

RepneStosb      macro
                db	0f2h

                stosb
                endm

Message         macro	x, y, attr, len, msg
                dw	((y * TEXT_ROW_BYTES) + (x * TEXT_CELL_BYTES))
                db	attr
                db	len
                db	msg

                endm
