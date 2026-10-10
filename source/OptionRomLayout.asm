; OptionRomLayout.asm

; Canonical source-composition entry point for the IBM 5150 option ROM.

; MASM 14.42 defaults to the 8086 instruction set.

; Compose-OptionRom.ps1 folds this include tree into the root listing.
; Definitions appear once, followed by fragments in ROM byte order.

                option	noscoped

                include	OptionRom.inc

                include	5150 Option ROM.asm
