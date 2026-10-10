; OptionRomInitialization.inc

; Absolute segments used only while OptionRomEntry establishes the ROM
; runtime.

PcNetRelocationSource           segment	at 0c169h
PcNetRelocationPayload          label	byte
                org	010fh
PcNetRelocationCrc16Table       label	word
                org	030fh
PcNetRelocationPayloadLength    label	word
PcNetRelocationSource           ends

InitializationStack             segment	at 01fe0h
InitializationStack             ends
