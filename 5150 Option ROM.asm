; 5150 Option ROM.asm

; Self-contained MASM source composed from source/OptionRomLayout.asm.
; Regenerate with source/Compose-OptionRom.ps1.

; OptionRomLayout.asm

; Canonical source-composition entry point for the IBM 5150 option ROM.

; MASM 14.42 defaults to the 8086 instruction set.

; Compose-OptionRom.ps1 folds this include tree into the root listing.
; Definitions appear once, followed by fragments in ROM byte order.

                option	noscoped

; OptionRom.inc

; Recovered logical segments, constants, and MASM-compatible data
; macros.

; Pc5150Hardware.inc

; IBM PC/5150 mainboard hardware constants shared by ROM modules.

MONO_VIDEO_SEGMENT              equ	0b000h
COLOR_VIDEO_SEGMENT             equ	0b800h
MONO_MODE_CONTROL_PORT          equ	03b8h
MONO_CRTC_INDEX_PORT            equ	03b4h
MONO_CRTC_DATA_PORT             equ	03b5h
BDA_VIDEO_MODE  equ	49h
BDA_CRTC_PORT   equ	63h

; Intel 8259A programmable interrupt controller.

PIC_COMMAND_PORT                equ	20h
PIC_DATA_PORT   equ	21h
DMA_SINGLE_MASK_PORT            equ	0ah

; Intel 8253 programmable interval timer.

PIT_COUNTER0_PORT               equ	40h
PIT_COUNTER2_PORT               equ	42h
PIT_CONTROL_PORT                equ	43h
KBD_DATA_PORT   equ	60h
PPI_PORT_B      equ	61h
PPI_CONTROL_PORT                equ	63h

; Mainboard COM1, implemented by an 8250-compatible UART.

IBM_UART_DATA_PORT              equ	03f8h
IBM_UART_DIVISOR_LATCH_LOW_PORT equ	IBM_UART_DATA_PORT
IBM_UART_INTERRUPT_ENABLE_PORT  equ	03f9h
COM1_INTERRUPT_ID_PORT          equ	03fah
IBM_UART_LINE_CONTROL_PORT      equ	03fbh
IBM_UART_MODEM_CONTROL_PORT     equ	03fch
IBM_UART_LINE_STATUS_PORT       equ	03fdh
BIOS_VIDEO_INTERRUPT            equ	10h
BIOS_TEXT_MODE_80X25            equ	03h

; OptionRomAdapterHardware.inc

; Add-in adapter I/O assignments used by the transport probes and
; drivers.

LOCAL_AREA_RESET_PORT           equ	0220h
LOCAL_AREA_STATUS_PORT          equ	036eh

IBM_PC_NET_STATUS_PORT          equ	0360h
IBM_PC_NET_DATA_PORT            equ	0361h

EAGLE_USART_BASE_PORT           equ	0300h
EAGLE_USART_STATUS_PORT         equ	0302h
EAGLE_USART_CONTROL_PORT        equ	0304h

TIGAN_LAN_STATUS_PORT           equ	031eh
TIGAN_LAN_COMMAND_PORT          equ	031fh
TIGAN_LAN_PROBE_PORT            equ	071fh
TIGAN_LAN_CONFIGURATION_PORT    equ	231fh

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

; OptionRom contains the option-ROM code and static descriptors.

; The BIOS data area is used only while ES is explicitly assumed to
; address it.

OptionRom       segment	at 0c000h
OptionRom       ends

; Non-emitting interface declaration for a separately resident PC-NET
; ROM.
; Its implementation bytes are not part of this recovered C000h image.

PcNetDriverInterface            segment	at 0cc00h
                org	0003h
PcNetDriverEntry                label	far
PcNetDriverInterface            ends
ResetVectorSegment              segment	at 0ffffh
ResetVector     label	far
ResetVectorSegment              ends
MotherboardRomSegment           segment	at 0fe00h
                org	0049h
MotherboardRomEntry             label	far
MotherboardRomSegment           ends
InterruptVectorTable            segment	at 0000h
                org	0000h
Int0Vector      label	dword
                org	0080h
Int20Vector     label	dword
                org	0084h
Int21Vector     label	dword
                org	0088h
Int22Vector     label	dword
                org	008ch
Int23Vector     label	dword
                org	0090h
Int24Vector     label	dword
                org	0094h
Int25Vector     label	dword
                org	009ch
Int27Vector     label	dword
InterruptVectorTable            ends
BiosDataArea    segment	at 0040h
BiosDataArea    ends

; Lexical abstraction for the B000h or B800h segment in DisplaySegment.

ActiveTextBuffer                segment	at 0b000h
ActiveTextBuffer                ends

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

OptionRomData   segment	at 01fa0h

; Absolute image of the PC-NET runtime template relocated from
; c169:0000h.

PcNetRuntimeStash               label	byte
SerialInterruptDispatchTable    label	word
SerialInterruptCause0Handler    dw	?
SerialInterruptCause2Handler    dw	?
SerialInterruptCause4Handler    dw	?
SerialInterruptCause6Handler    dw	?
                org	0018h
AdapterStatusPort               dw	?
AdapterDataPort dw	?
SerialOutputCallback            label	word
TransportOutputCallback         dw	?
                org	001eh
LocalAreaNetworkStepCallback    label	word
IbmPcNetStepCallback            label	word
SerialStepCallback              label	word
TiganLanStepCallback            label	word
TransportStepCallback           dw	?
LocalAreaNetworkRestartCallback label	word
IbmPcNetRestartCallback         label	word
SerialRestartCallback           label	word
TiganLanRestartCallback         label	word
TransportRestartCallback        dw	?
SerialTransportRestart          equ	PcNetServiceStubTable
                org	0022h
EagleUsartServiceCallback       label	word
IbmUartServiceCallback          label	word
TransportServiceCallback        dw	?
EagleUsartReturnCallback        label	word
IbmUartReturnCallback           label	word
TransportReturnCallback         dw	?
                org	0026h
RemainingImageBlocks            dw	?
ReceiveSlotIndex                dw	?
                org	002ah
DisplaySegment  dw	?
NodeAddress     dw	?
BootTimeoutTicks                dw	?
                org	0030h

; Display mode-control I/O port: 03b8h for MDA or 03d8h for colour text.

DisplayModeControlPort          dw	?
                org	0032h
SavedReceivePrefixLow           dw	?
SavedReceivePrefixHigh          dw	?
                org	0036h
TransportContinuation           label	dword
                org	003ah
CallerStackSegment              dw	?
CallerStackPointer              dw	?
                org	003eh

; These shared workspace words are queue links for Tigan and CRCs for
; serial.

TiganLanRequestQueueHead        label	word
SerialReceiveCrc16              label	word
                org	0040h
TiganLanRequestQueueTail        label	word
SerialTransmitCrc16             label	word
                org	0042h

; The relocated template initializes this as 010fh:0000h.

Crc16TablePointer               dword	?
                org	0047h

; IRQ0 countdowns and the remaining consecutive retry-timeout budget.

DelayedAckTicks db	?
DataRetryTicks  db	?
ControlRetryTicks               db	?
RetryTimeoutBudget              db	?
                org	004fh

; Shared transport state byte. Serial uses a transmit-state index;
; PC-NET and Tigan use independent, transport-specific flag layouts.

TransportState  db	?
                org	0053h
PendingControlClass             db	?
                org	0059h
StartupControlClass             db	?
                org	005ah

; PIC IRQ bits accumulated by the successful transport probe.

TransportIrqMask                db	?
DataRetryInterval               db	?
ControlRetryInterval            db	?
AckDelayInterval                db	?
SessionFlags    db	?
                org	0060h
FunctionKeyMenuRequested        db	?
                org	0094h
PcNetRuntimeAdapterCommand      label	byte
                org	00a2h
PcNetRuntimeAdapterConfiguration                label	word
                org	00b4h
PcNetRuntimeBufferDescriptor0   label	byte
                org	00c6h
PcNetRuntimeBufferDescriptor1   label	byte
                org	00fdh

; Header node address copied before a transport makes it active.

ConfiguredNodeAddress           dw	?
                org	0107h
PcNetRuntimeByte0107            label	byte
                org	0109h

; Initial/menu request code, then the first requested image slot.

BootRequestWord label	word
PcNetRuntimeWord0109            label	word
                org	010bh

; Client mask and selection index, then the last requested image slot.

BootRequestArgument             label	word
PcNetRuntimeWord010B            label	word
                org	010ch
BootMenuSelection               label	byte
                org	010dh
PcNetRuntimeByte010D            label	byte
                org	010fh
PcNetRuntimeCrc16Table          label	word
                org	030fh
PcNetRuntimeStashEnd            label	byte
OptionRomData   ends

TEXT_COLUMNS    equ	80
TEXT_ROWS       equ	25
TEXT_CELL_BYTES equ	2
TEXT_ROW_BYTES  equ	TEXT_COLUMNS * TEXT_CELL_BYTES
TEXT_CELL_COUNT equ	TEXT_COLUMNS * TEXT_ROWS

DEFAULT_TEXT_ATTRIBUTE          equ	07h
CLEAR_TEXT_CELL equ	(DEFAULT_TEXT_ATTRIBUTE shl 8) or ' '

; 5150 Option ROM.asm

; MASM reassembly source for 5150 Option ROM.bin.

OptionRom       segment	at 0c000h

                assume	cs:OptionRom, ds:OptionRom, es:nothing, ss:nothing
OptionRomHeader:
OptionRomSignature:
                dw	0aa55h

OptionRomSizeBlocks:
                db	10h

                jmp	OptionRomEntry

OptionRomChecksum:
                db	79h

RomConfigurationFlags:
                db	00h

LocalAreaNetworkInitializationPayload           label	byte
RomNodeAddress:
                db	36h

; This 19-byte header range is sent unchanged during local-area setup.
; The Destek Z80 receives it at 2040h in SUB11 (056ch).

RomHeaderReserved08:
                db	8 dup (00h)

RomHeaderUnknown10:
                db	0ffh

RomHeaderUnknown11:
                db	00h

RomHeaderUnknown12:

; Maps to Z80 204bh: record capacity in four-byte units (22h = 136).

                db	22h

RomHeaderReserved13:
                db	0ch dup (00h)

FunctionKeyEnableMask:
                db	0ffh

LocalAreaNetworkInitializationPayloadLength     equ	13h
ManufacturerString:
                db	'MAGIX COPR. SABAKI ENTERPRISES, INC. 1985'

; Establish ROM environment; mask IRQs and acknowledge keyboard.

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

; OptionRomInterruptUtilities.inc

; Install IRQ handlers and initialise the Intel 8259A PIC.

InstallInterruptVectors         proc	near
                xor	ax,ax
                mov	ds,ax

                assume	ds:InterruptVectorTable
                mov	word ptr Int20Vector,TimerInterruptHandler
                mov	word ptr Int20Vector+2,cs
                mov	word ptr Int22Vector,SharedNetworkInterruptHandler
                mov	word ptr Int22Vector+2,cs
                mov	word ptr Int23Vector,LocalAreaNetworkInterruptHandler
                mov	word ptr Int23Vector+2,cs
                mov	word ptr Int24Vector,IbmUartInterruptHandler
                mov	word ptr Int24Vector+2,cs
                mov	word ptr Int25Vector,EagleUsartInterruptHandler
                mov	word ptr Int25Vector+2,cs
                mov	word ptr Int27Vector,LocalAreaNetworkInterruptHandler
                mov	word ptr Int27Vector+2,cs
                push	cs
                pop	ds

                assume	ds:OptionRom
                mov	al,13h
                out	PIC_COMMAND_PORT,al
                mov	al,20h
                out	PIC_DATA_PORT,al
                mov	al,0fh
                out	PIC_DATA_PORT,al
                mov	al,0feh
                out	PIC_DATA_PORT,al
                ret
InstallInterruptVectors         endp

Version_2_20:
                Message	31, 8, 07h, 0eh, 'VERSION:  2.20'

Loading:
                Message	31, 10, 87h, 0fh, '... LOADING ...'

NoNetworkFound:
                Message	26, 10, 0f0h, 18h, '!!! NO NETWORK FOUND !!!'

FromLocalAreaNetwork:
                Message	26, 12, 07h, 17h, 'FROM LOCAL AREA NETWORK'

FromIBMPcNet:
                Message	31, 12, 07h, 0fh, 'FROM IBM PC-NET'

FromEagleUsart:
                Message	31, 12, 07h, 10h, 'FROM EAGLE USART'

FromIBMUart:
                Message	32, 12, 07h, 0dh, 'FROM IBM UART'

TimeOut:
                Message	30, 16, 70h, 10h, '!!! TIME OUT !!!'

DuplicateAddr:
                Message	27, 16, 70h, 15h, '!!! DUPLICATE ADDR !!!'

LanBoardFailed:
                Message	26, 16, 70h, 18h, '!!! LAN BOARD FAILED !!!'

CheckServer:
                Message	28, 16, 70h, 14h, '!!! CHECK SERVER !!!'

BadInterrupt:
                Message	27, 16, 70h, 15h, '!!! BAD INTERRUPT !!!'

SelectTransport proc	near

                assume	ds:OptionRomData, es:OptionRomData
                mov	bx,word ptr cs:[RomNodeAddress]
                mov	word ptr ConfiguredNodeAddress,bx
                call	TestLocalAreaNetwork
                jne	Select1
                call	TestTiganLan
                je	Select1
                call	SelectIBMPcNet
                je	Select1
                call	TestEagleUsart
                jne	Select1
                call	TestIBMUart
                je	ShowNoNetworkFound

; Unmask the selected transport IRQ at the Intel 8259A PIC.

Select1:
                mov	ah,byte ptr TransportIrqMask
                not	ah
                in	al,PIC_DATA_PORT
                and	al,ah
                out	PIC_DATA_PORT,al
                ret
SelectTransport endp

ShowNoNetworkFound              proc	near
                mov	si,NoNetworkFound
                call	Display
NoNetworkFixedPoint:
                jmp	NoNetworkFixedPoint
ShowNoNetworkFound              endp

; Reset and probe the local-area adapter before committing callbacks.

TestLocalAreaNetwork            proc	near

; Probe the two local-area port pairs, accept a zero status reply,
; send the ROM initialisation payload, then install the callbacks.

                test	byte ptr cs:[RomConfigurationFlags],40h
                je	TestLan1
                xor	ax,ax
                ret

TestLan1:
                mov	dx,LOCAL_AREA_RESET_PORT
                out	dx,al
                mov	dx,LOCAL_AREA_STATUS_PORT
                out	dx,al
                mov	bx,9080h
                mov	cx,2800h
TestLan2:
                loop	TestLan2
TestLan3:
                mov	cx,1000h
TestLan4:
                in	al,dx
                IncCxLong
                test	al,80h
                loope	TestLan4
                je	TestLan5
                or	dl,1h
                in	al,dx
                IncCxLong
                cmp	al,6fh
                jbe	TestLan6
TestLan5:
                mov	ax,dx
                mov	bl,8h
                mov	dx,LOCAL_AREA_RESET_PORT
                and	al,0feh
                cmp	ax,LOCAL_AREA_RESET_PORT
                jne	TestLan3
                ret

TestLan6:
                or	al,al
                jne	ShowLanBoardFailed
                or	byte ptr TransportIrqMask,bl
                mov	byte ptr ds:[46h],bh
                mov	ax,ConfiguredNodeAddress
                mov	NodeAddress,ax
                mov	si,FromLocalAreaNetwork
                call	Display
                mov	si,offset LocalAreaNetworkInitializationPayload
                mov	cx,LocalAreaNetworkInitializationPayloadLength

; Match the Z80 reset/configuration exchange: send 19 bytes, then
; require its zero completion status before installing callbacks.

                push	ds
                push	cs
                pop	ds
                call	WriteAdapterBytes
                pop	ds
                and	dl,0feh
TestLan7:
                in	al,dx
                test	al,80h
                je	TestLan7
                or	dl,1h
                in	al,dx
                or	al,al
                je	TestLan8
ShowLanBoardFailed:
                mov	si,LanBoardFailed
                jmp	near ptr DisplayAndReset

TestLan8:
                mov	word ptr AdapterDataPort,dx
                and	dl,0feh
                mov	word ptr AdapterStatusPort,dx
                mov	al,8h
                mov	DataRetryInterval,al
                mov	al,14h
                mov	ControlRetryInterval,al
                mov	al,3h
                mov	AckDelayInterval,al
                mov	ax,LocalAreaNetworkStep
                mov	LocalAreaNetworkStepCallback,ax
                mov	ax,LocalAreaNetworkRestart
                mov	LocalAreaNetworkRestartCallback,ax
                or	ax,ax
                ret
TestLocalAreaNetwork            endp

SelectIBMPcNet  proc	near
                test	byte ptr cs:[RomConfigurationFlags],20h
                jne	SelectPcNet1
                xor	ax,ax
                mov	es,ax
                mov	ax,es:[172h]
                push	ds
                pop	es
                cmp	ax,word ptr 0cc00h
                jne	SelectPcNet1
                call	TestIBMPcNet
                mov	ax,IbmPcNetStep
                mov	IbmPcNetStepCallback,ax
                mov	ax,IbmPcNetRestart
                mov	IbmPcNetRestartCallback,ax
                xor	ax,ax
SelectPcNet1:
                ret
SelectIBMPcNet  endp

TestIBMPcNet    proc	near
                mov	ax,ConfiguredNodeAddress
                mov	NodeAddress,ax
                mov	si,FromIBMPcNet
                call	Display
                or	byte ptr TransportIrqMask,4h
                mov	byte ptr ds:[46h],0c0h
                mov	word ptr AdapterDataPort,IBM_PC_NET_DATA_PORT
                mov	word ptr AdapterStatusPort,IBM_PC_NET_STATUS_PORT
                mov	byte ptr DataRetryInterval,0ch
                mov	byte ptr ControlRetryInterval,14h
                mov	byte ptr AckDelayInterval,4h
                mov	byte ptr ds:[56h],3h
                mov	byte ptr ds:[4dh],5h
                mov	ax,ds
                mov	bx,0d8h
                mov	byte ptr [bx+3h],1h
                mov	si,offset PcNetRuntimeAdapterConfiguration
                call	SegmentedToLinear
                mov	ax,1f60h
                xor	bx,bx
                mov	ds:[88h],ax
                mov	ds:[8ch],ax
                mov	word ptr ds:[86h],bx
                mov	word ptr ds:[8eh],bx
                add	word ptr ds:[8eh],word ptr 7h
                mov	es,ax
                mov	cx,word ptr NodeAddress
                ZeroDisp	26h,89h,4fh     ; mov es:[bx+0],cx
                push	ds
                pop	es
                push	ax
                mov	si,offset PcNetRuntimeBufferDescriptor0
                call	SegmentedToLinear
                pop	ax
                add	bx,word ptr 200h
                mov	word ptr ds:[8ah],bx
                mov	si,offset PcNetRuntimeBufferDescriptor1
SegmentedToLinear:
                mov	cx,4h
                rol	ax,cl
                mov	cl,al
                and	cl,0fh
                and	al,0f0h
                add	ax,bx
                adc	cl,ch
                mov	byte ptr [si+6h],cl
                mov	byte ptr [si+8h],al
                mov	byte ptr [si+0ah],ah
                ret
TestIBMPcNet    endp

; Probe the Eagle USART, then install its adapter callbacks.

TestEagleUsart  proc	near
                mov	dh,3h
                mov	dl,0h
                in	al,dx
                IncCxLong
                cmp	al,0ffh
                je	TestEagle2
                mov	si,FromEagleUsart
                call	Display
                mov	byte ptr ds:[46h],0h
                mov	word ptr AdapterStatusPort,dx
                mov	al,9h
                out	dx,al
                mov	al,40h
                out	dx,al
                call	InitializeSerialTransport
                mov	ah,al
                mov	al,0ch
                out	dx,al
                mov	al,ah
                dec	al
                dec	al
                out	dx,al
                out	dx,al
                mov	si,EagleUsartInitializationBytes
                mov	cx,18h
                cld
TestEagle1:
                lods	byte ptr cs:[si]
                out	dx,al
                nop
                nop
                nop
                loop	TestEagle1
                mov	dl,1h
                mov	word ptr AdapterDataPort,dx
                mov	dx,EAGLE_USART_CONTROL_PORT
                mov	al,8h
                out	dx,al
                or	byte ptr TransportIrqMask,20h
                mov	bx,0h
                ZeroDisp	0,0c7h,47h,PcNetServiceDispatchOutput,dw
                mov	word ptr [bx+SerialInterruptCause4Handler-SerialInterruptDispatchTable],PcNetServiceReceiveData
                mov	word ptr [bx+SerialInterruptCause6Handler-SerialInterruptDispatchTable],PcNetServiceAdapterService
                mov	ax,EagleReadAndWriteCommand30
                mov	EagleUsartServiceCallback,ax
                mov	ax,EagleWriteCommand28
                mov	EagleUsartReturnCallback,ax
                or	ax,ax
TestEagle2:
                ret
TestEagleUsart  endp

InitializeSerialTransport       proc	near
                mov	word ptr ds:[44h],ds
                mov	al,50h
                mov	DataRetryInterval,al
                mov	al,28h
                mov	ControlRetryInterval,al
                mov	al,4h
                mov	AckDelayInterval,al
                mov	ax,AdapterWriteByte
                mov	SerialOutputCallback,ax
                mov	ax,PcNetServicePollOutput
                mov	SerialStepCallback,ax
                mov	ax,SerialTransportRestart
                mov	SerialRestartCallback,ax
                mov	ah,byte ptr cs:[RomConfigurationFlags]
                and	ah,3h
                mov	al,0ch
                mov	cx,60h
InitSerial1:
                dec	ah
                js	InitSerial2
                shl	al,1
                shr	cl,1
                add	byte ptr DataRetryInterval,28h
                jmp	InitSerial1

InitSerial2:
                push	ax
                push	es
                mov	ax,cx
                aam
                or	ax,word ptr 3030h
                mov	es,word ptr DisplaySegment
                mov	byte ptr es:[4h],ah
                mov	es:[6h],al
                pop	es
                pop	ax
                ret
InitializeSerialTransport       endp

EagleUsartInitializationBytes:
                db	10h, 30h, 0dh, 00h, 0ah, 00h, 0bh, 50h
                db	0eh, 03h, 0fh, 00h, 02h, 00h, 04h, 44h
                db	01h, 16h, 05h, 0eah, 03h, 0c1h, 09h, 09h

; Probe and configure COM1, then install serial callbacks.

TestIBMUart     proc	near
                mov	dh,3h
                mov	dl,0fah
                in	al,dx
                IncCxLong
                not	al
                and	al,0f8h
                je	TestIBMUart1
                mov	si,FromIBMUart
                call	Display
                mov	byte ptr ds:[46h],1h
                call	InitializeSerialTransport
                mov	ah,al
                mov	dl,0fbh
                mov	al,80h
                out	dx,al
                mov	dl,0f8h
                mov	al,ah
                out	dx,al
                mov	si,IbmUartInitializationPairs
                mov	cx,4h
                cld

; Write the IBM UART register/value initialization pairs.

TestUart1:
                lods	byte ptr cs:[si]
                mov	dl,al
                lods	byte ptr cs:[si]
                out	dx,al
                loop	TestUart1
                mov	word ptr AdapterDataPort,IBM_UART_DATA_PORT
                mov	word ptr AdapterStatusPort,IBM_UART_LINE_STATUS_PORT
                or	byte ptr TransportIrqMask,10h
                mov	bx,0h
                mov	word ptr [bx+SerialInterruptCause2Handler-SerialInterruptDispatchTable],PcNetServiceDispatchOutput
                mov	word ptr [bx+SerialInterruptCause4Handler-SerialInterruptDispatchTable],PcNetServiceReceiveData
                mov	word ptr [bx+SerialInterruptCause6Handler-SerialInterruptDispatchTable],PcNetServiceAdapterService
                ZeroDisp	0,0c7h,47h,IbmUartReturn,dw
                mov	ax,IbmUartReadPortFd
                mov	IbmUartServiceCallback,ax
                mov	ax,IbmUartReturn
                mov	IbmUartReturnCallback,ax
                or	ax,ax
TestIBMUart1:
                ret
TestIBMUart     endp

IbmUartInitializationPairs:
                db	0f9h, 00h               ; 03f9h: disable UART interrupts.
                db	0fbh, 03h               ; 03fbh: select 8 data bits, one stop bit.
                db	0fch, 0bh               ; 03fch: assert DTR, RTS, and OUT2.
                db	0f9h, 07h               ; 03f9h: enable RX, TX, and line-status IRQs.

; Service timeout counters, then rearm PIT channel 0.

TimerInterruptHandler           proc	near
                push	ax
                call	DispatchInterruptContinuation
                test	byte ptr DataRetryTicks,0ffh
                je	TimerIrq1
                dec	byte ptr DataRetryTicks
                jne	TimerIrq1
                dec	byte ptr RetryTimeoutBudget
                je	ShowTimeOut
                call	ResumeTransportSession
                jmp	TimerIrq3

TimerIrq1:
                test	byte ptr ControlRetryTicks,0ffh
                je	TimerIrq2
                dec	byte ptr ControlRetryTicks
                jne	TimerIrq2
                dec	byte ptr RetryTimeoutBudget
                je	ShowTimeOut
                call	RunTransportStateMachine
                jmp	TimerIrq3

TimerIrq2:
                test	byte ptr DelayedAckTicks,0ffh
                je	TimerIrq3
                dec	byte ptr DelayedAckTicks
                jne	TimerIrq3
                call	RequestSessionAck
TimerIrq3:
                dec	word ptr BootTimeoutTicks
                je	ShowTimeOut
                mov	al,30h
                out	PIT_CONTROL_PORT,al
                mov	al,36h
                out	PIT_COUNTER0_PORT,al
                mov	al,74h
                out	PIT_COUNTER0_PORT,al
                ret
TimerInterruptHandler           endp

ShowTimeOut:
                mov	si,TimeOut              ; c59a: beh, cfh, 01h
                jmp	near ptr DisplayAndReset ; c59d: e9h, 6dh, 04h

; The dispatch wrapper calls the handler body and owns the final IRET.
; EagleIrq2 is also the shared RET used by UART and local-area IRQs.

EagleUsartInterruptHandler      proc	near
                push	ax
                call	DispatchInterruptContinuation
                mov	dx,EAGLE_USART_CONTROL_PORT
                mov	al,18h
                out	dx,al
                in	al,dx
                test	al,0f9h
                jne	EagleIrq3
                mov	bx,offset SerialInterruptDispatchTable
                xor	ah,ah
                add	bx,ax
                xor	al,al
                out	dx,al
                call	word ptr [bx]
                mov	dx,EAGLE_USART_STATUS_PORT
                mov	al,38h
                out	dx,al
EagleIrq1:
                mov	dl,4h
                mov	al,8h
                out	dx,al
EagleIrq2:
                ret

EagleIrq3:
                inc	al
                jne	ShowBadInterrupt
                out	dx,al
                jmp	EagleIrq1
EagleUsartInterruptHandler      endp

; Drain pending interrupt causes, then use EagleIrq2's shared RET.

IbmUartInterruptHandler         proc	near
                push	ax
                call	DispatchInterruptContinuation
UartIrq1:
                mov	dx,COM1_INTERRUPT_ID_PORT
                in	al,dx
                test	al,1h
                jne	EagleIrq2
                and	ax,word ptr 6h
                mov	bx,offset SerialInterruptDispatchTable
                add	bx,ax
                call	word ptr [bx]
                jmp	UartIrq1
IbmUartInterruptHandler         endp

; Service frames while adapter status bit 7 is set. EagleIrq2 is the
; shared RET to DispatchInterruptContinuation, which restores AX and
; completes the hardware interrupt with IRET.

LocalAreaNetworkInterruptHandler                proc	near
                push	ax
                call	DispatchInterruptContinuation

; Poll adapter status until pending adapter work has been serviced.

LocalIrq1:
                mov	dx,word ptr AdapterStatusPort
                in	al,dx
                test	al,80h
                je	EagleIrq2
                call	LocalAreaNetworkReceiveService
                jmp	LocalIrq1
LocalAreaNetworkInterruptHandler                endp

SharedNetworkInterruptHandler:
                push	ax                      ; c5f8: 50h
                call	DispatchInterruptContinuation ; c5f9: e8h, 21h, 00h
                test	byte ptr ds:[46h],40h   ; c5fc: f6h, 06h, 46h, 00h, 40h
                jne	LC606                   ; c601: 75h, 03h
                jmp	near ptr ServiceTiganLanInterrupt ; c603: e9h, 4dh, 0eh

LC606:
                jmp	near ptr ServiceIbmPcNetInterrupt ; c606: e9h, 1eh, 0bh

ShowBadInterrupt:
                mov	si,BadInterrupt         ; c609: beh, 31h, 02h
                jmp	ResetAfterError         ; c60c: ebh, 0ch

; Discard the return address and inspect the stacked error argument.
; Low byte 10h selects duplicate-address; all other values select
; board failure. Neither path returns to its caller.

AbortNetworkOperation           proc	near
                pop	ax
                pop	ax
                cmp	al,10h
                je	ShowDuplicateAddr
                jmp	near ptr ShowLanBoardFailed
AbortNetworkOperation           endp

ShowDuplicateAddr:
                mov	si,DuplicateAddr        ; c617: beh, e3h, 01h

; Shared fatal exit after the caller selects a message in SI.

ResetAfterError proc	near
                jmp	near ptr DisplayAndReset
ResetAfterError endp

DispatchInterruptContinuation:
                pop	ax                      ; c61d: 58h
                call	ax                      ; c61e: ffh, d0h
                pop	ax                      ; c620: 58h
                iret                            ; c621: cfh

; OptionRomSerialCallbacks.inc

AdapterWriteByte                proc	near
                out	dx,al
IbmUartReturn:
                ret
AdapterWriteByte                endp

EagleWriteCommand28             proc	near
                mov	al,28h
                out	dx,al
                ret
EagleWriteCommand28             endp

EagleReadAndWriteCommand30      proc	near
                in	al,dx
                and	dl,2h
                mov	al,30h
                out	dx,al
                ret
EagleReadAndWriteCommand30      endp

IbmUartReadPortFd               proc	near
                in	al,dx
                mov	dl,0fdh
                in	al,dx
                ret
IbmUartReadPortFd               endp

; Apply peer counters and cancel acknowledged retry timers.
; DATA (BL=0) returns with ZF set; RETRY (BL=3) returns with ZF clear.
; Other classes discard one return address and resume the session.
; The caller must provide that disposable near-call stack frame.

ProcessSessionHeader            proc	near
                mov	byte ptr RetryTimeoutBudget,0ah
                mov	al,ds:[7ch]
                cmp	al,byte ptr ds:[4bh]
                je	SessionHead1
                mov	ds:[4bh],al
                mov	byte ptr ControlRetryTicks,0h
SessionHead1:
                mov	al,ds:[7bh]
                cmp	al,byte ptr ds:[4ch]
                jne	SessionHead2
                mov	byte ptr DataRetryTicks,0h
                and	byte ptr SessionFlags,0bfh
                test	byte ptr SessionFlags,20h
                je	SessionHead2
                call	AdvanceTransportSession
SessionHead2:
                cmp	bl,3h
                jne	SessionHead3
                or	bl,bl
                ret

SessionHead3:
                cmp	bl,0h
                jne	SessionHead4
                ret

SessionHead4:
                pop	ax
                cmp	bl,2h
                jne	RunTransportStateMachine
ProcessSessionHeader            endp

; Fall through with ACK as the pending control class.

RequestSessionAck               proc	near
                mov	al,1h
RequestSessionAck               endp

; Keep the higher-priority pending control class, then run the session.

QueueSessionControl             proc	near
                cmp	al,byte ptr PendingControlClass
                jbe	RunTransportStateMachine
                mov	PendingControlClass,al
QueueSessionControl             endp

; Wait for transport readiness. Choose pending control output first,
; otherwise retry a control exchange or submit the current DATA record.
; The restart callback is a tail call using this caller's return frame.

RunTransportStateMachine        proc	near
                call	word ptr TransportStepCallback
                jne	RunState1
                mov	bl,byte ptr PendingControlClass
                or	bl,bl
                jne	RunState4
                test	byte ptr SessionFlags,80h
                jne	RunState2
RunState1:
                ret

RunState2:
                mov	al,ds:[4bh]
                cmp	al,byte ptr ds:[4ch]
                jns	RunState5
                test	byte ptr ControlRetryTicks,0ffh
                jne	RunState1
                mov	al,ControlRetryInterval
                mov	ControlRetryTicks,al
                mov	bl,byte ptr StartupControlClass
                or	bl,bl
                jne	RunState3
                mov	bl,2h
RunState3:
                mov	byte ptr PendingControlClass,bl
RunState4:
                xor	si,si
                jmp	RunState6

RunState5:
                mov	bl,0h
                mov	al,ds:[4ch]
                mov	ds:[102h],al
                mov	ds:[108h],al
                mov	byte ptr SessionFlags,40h
                mov	si,105h
                mov	al,DataRetryInterval
                mov	DataRetryTicks,al
RunState6:
                mov	byte ptr DelayedAckTicks,0h
                mov	al,ds:[4eh]
                mov	ds:[103h],al
                mov	al,ds:[4dh]
                mov	ds:[104h],al
                jmp	word ptr TransportRestartCallback
RunTransportStateMachine        endp

ResumeTransportSession          proc	near
                or	byte ptr SessionFlags,80h
                jmp	RunTransportStateMachine
ResumeTransportSession          endp

AcquireReceiveBuffer            proc	near
                mov	word ptr BootTimeoutTicks,258h
                xor	ax,ax
                mov	ax,40h
                mov	es,ax
                mov	ax,ReceiveSlotIndex
                cmp	ax,word ptr 1h
                ja	AcquireReceive1
                mov	di,800h
                mov	es,di
AcquireReceive1:
                ror	ax,1
                xchg	al,ah
                mov	di,ax
                sub	di,word ptr 4h
                mov	ax,word ptr es:[di]
                mov	SavedReceivePrefixLow,ax
                mov	ax,word ptr es:[di+2h]
                mov	SavedReceivePrefixHigh,ax
                ret
AcquireReceiveBuffer            endp

LC72C:
                ret                             ; c72c: c3h

ProcessReceivedBuffer           proc	near
                inc	byte ptr ds:[4eh]

; Tigan enters here after incrementing the receive counter itself.

ProcessReceive1:
                mov	di,bx
                mov	bl,byte ptr es:[di+3h]
                mov	ax,SavedReceivePrefixLow
                mov	word ptr es:[di],ax
                mov	ax,SavedReceivePrefixHigh
                mov	word ptr es:[di+2h],ax
                inc	byte ptr ds:[4dh]
                and	bl,7fh
                jne	ProcessReceive2
                mov	si,CheckServer
                jmp	DisplayAndReset

ProcessReceive2:
                cmp	bl,0dh
                je	ProcessReceive8
                cmp	bl,0ch
                je	ProcessReceive3
                jmp	ShowDuplicateAddr

ProcessReceive3:
                push	ds
                mov	ds,word ptr DisplaySegment
                inc	byte ptr ds:[0h]
                pop	ds
                mov	ax,BootRequestWord
                or	ax,ax
                jns	ProcessReceive6
                cmp	word ptr ReceiveSlotIndex,word ptr 0h
                je	ProcessReceive4

; The second introductory record completes the downloaded menu.

                inc	byte ptr FunctionKeyMenuRequested
                jmp	ProcessReceive8

ProcessReceive4:
                mov	ax,word ptr es:[di+4h]
                or	ax,ax
                jne	ProcessReceive5

; A zero selector keeps request mode and advances to the menu's tail.

                inc	word ptr ReceiveSlotIndex
                jmp	ProcessReceive8

ProcessReceive5:

; A counted-image response replaces the menu with the selected image.

                mov	RemainingImageBlocks,ax
                mov	word ptr BootRequestArgument,0ffffh
                mov	ax,word ptr es:[di+6h]
                mov	word ptr TransportContinuation,ax
                jmp	ProcessReceive7

ProcessReceive6:
                dec	word ptr RemainingImageBlocks
                je	SetInt0OffsetFromRomConfiguration
                mov	ax,ReceiveSlotIndex
                inc	word ptr ReceiveSlotIndex
                cmp	ax,word ptr BootRequestArgument
                jne	ProcessReceive8
ProcessReceive7:
                call	AdvanceTransportSession
ProcessReceive8:
                push	ds
                pop	es
                test	byte ptr DelayedAckTicks,0ffh
                jne	ProcessReceive9
                mov	al,AckDelayInterval
                mov	DelayedAckTicks,al
ProcessReceive9:
                ret
ProcessReceivedBuffer           endp

SetInt0OffsetFromRomConfiguration               proc	near
                xor	bx,bx
                mov	es,bx

                assume	es:InterruptVectorTable
                mov	al,byte ptr cs:[RomNodeAddress]
                mov	ah,byte ptr cs:[RomConfigurationFlags]
                mov	word ptr es:[bx],ax
                mov	byte ptr PendingControlClass,6h
                ret

                assume	es:nothing
SetInt0OffsetFromRomConfiguration               endp

AdvanceTransportSession         proc	near
                test	byte ptr SessionFlags,0c0h
                je	AdvanceTransportSession1
                or	byte ptr SessionFlags,20h
                ret

AdvanceTransportSession1:
                mov	ax,BootRequestArgument
                inc	ax
                mov	BootRequestWord,ax
                mov	ax,8h
                cmp	ax,word ptr RemainingImageBlocks
                jbe	AdvanceTransportSession2
                mov	ax,RemainingImageBlocks
AdvanceTransportSession2:
                add	word ptr BootRequestArgument,ax
AdvanceTransportSession3:
                inc	byte ptr ds:[4ch]
                mov	byte ptr SessionFlags,80h
                ret
AdvanceTransportSession         endp

ShowAddress     proc	near

                assume	ds:OptionRomData

; Present the assigned node address once, then service menu and
; completion.

                cmp	byte ptr ds:[5fh],0h
                jne	ShowAddr1
                cmp	word ptr NodeAddress,word ptr 0h
                je	ShowAddr1
                inc	byte ptr ds:[5fh]
                cli
                mov	si,Address
                call	Display
                mov	es,word ptr DisplaySegment

                assume	es:ActiveTextBuffer
                mov	ax,NodeAddress
                mov	cl,64h
                div	cl
                or	al,30h
                stosb
                mov	al,bl
                stosb
                mov	al,ah
                xor	ah,ah
                aam
                or	ax,word ptr 3030h
                xchg	al,ah
                stosb
                mov	al,bl
                stosb
                mov	al,ah
                stosb
                mov	al,bl
                stosb
                push	ds
                pop	es

                assume	es:OptionRomData
                sti
ShowAddr1:
                cmp	byte ptr FunctionKeyMenuRequested,0h
                je	ShowAddr2
                call	WriteFunctionKeyMenu
ShowAddr2:
                cmp	word ptr RemainingImageBlocks,word ptr 0h
                jne	ShowAddress
ShowAddr3:

; Wait for the last protocol transmission before restoring the BIOS.

                cmp	byte ptr PendingControlClass,6h
                je	ShowAddr3
                mov	dx,word ptr AdapterStatusPort
                test	byte ptr ds:[46h],81h
                js	ShowAddr5
                je	ShowAddr8
ShowAddr4:
                in	al,dx
                test	al,40h
                je	ShowAddr4
                jmp	ShowAddr9

ShowAddr5:
                mov	cx,2000h
ShowAddr6:
                loop	ShowAddr6
                test	byte ptr ds:[46h],40h
                jne	ShowAddr9
                mov	al,80h
                out	dx,al
                jmp	ShowAddr7

ShowAddr7:
                xor	al,al
                out	dx,al
                jmp	ShowAddr9

ShowAddr8:
                mov	al,1h
                out	dx,al
                nop
                in	al,dx
                test	al,1h
                je	ShowAddr8
ShowAddr9:
                jmp	RestoreBiosAndTransferControl
ShowAddress     endp

Address:
                Message	32, 14, 0fh, 09h, 'ADDRESS: '

; Restore BIOS state, then transfer to the selected continuation.

RestoreBiosAndTransferControl   proc	near

                assume	ds:OptionRomData

; Bypass BIOS restoration when executing in the motherboard-ROM segment.

                cli
                mov	ax,cs
                cmp	ax,word ptr 0fe00h
                je	RestoreBios2

; Restore the single PIC's BIOS vector base, then enable IRQ0 and IRQ1.

                mov	al,13h
                out	PIC_COMMAND_PORT,al
                mov	al,8h
                out	PIC_DATA_PORT,al
                mov	al,9h
                out	PIC_DATA_PORT,al
                mov	al,0fch
                out	PIC_DATA_PORT,al

; Restore the BIOS timer divisor and acknowledge the keyboard latch.

                mov	al,36h
                out	PIT_CONTROL_PORT,al
                xor	al,al
                out	PIT_COUNTER0_PORT,al
                out	PIT_COUNTER0_PORT,al
                in	al,KBD_DATA_PORT
                mov	al,0c0h
                out	PPI_PORT_B,al
                jmp	RestoreBios1

RestoreBios1:
                mov	al,4ch
                out	PPI_PORT_B,al
                xor	ax,ax
                mov	es,ax

                assume	es:InterruptVectorTable
                xor	bx,bx
                dec	ax
                mov	word ptr es:[Int20Vector],bx
                mov	word ptr es:[Int20Vector+2],ax
                mov	word ptr es:[Int21Vector],bx
                mov	word ptr es:[Int21Vector+2],ax
                mov	es,word ptr DisplaySegment

                assume	es:ActiveTextBuffer
                mov	dx,word ptr DisplayModeControlPort
                mov	al,1h
                out	dx,al
                call	CompleteDisplayInitialization
                test	byte ptr ds:[46h],40h
                je	RestoreBios2

; Preserve low memory across the separately resident PC-NET service
; call.

                push	ds
                mov	cx,100h
                xor	ax,ax
                mov	ds,ax

                assume	ds:InterruptVectorTable
                mov	di,ax
                mov	ax,1f00h
                mov	es,ax

                assume	es:nothing
                mov	si,1000h
                push	si
                push	di
                push	es
                push	ds
                push	cx
                cld
                RepneMovsw
                call	PcNetDriverEntry
                cli
                pop	cx
                pop	es
                pop	ds

                assume	ds:nothing, es:InterruptVectorTable
                pop	si
                pop	di
                cld
                RepneMovsw
                pop	ds
RestoreBios2:

                assume	ds:OptionRomData, es:nothing

; Recover the caller's stack and enter the downloaded continuation.

                mov	ss,word ptr CallerStackSegment

                assume	ss:nothing
                mov	sp,word ptr CallerStackPointer
                jmp	dword ptr TransportContinuation
RestoreBiosAndTransferControl   endp

; Program PIT channels 0 and 2 for the next execution stage.

InitializePitChannels           proc	near
                mov	al,30h
                out	PIT_CONTROL_PORT,al
                mov	al,36h
                out	PIT_COUNTER0_PORT,al
                mov	al,74h
                out	PIT_COUNTER0_PORT,al
                mov	al,0b6h
                out	PIT_CONTROL_PORT,al
                mov	al,0h
                out	PIT_COUNTER2_PORT,al
                mov	al,7h
                out	PIT_COUNTER2_PORT,al
                ret
InitializePitChannels           endp

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

WriteFunctionKeyMenu            proc	near

; Save the loading display before presenting the downloaded captions.

                cli
                mov	ax,0a00h
                mov	bx,word ptr DisplaySegment
                call	CopyTextScreen
                mov	es,word ptr DisplaySegment
                call	ClearScreen
                push	ds
                mov	ax,800h
                mov	ds,ax

                assume	ds:nothing, es:ActiveTextBuffer
                mov	bx,8h
                mov	si,0dch
                mov	di,0cb4h
                mov	ah,byte ptr cs:[FunctionKeyEnableMask]
WriteMenu1:

; Display only entries whose mask intersects the ROM's client mask.

                test	byte ptr [bx+1h],ah
                je	WriteMenu3
                mov	cl,70h
                mov	al,46h
                stosb
                mov	al,cl
                stosb
                mov	al,bl
                or	al,30h
                stosb
                mov	al,cl
                stosb
                mov	al,3ah
                stosb
                mov	al,cl
                stosb
                inc	di
                inc	di
                mov	cx,1eh
WriteMenu2:
                movsb
                inc	di
                loop	WriteMenu2
                sub	si,word ptr 1eh
                sub	di,word ptr 44h
WriteMenu3:
                sub	si,word ptr 1eh
                sub	di,word ptr 140h
                dec	bx
                jne	WriteMenu1
                pop	ds
                push	ds
                pop	es

                assume	ds:OptionRomData, es:OptionRomData
                mov	al,40h
                out	PPI_PORT_B,al
                call	EnableTextDisplay

; Fall through to keyboard polling; its RET returns to ShowAddress.

WriteFunctionKeyMenu            endp

; Poll IRQ1, acknowledge a scan code, and dispatch function keys.

PollKeyboard    proc	near

                assume	ds:OptionRomData
                sti
                nop
                mov	word ptr BootTimeoutTicks,258h
                mov	al,0ah
                out	PIC_COMMAND_PORT,al

; Allow the PIC command-port read selection to settle before reading.

                jmp	PollKey1

PollKey1:
                nop
                nop
                in	al,PIC_COMMAND_PORT
                and	al,2h
                je	PollKeyboard

; Read the scan code and pulse the keyboard acknowledgement latch.

                in	al,KBD_DATA_PORT
                mov	ah,al
                mov	al,0c0h
                out	PPI_PORT_B,al
                jmp	PollKey2

PollKey2:
                mov	al,40h
                out	PPI_PORT_B,al
                mov	al,ah
                and	al,7fh
                sub	al,3bh
                cmp	al,7h
                ja	PollKeyboard
                cli
                mov	bx,800h
                mov	es,bx

                assume	es:nothing
                xor	bx,bx
                mov	bl,al
                mov	bl,byte ptr es:[bx+2h]
                push	ds
                pop	es

                assume	es:OptionRomData
                and	bl,byte ptr cs:[FunctionKeyEnableMask]
                je	PollKeyboard

; Submit the enabled F1-F8 selection and restart the download session.

                mov	byte ptr BootMenuSelection,al
                mov	byte ptr BootRequestWord,2h
                mov	word ptr ReceiveSlotIndex,0h
                mov	byte ptr FunctionKeyMenuRequested,0h

; Restore the saved loading screen from 0a00:0000 to video RAM.
; Reverse the segment arguments used by WriteFunctionKeyMenu.

                mov	dx,word ptr DisplayModeControlPort
                mov	ax,DisplaySegment
                mov	bx,0a00h
                call	CopyTextScreen

                assume	es:ActiveTextBuffer
                mov	byte ptr es:[0h],0h
                push	ds
                pop	es

                assume	es:OptionRomData
                call	EnableTextDisplay
                call	AdvanceTransportSession3
                call	RunTransportStateMachine
                sti
                ret
PollKeyboard    endp

; Copy 80 by 25 text cells from BX:0000 to AX:0000.
; Disable video output during the copy; the caller re-enables it.
; Preserve DS; leave ES selecting the destination segment.

CopyTextScreen  proc	near

                assume	ds:OptionRomData
                push	ds
                mov	dx,word ptr DisplayModeControlPort
                mov	es,ax
                mov	ds,bx

                assume	ds:nothing, es:nothing
                mov	al,1h
                out	dx,al
                mov	cx,0fa0h
                xor	si,si
                mov	di,si
                cld
                RepneMovsb
                pop	ds

                assume	ds:OptionRomData
                ret
CopyTextScreen  endp

TestTiganLan    proc	near
                test	byte ptr cs:[RomConfigurationFlags],4h
                jne	TestTigan2
                mov	dx,TIGAN_LAN_STATUS_PORT
                mov	al,80h
                out	dx,al
                mov	dx,TIGAN_LAN_PROBE_PORT
                jmp	TestTigan1

TestTigan1:
                in	al,dx
                IncCxLong
                IncCxLong
                or	al,al
                je	InitializeTiganLan
TestTigan2:
                ret
TestTiganLan    endp

InitializeTiganLan              proc	near

; Read adapter configuration and initialise its shared-memory window.
; Build 192 linked receive descriptors at a stride of 168 bytes, then
; publish the queue heads and enable the transport interrupt mask.

                mov	ax,ConfiguredNodeAddress
                mov	NodeAddress,ax
                mov	si,FromTiganLan
                call	Display
                cld
                mov	dx,TIGAN_LAN_CONFIGURATION_PORT
                mov	di,67h
                mov	cx,6h
InitTigan1:
                in	al,dx
                stosb
                add	dx,word ptr 400h
                loop	InitTigan1
                mov	dx,TIGAN_LAN_STATUS_PORT
                xor	al,al
                out	dx,al
                mov	word ptr AdapterStatusPort,dx
                mov	ax,0a000h
                mov	es,ax
                mov	ds:[12h],ax
                mov	di,8000h
                mov	cx,8000h
                xor	al,al
                RepneStosb
                mov	word ptr es:[0fffch],0ffech
                mov	word ptr es:[0fff6h],0h
                mov	word ptr es:[0ffeeh],0ff00h
                mov	byte ptr es:[0ffech],1h
                mov	dx,TIGAN_LAN_COMMAND_PORT
                out	dx,al
                xor	cx,cx
InitTigan2:
                cmp	byte ptr es:[0ffech],0h
                je	InitTigan4
                loop	InitTigan2
InitTigan3:
                jmp	near ptr ShowLanBoardFailed

InitTigan4:
                mov	word ptr AdapterDataPort,dx
                mov	ax,es:[0ff00h]
                mov	es:[0ff02h],ax
                out	dx,al
                mov	word ptr es:[0fef2h],0ffffh
                mov	si,6dh
                mov	cx,word ptr [si]
                and	cx,word ptr 0fh
                mov	ax,8002h
                call	SubmitTiganLanCommand
                je	InitTigan3
                mov	si,67h
                mov	cx,6h
                mov	ax,8001h
                call	SubmitTiganLanCommand
                je	InitTigan3
                mov	di,0feeeh
                mov	word ptr es:[0ff04h],di
                xor	ax,ax
                ZeroDisp	26h,89h,45h     ; mov es:[di+0],ax
                mov	word ptr es:[di+2h],8004h
                dec	ax
                mov	word ptr es:[di+4h],ax
                mov	bx,0fee6h
                mov	word ptr es:[di+6h],bx
                mov	cx,6h
                mov	si,61h
                lea	di,[di+8h]
                RepneMovsb
                ZeroDisp	26h,0c7h,47h,8000h,dw ; mov word ptr es:[bx+0],8000h
                mov	word ptr es:[bx+2h],ax
                mov	di,0fe5eh
                mov	word ptr es:[bx+4h],di
                mov	ax,NodeAddress
                ZeroDisp	26h,89h,45h     ; mov es:[di+0],ax
                mov	cx,0c0h
                mov	di,8000h
                mov	ax,0ffffh
InitTigan5:
                mov	bx,di
                add	bx,word ptr 0a8h
                mov	word ptr es:[di+4h],bx
                mov	word ptr es:[di+6h],ax
                lea	si,[bx+16h]
                mov	word ptr es:[di+18h],si
                lea	si,[di+20h]
                mov	word ptr es:[di+1ah],si
                mov	word ptr es:[di+1eh],88h
                mov	di,bx
                loop	InitTigan5
                sub	bx,word ptr 0a8h
                mov	TiganLanRequestQueueHead,bx
                mov	word ptr es:[bx+2h],8000h
                mov	di,8000h
                mov	word ptr es:[bx+4h],di
                add	bx,word ptr 16h
                mov	TiganLanRequestQueueTail,bx
                mov	ax,8016h
                mov	word ptr es:[bx+2h],ax
                or	word ptr es:[bx+8h],word ptr 8000h
                mov	word ptr es:[di+6h],ax
                mov	word ptr es:[0ff06h],di
                mov	byte ptr es:[0ff02h],10h
                out	dx,al
                or	byte ptr TransportIrqMask,4h
                mov	byte ptr ds:[46h],88h
                mov	al,8h
                mov	DataRetryInterval,al
                mov	al,14h
                mov	ControlRetryInterval,al
                mov	al,3h
                mov	AckDelayInterval,al
                mov	ax,TiganLanStep
                mov	TiganLanStepCallback,ax
                mov	ax,TiganLanRestart
                mov	TiganLanRestartCallback,ax
                xor	ax,ax
                ret
InitializeTiganLan              endp

SubmitTiganLanCommand           proc	near
                mov	di,0feeeh
                mov	word ptr es:[0ff04h],di
                ZeroDisp	26h,0c7h,45h,0,dw ; mov word ptr es:[di+0],0
                mov	word ptr es:[di+2h],ax
                lea	di,[di+6h]
                RepneMovsb
                mov	word ptr es:[0ff02h],100h
                out	dx,al
                xor	cx,cx
TiganCommand1:
                test	word ptr es:[0feeeh],8000h
                je	TiganCommand2
                test	word ptr es:[0ff00h],2000h
                jne	TiganCommand4
TiganCommand2:
                loop	TiganCommand1
TiganCommand3:
                ret

TiganCommand4:
                test	word ptr es:[0feeeh],2000h
                je	TiganCommand3
                mov	word ptr es:[0ff02h],2000h
                out	dx,al
                ret
SubmitTiganLanCommand           endp

FromTiganLan:
                Message	32, 12, 07h, 0eh, 'FROM TIGAN LAN'

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

WriteAdapterBytes               proc	near
                cld
Write1:
                and	dl,0feh
Write2:
                in	al,dx
                test	al,40h
                je	Write2
                lodsb
                or	dl,1h
                out	dx,al
                loop	Write1

; Short call/return delay between adapter status and data I/O.

AdapterIoSettleDelay:
                ret
WriteAdapterBytes               endp

ReadAdapterBytes                proc	near
                cld
Read1:
                and	dl,0feh
Read2:
                in	al,dx
                test	al,80h
                je	Read2
                call	AdapterIoSettleDelay
                or	dl,1h
                in	al,dx
                stosb
                loop	Read1
                ret
ReadAdapterBytes                endp

LCFBE:
                mov	cx,bx                   ; cfbe: 8bh, cbh

DrainAdapterBytes               proc	near
Drain1:
                and	dl,0feh
Drain2:
                in	al,dx
                test	al,80h
                je	Drain2
                call	AdapterIoSettleDelay
                or	dl,1h
                in	al,dx
                loop	Drain1
                ret
DrainAdapterBytes               endp

ReadLocalAreaNetworkFrame       proc	near
                push	ds
                pop	es
                mov	dx,word ptr AdapterStatusPort
                mov	di,7dh
                mov	cx,2h
                call	ReadAdapterBytes
                mov	bx,word ptr ds:[7dh]
                xchg	bl,bh
                cmp	bx,word ptr 0bh
                jb	LCFBE
                mov	cx,7h
                call	ReadAdapterBytes
                mov	al,ds:[85h]
                cmp	al,0h
                je	ReadLan3
ReadLan1:
                push	word ptr ds:[16h]
                call	ReadLan2
ReadLan2:
                mov	bp,AbortNetworkOperation
                jmp	bp

ReadLan3:
                mov	di,79h
                mov	cx,4h
                call	ReadAdapterBytes
                mov	bl,byte ptr ds:[79h]
                cmp	bl,5h
                jne	ReadLan4
                mov	byte ptr StartupControlClass,0h
                jmp	ReadLan7

ReadLan4:
                test	byte ptr StartupControlClass,0ffh
                je	ReadLan7
                call	GetLocalAreaPayloadLength
                je	ReadLan6
ReadLan5:
                call	DrainAdapterBytes
ReadLan6:
                mov	si,RunTransportStateMachine
                jmp	si

ReadLan7:
                mov	si,ProcessSessionHeader
                call	si
                je	ReadLan8
                mov	si,ResumeTransportSession
                jmp	si

ReadLan8:
                call	GetLocalAreaPayloadLength
                jne	ReadLan9
                jmp	near ptr ReadLan1

ReadLan9:
                mov	al,ds:[4eh]
                sub	al,byte ptr ds:[7ah]
                jns	ReadLan10
                inc	al
                je	ReadLan11
                call	DrainAdapterBytes
                test	byte ptr ds:[55h],0ffh
                jne	ReadLan6
                inc	byte ptr ds:[55h]
                mov	al,3h
                mov	si,QueueSessionControl
                jmp	si

ReadLan10:
                call	DrainAdapterBytes
                mov	si,RequestSessionAck
                jmp	si

ReadLan11:
                cmp	cx,word ptr 82h
                jbe	ReadLan12
                call	DrainAdapterBytes
                jmp	ReadLan13

ReadLan12:
                mov	si,AcquireReceiveBuffer
                call	si
                je	ReadLan5
                mov	bx,di
                mov	byte ptr es:[bx+2h],cl
                dec	byte ptr es:[bx+2h]
                lea	di,[bx+4h]
                call	ReadAdapterBytes
                mov	cl,byte ptr es:[di-2h]
                mov	byte ptr es:[bx+3h],cl
                cmp	al,byte ptr es:[bx+2h]
                je	ReadLan14
                mov	di,bx
                mov	si,LC72C
                call	si
ReadLan13:
                inc	byte ptr ds:[54h]
                jmp	ReadLan15

ReadLan14:
                dec	byte ptr es:[bx+2h]
                mov	byte ptr ds:[55h],0h
                mov	si,ProcessReceivedBuffer
                call	si
ReadLan15:
                jmp	near ptr ReadLan6
ReadLocalAreaNetworkFrame       endp

; Convert the big-endian frame length and subtract its 11-byte header.
; Return the remaining length in CX, with ZF set when it is zero.

GetLocalAreaPayloadLength       proc	near
                mov	cx,word ptr ds:[7dh]
                xchg	cl,ch
                sub	cx,word ptr 0bh
                or	cx,cx
                ret
GetLocalAreaPayloadLength       endp

; Normalize the local-area adapter status bits for a caller.

ReadLocalAreaNetworkStatus      proc	near
                mov	dx,word ptr AdapterStatusPort
                in	al,dx
                and	al,0c0h
                xor	al,40h
                ret
ReadLocalAreaNetworkStatus      endp

; Installed through LocalAreaNetworkRestart by TestLocalAreaNetwork.
; Write the length/header and optional record, then resume the session.

LocalAreaNetworkRestartHandler  proc	near
                mov	byte ptr ds:[101h],bl
                mov	di,si
                mov	cx,0bh
                mov	bx,cx
                or	si,si
                je	RestartLan1
                mov	bl,byte ptr [si+2h]
                add	bx,cx
                inc	bx
RestartLan1:
                xchg	bl,bh
                mov	word ptr ds:[0f8h],bx
                mov	si,0f8h
                inc	cx
                inc	cx
                call	WriteAdapterBytes
                or	di,di
                je	RestartLan2
                xchg	bh,bl
                lea	si,[di+4h]
                sub	bx,word ptr 0ch
                mov	byte ptr [bx+si],bl
                inc	bx
                mov	cx,bx
                call	WriteAdapterBytes
RestartLan2:
                mov	byte ptr PendingControlClass,0h
                and	dl,0feh
                in	al,dx
                sti
                nop
                nop
                nop
                cli
                jmp	near ptr ReadLan6
LocalAreaNetworkRestartHandler  endp

                pop	word ptr [bx+di]        ; d11f: 8fh, 01h
IbmPcNetRestart:
                jmp	near ptr QueueIbmPcNetOutput ; d121: e9h, 04h, 02h

IbmPcNetStep:
                jmp	near ptr PollIbmPcNetOutput ; d124: e9h, d0h, 01h

ServiceIbmPcNetInterrupt        proc	near
                mov	dx,word ptr AdapterStatusPort
                in	al,dx
                mov	ah,al
                or	al,80h
                jmp	ServicePcNet1

ServicePcNet1:
                out	dx,al
                mov	bx,dx
                add	dl,3h
                jmp	ServicePcNet2

ServicePcNet2:
                in	al,dx
                test	ah,80h
                je	ServicePcNet6
                test	byte ptr TransportState,80h
                je	ServicePcNet3
                and	byte ptr TransportState,7fh
                jmp	near ptr ProgramIbmPcNetAdapter

ServicePcNet3:
                and	al,5dh
                out	dx,al
                and	byte ptr TransportState,0bfh
ServicePcNet4:
                test	byte ptr TransportState,20h
                je	ServicePcNet5
                jmp	near ptr FlushIbmPcNetOutput

ServicePcNet5:
                cmp	byte ptr ds:[56h],0h
                je	ServicePcNet11
                dec	byte ptr ds:[56h]
                mov	bx,200h
                mov	cl,0a1h
                jmp	near ptr SubmitIbmPcNetCommand

ServicePcNet6:
                test	al,40h
                je	ServicePcNet13
                and	al,9fh
                out	dx,al
                jmp	ServicePcNet7

ServicePcNet7:
                mov	dx,bx
                mov	al,ah
                and	al,0f8h
                out	dx,al
                cmp	byte ptr ds:[9bh],44h
                je	ServicePcNet12
                cmp	byte ptr ds:[9bh],42h
                jne	ServicePcNet8
                jmp	near ptr ProcessIbmPcNetReceive

ServicePcNet8:
                les	si,dword ptr ds:[8ah]
                ZeroDisp	26h,80h,7ch,0a1h,db ; cmp byte ptr es:[si+0],0a1h
                jne	ServicePcNet10
                inc	byte ptr ds:[56h]
                test	byte ptr TransportState,4h
                je	ServicePcNet10
                lea	si,[si+0ah]
                mov	di,0e2h
                mov	cx,10h
                cld
ServicePcNet9:
                lods	byte ptr es:[si]
                mov	byte ptr [di],al
                inc	di
                loop	ServicePcNet9
                and	byte ptr TransportState,0fbh
ServicePcNet10:
                test	byte ptr TransportState,40h
                je	ServicePcNet4
ServicePcNet11:
                ret

ServicePcNet12:
                les	si,dword ptr ds:[86h]
                lea	ax,[si+5h]
                mov	ds:[8eh],ax
                mov	word ptr ds:[90h],7h
                mov	word ptr ds:[92h],1f5h
                mov	byte ptr es:[si+2h],0h
                and	byte ptr TransportState,0efh
                jmp	near ptr RunTransportStateMachine

ServicePcNet13:
                mov	dx,word ptr AdapterDataPort
                push	ds
                pop	es

                assume	es:OptionRomData
                cld
                mov	di,9bh
                mov	cx,7h
ServicePcNet14:
                in	al,dx
                stosb
                loop	ServicePcNet14
                mov	ax,ds:[9ch]
                or	ax,word ptr ds:[9eh]
                je	ServicePcNet15
                push	word ptr ds:[16h]
                call	AbortNetworkOperation
ServicePcNet15:
                mov	si,offset PcNetRuntimeBufferDescriptor1
                mov	al,ds:[9bh]
                cmp	al,42h
                je	ServicePcNet17
                cmp	al,43h
                je	ServicePcNet17
                mov	si,offset PcNetRuntimeBufferDescriptor0
                cmp	al,44h
                je	ServicePcNet17
ServicePcNet16:
                ret

                assume	es:nothing
ServicePcNet17:
                mov	ax,ds:[0a0h]
                dec	ax
                mov	byte ptr [si+0ch],al
                mov	byte ptr [si+0eh],ah
                jmp	near ptr ProgramPcNet3
ServiceIbmPcNetInterrupt        endp

ProcessIbmPcNetReceive          proc	near

; Import the frame's session counters, then walk its packed records.
; Accepted records use the common receive buffer and payload handler.

                les	si,dword ptr ds:[8ah]
                mov	bl,byte ptr es:[si+2h]
                cmp	bl,5h
                jne	ReceivePcNet1
                mov	byte ptr StartupControlClass,0h
                or	byte ptr TransportState,4h
ReceivePcNet1:
                cmp	bl,6h
                jne	ReceivePcNet2
                push	word ptr ds:[10h]
                call	AbortNetworkOperation
ReceivePcNet2:
                cmp	byte ptr StartupControlClass,0h
                jne	ServicePcNet16
                mov	al,byte ptr es:[si+3h]
                mov	ds:[7bh],al
                mov	al,byte ptr es:[si+4h]
                mov	ds:[7ch],al
                or	byte ptr TransportState,8h
                call	ProcessPcNetSessionHeader
                jmp	ProcessIbmPcNetRecords
ProcessIbmPcNetReceive          endp

; The extra CALL frame accommodates ProcessSessionHeader's two exits.
; A normal return discards our caller's frame here; a control-class
; unwind discards the inner frame there. Both resume at
; ProcessIbmPcNetRecords.

ProcessPcNetSessionHeader       proc	near
                call	ProcessSessionHeader
                pop	ax
                je	ProcessIbmPcNetRecords
                call	ResumeTransportSession
ProcessPcNetSessionHeader       endp

; Read a batch of packed records following the five-byte frame header.
; Each record holds length, dispatch, sequence, then length bytes.
; A zero length/dispatch word ends the batch and resumes the session.

ProcessIbmPcNetRecords          proc	near
                les	si,dword ptr ds:[8ah]
                lea	si,[si+5h]
                mov	dx,ds
                cld
PcNetRecord1:
                lods	word ptr es:[si]
                or	ax,ax
                je	PcNetRecord2
                mov	cx,ax
                lods	byte ptr es:[si]
                mov	ah,byte ptr ds:[4eh]
                sub	ah,al
                js	PcNetRecord3
                mov	al,1h
                jmp	PcNetRecord4

PcNetRecord2:
                and	byte ptr TransportState,0f7h
                mov	es,dx
                jmp	near ptr RunTransportStateMachine

PcNetRecord3:
                inc	ah
                je	PcNetRecord6
                cmp	byte ptr ds:[55h],0h
                jne	PcNetRecord5
                inc	byte ptr ds:[55h]
                mov	al,3h
PcNetRecord4:
                cmp	al,byte ptr PendingControlClass
                jbe	PcNetRecord5
                mov	PendingControlClass,al
PcNetRecord5:
                xor	ch,ch
                add	si,cx
                jmp	PcNetRecord1

; Preserve the adapter segment while acquiring the destination slot.
; Copy only the payload; the dispatch byte goes in the saved prefix.

PcNetRecord6:
                push	es
                call	AcquireReceiveBuffer
                pop	ax
                je	PcNetRecord2
                mov	bx,di
                mov	byte ptr es:[di+2h],cl
                mov	byte ptr es:[di+3h],ch
                xor	ch,ch
                lea	di,[di+4h]
                mov	ds,ax
                RepneMovsb
                mov	ds,dx
                push	ax
                mov	byte ptr ds:[55h],cl
                cmp	byte ptr PendingControlClass,3h
                jne	PcNetRecord7
                mov	byte ptr PendingControlClass,cl
PcNetRecord7:
                call	ProcessReceivedBuffer
                pop	es
                jmp	PcNetRecord1
ProcessIbmPcNetRecords          endp

; Test adapter and software busy state, then flush a buffered frame
; if the next record will not fit. ZF reports output readiness.

PollIbmPcNetOutput              proc	near
                test	byte ptr TransportState,18h
                jne	PollPcNet2
                mov	dx,word ptr AdapterStatusPort
                in	al,dx
                and	al,8h
                jne	PollPcNet2
                cmp	byte ptr PendingControlClass,al
                jne	PollPcNet1
                mov	si,word ptr ds:[0ah]
                or	si,si
                je	PollPcNet2
                xor	cx,cx
                mov	cl,byte ptr [si+2h]
                cmp	cx,word ptr ds:[92h]
                jbe	PollPcNet1
                call	FlushIbmPcNetOutput
                or	al,1h
PollPcNet1:
                or	al,al
PollPcNet2:
                ret
PollIbmPcNetOutput              endp

QueueIbmPcNetOutput             proc	near

; Append a session record to the adapter output buffer. Flush when
; full or when a control frame requires immediate submission.

                les	di,dword ptr ds:[86h]
                mov	byte ptr PendingControlClass,0h
                or	bl,bl
                je	QueuePcNet1
                mov	byte ptr es:[di+2h],bl
                jmp	FlushIbmPcNetOutput

QueuePcNet1:
                mov	di,word ptr ds:[8eh]
                mov	al,byte ptr [si+3h]
                mov	byte ptr es:[di+2h],al
                xor	cx,cx
                mov	cl,byte ptr [si+2h]
                dec	cx
                mov	bx,cx
                ZeroDisp	26h,88h,4dh     ; mov es:[di+0],cl
                lea	si,[si+4h]
                mov	al,byte ptr [bx+si]
                mov	byte ptr es:[di+1h],al
                lea	di,[di+3h]
                cld
                RepneMovsb
                push	ds
                pop	es
                mov	word ptr ds:[8eh],di
                add	bx,word ptr 3h
                add	word ptr ds:[90h],bx
                sub	word ptr ds:[92h],bx
                js	FlushIbmPcNetOutput
                cmp	word ptr ds:[0ah],word ptr 0h
                je	QueuePcNet2
                jmp	near ptr RunTransportStateMachine

QueuePcNet2:
                and	al,80h
                je	FlushIbmPcNetOutput
                mov	byte ptr DataRetryTicks,0h
QueuePcNet3:
                ret
QueueIbmPcNetOutput             endp

; QueuePcNet3 is the shared RET when submission must wait.
; Otherwise terminate the packed records and fall into command output.

FlushIbmPcNetOutput             proc	near
                or	byte ptr TransportState,30h
                test	byte ptr TransportState,44h
                jne	QueuePcNet3
                and	byte ptr TransportState,0dfh
                les	si,dword ptr ds:[86h]
                mov	di,word ptr ds:[8eh]
                mov	word ptr es:[di],0h
                mov	al,ds:[4eh]
                mov	byte ptr es:[si+3h],al
                mov	al,ds:[4dh]
                mov	byte ptr es:[si+4h],al
                mov	bx,word ptr ds:[90h]
                mov	cl,0a0h
                cmp	byte ptr es:[si+2h],4h
                jne	FlushPcNet1
                mov	cl,0a2h
FlushPcNet1:
                cmp	bx,word ptr 7h
                jbe	SubmitIbmPcNetCommand
                mov	al,DataRetryInterval
                mov	DataRetryTicks,al
FlushIbmPcNetOutput             endp

; Publish length and command, then request adapter service. Submit now
; if ready, or set the deferred-programming flag for the interrupt path.

SubmitIbmPcNetCommand           proc	near
                or	byte ptr TransportState,40h
                mov	word ptr ds:[0e0h],bx
                mov	byte ptr ds:[0d8h],cl
                mov	dx,word ptr AdapterStatusPort
                mov	si,dx
                add	dl,3h
                in	al,dx
                jmp	SubmitPcNet1

SubmitPcNet1:
                or	al,2h
                out	dx,al
                mov	ah,al
                xchg	dx,si
                jmp	SubmitPcNet2

SubmitPcNet2:
                jmp	SubmitPcNet3

SubmitPcNet3:
                push	ds
                pop	es
                in	al,dx
                test	al,80h
                jne	ProgramIbmPcNetAdapter
                mov	al,ah
                or	al,80h
                mov	dx,si
                out	dx,al
                or	byte ptr TransportState,80h
                ret
SubmitIbmPcNetCommand           endp

ProgramIbmPcNetAdapter          proc	near
                mov	dx,word ptr AdapterDataPort
                mov	cx,7h
                mov	si,offset PcNetRuntimeAdapterCommand
                cld
ProgramPcNet1:
                lodsb
                out	dx,al
                loop	ProgramPcNet1
                mov	al,1h
                mov	dx,word ptr AdapterStatusPort
                jmp	ProgramPcNet2

ProgramPcNet2:
                out	dx,al
                mov	si,offset PcNetRuntimeAdapterConfiguration
ProgramPcNet3:
                mov	al,7h
                out	DMA_SINGLE_MASK_PORT,al
                lodsw
                mov	cx,ax
                mov	dx,word ptr AdapterStatusPort
                add	dl,3h
                in	al,dx
                jmp	ProgramPcNet4

ProgramPcNet4:
                and	al,0b6h
                or	al,ch
                out	dx,al
                jmp	ProgramPcNet5

ProgramPcNet5:
                or	al,cl
                out	dx,al
                jmp	ProgramPcNet6

ProgramPcNet6:
                mov	cx,8h
                xor	dh,dh
ProgramPcNet7:
                lodsw
                mov	dl,ah
                out	dx,al
                loop	ProgramPcNet7
                ret
ProgramIbmPcNetAdapter          endp

TiganLanRestart:
                jmp	near ptr StartTiganLanOutput ; d44d: e9h, 5eh, 00h

TiganLanStep:
                jmp	near ptr PollTiganLanOutput ; d450: e9h, 50h, 00h

ServiceTiganLanInterrupt        proc	near
                mov	es,word ptr ds:[12h]
                mov	ax,es:[0ff00h]
                and	ax,word ptr 0f000h
                je	ServiceTigan4
                call	SignalTiganCommand
                test	ax,9000h
                je	ServiceTigan2
                push	word ptr ds:[16h]
                call	ServiceTigan1
ServiceTigan1:
                mov	bp,AbortNetworkOperation
                jmp	bp

ServiceTigan2:
                test	ax,2000h
                je	ServiceTigan3
                and	byte ptr TransportState,7fh
ServiceTigan3:
                test	ax,4000h
                je	ServiceTiganLanInterrupt
                or	byte ptr TransportState,40h
                call	ProcessTiganReceiveQueue
                and	byte ptr TransportState,0bfh
                jmp	ServiceTiganLanInterrupt

ServiceTigan4:
                call	SignalTiganCommand
                test	word ptr es:[0ff00h],0f000h
                jne	ServiceTiganLanInterrupt
                mov	si,RunTransportStateMachine
                jmp	si
ServiceTiganLanInterrupt        endp

; Drain queued input before reporting the transport busy state in ZF.

PollTiganLanOutput              proc	near
                call	DrainTiganPendingFrames
                push	ds
                pop	es
                cmp	byte ptr TransportState,0h
                ret
PollTiganLanOutput              endp

StartTiganLanOutput             proc	near
                xor	cx,cx
                cld
                mov	byte ptr PendingControlClass,cl
                mov	byte ptr ds:[101h],bl
                mov	es,word ptr ds:[12h]
                mov	word ptr es:[0feeeh],cx
                mov	ax,4h
                or	si,si
                je	TiganOut1
                mov	cl,byte ptr [si+2h]
                add	ax,cx
                inc	ax
                lea	si,[si+4h]
                mov	di,0fe64h
                mov	byte ptr es:[di],cl
                inc	di
                RepneMovsb
TiganOut1:
                mov	di,0fe60h
                mov	cl,4h
                mov	si,101h
                RepneMovsb
                add	al,2h
                cmp	al,32h
                jae	TiganOut2
                mov	al,32h
TiganOut2:
                or	ax,word ptr 8000h
                mov	es:[0fee6h],ax
                or	byte ptr TransportState,80h
                mov	ax,100h
                call	SignalTiganCommand
                push	ds
                pop	es
TiganOut3:
                ret
StartTiganLanOutput             endp

; TiganOut3 is the shared RET when no completed descriptor is present.

ProcessTiganReceiveQueue        proc	near

; Consume completed receive descriptors and return reusable buffers
; to the adapter queue after processing their session records.

                call	DrainTiganPendingFrames
TiganQueue1:
                mov	di,TiganLanRequestQueueHead
                mov	bx,word ptr es:[di+4h]
                ZeroDisp	26h,8bh,47h     ; mov ax,es:[bx+0]
                test	ax,8000h
                je	TiganOut3
                mov	si,0ffffh
                xchg	word ptr es:[bx+6h],si
                ZeroDisp	26h,0c7h,47h,0,dw ; mov word ptr es:[bx+0],0
                or	word ptr es:[bx+2h],word ptr 8000h
                mov	TiganLanRequestQueueHead,bx
                and	word ptr es:[di+2h],word ptr 7fffh
                test	ax,2000h
                je	TiganQueue2
                push	si
                call	ProcessTiganReceivedFrame
                pop	si
                mov	es,word ptr ds:[12h]
                cmp	si,word ptr ds:[16h]
                je	TiganQueue1
TiganQueue2:
                cmp	si,word ptr 0ffffh
                je	TiganQueue1
                call	RecycleTiganReceiveBuffer
                jmp	TiganQueue1
ProcessTiganReceiveQueue        endp

; Mark the returned buffer as the new queue tail, link the old tail
; to it, then clear the old tail's end marker.

RecycleTiganReceiveBuffer       proc	near
                or	word ptr es:[si+8h],word ptr 8000h
                mov	bx,si
                xchg	TiganLanRequestQueueTail,si
                mov	word ptr es:[si+2h],bx
                and	word ptr es:[si+8h],word ptr 7fffh
                ret
RecycleTiganReceiveBuffer       endp

ProcessTiganReceivedFrame       proc	near
                ZeroDisp	26h,0f7h,44h,8000h,dw ; test word ptr es:[si+0],8000h
                jne	ReceiveTigan1
                push	word ptr ds:[16h]
                call	ServiceTigan1
ReceiveTigan1:
                mov	bl,byte ptr es:[si+0ch]
                cmp	bl,5h
                jne	ReceiveTigan2
                mov	byte ptr StartupControlClass,0h
ReceiveTigan2:
                cmp	bl,6h
                jne	ReceiveTigan3
                push	word ptr ds:[10h]
                call	ServiceTigan1
ReceiveTigan3:
                cmp	byte ptr StartupControlClass,0h
                je	ReceiveTigan5
ReceiveTigan4:
                ret

ReceiveTigan5:
                mov	al,byte ptr es:[si+0eh]
                mov	ds:[7bh],al
                mov	al,byte ptr es:[si+0fh]
                mov	ds:[7ch],al
                mov	di,ProcessSessionHeader
                call	di
                je	ReceiveTigan6
                mov	di,ResumeTransportSession
                jmp	di

ReceiveTigan6:
                mov	al,ds:[4eh]
                sub	al,byte ptr es:[si+0dh]
                jns	ReceiveTigan7
                inc	al
                je	ReceiveTigan9
                cmp	byte ptr ds:[55h],0h
                jne	ReceiveTigan4
                inc	byte ptr ds:[55h]
                mov	al,3h
                jmp	ReceiveTigan8

ReceiveTigan7:
                mov	al,1h
ReceiveTigan8:
                mov	di,QueueSessionControl
                jmp	di

ReceiveTigan9:
                inc	byte ptr ds:[4eh]
                mov	ds:[55h],al
                cmp	byte ptr DelayedAckTicks,al
                jne	ReceiveTigan10
                mov	al,AckDelayInterval
                mov	DelayedAckTicks,al
ReceiveTigan10:
                cmp	word ptr ds:[14h],word ptr 0h
                jne	QueueTiganPendingFrame
                mov	di,AcquireReceiveBuffer
                call	di
                je	QueueTiganPendingFrame
ProcessTiganReceivedFrame       endp

CopyTiganReceivedPayload        proc	near

; Copy the record body out of adapter RAM and separate its dispatch
; byte. Tail-enter the common handler after its counter increment.

                mov	bx,di
                mov	dx,ds
                lea	si,[si+10h]
                mov	ds,word ptr ds:[12h]
                cld
                lodsb
                dec	al
                mov	byte ptr es:[di+2h],al
                xor	cx,cx
                mov	cl,al
                lea	di,[di+4h]
                RepneMovsb
                lodsb
                mov	byte ptr es:[bx+3h],al
                mov	ds,dx
                mov	di,ProcessReceive1
                jmp	di
CopyTiganReceivedPayload        endp

QueueTiganPendingFrame          proc	near
                mov	es,word ptr ds:[12h]
                mov	word ptr es:[si+2h],0h
                mov	di,word ptr ds:[16h]
                or	di,di
                jne	QueueTigan1
                mov	word ptr ds:[14h],si
                jmp	QueueTigan2

QueueTigan1:
                mov	word ptr es:[di+2h],si
QueueTigan2:
                mov	word ptr ds:[16h],si
QueueTigan3:
                mov	byte ptr DelayedAckTicks,1h
                mov	es,word ptr ds:[12h]
QueueTigan4:
                ret
QueueTiganPendingFrame          endp

DrainTiganPendingFrames         proc	near
                mov	si,word ptr ds:[14h]
                or	si,si
                je	QueueTigan4
                mov	di,AcquireReceiveBuffer
                call	di
                je	QueueTigan3
                push	si
                call	CopyTiganReceivedPayload
                pop	si
                mov	es,word ptr ds:[12h]
                mov	ax,word ptr es:[si+2h]
                mov	ds:[14h],ax
                or	ax,ax
                jne	DrainTigan1
                mov	ds:[16h],ax
DrainTigan1:
                call	RecycleTiganReceiveBuffer
                jmp	DrainTiganPendingFrames
DrainTiganPendingFrames         endp

; Wait for the adapter command mailbox to empty, publish AX, then
; notify the controller through its command I/O port.

SignalTiganCommand              proc	near
SignalTigan1:
                cmp	word ptr es:[0ff02h],word ptr 0h
                jne	SignalTigan1
                mov	es:[0ff02h],ax
                mov	dx,word ptr AdapterDataPort
                out	dx,al
                ret
SignalTiganCommand              endp

; OptionRomPcNetRuntimeTemplate.inc

; PC-NET static data; relocation begins at its d690h tail.

PcNetDriverData:
                db	3ch, 02h, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 09h, 06h, 09h, 06h, 09h, 06h, 09h, 06h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 09h, 06h, 09h, 06h, 09h, 06h, 09h, 06h, 09h, 06h, 0ffh, 0ffh, 00h
                db	00h, 00h, 00h, 00h, 00h, 58h, 02h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0fh, 01h, 00h, 00h, 00h, 00h, 00h
                db	00h, 0ah, 0ffh, 00h, 00h, 0ffh, 00h, 00h, 00h, 00h, 00h, 00h, 0ffh, 00h, 00h, 00h
                db	04h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, 30h, 30h, 58h, 47h, 4dh, 00h, 00h
                db	00h, 00h, 00h, 00h, 0ch, 08h, 00h, 26h, 00h, 60h, 00h, 0f2h, 02h, 04h, 40h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 07h, 00h, 0f5h, 01h, 01h, 00h, 00h, 00h, 00h
                db	1ah, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 21h, 08h, 0ffh, 0ch, 4bh, 0bh, 00h
                db	82h, 00h, 06h, 00h, 06h, 19h, 07h, 00h, 07h, 03h, 0ah, 61h, 08h, 0ffh, 0ch, 4bh
                db	0bh, 00h, 82h, 00h, 06h, 00h, 06h, 00h, 07h, 00h, 07h, 03h, 0ah, 61h, 00h, 0ffh
                db	0ch, 47h, 0bh, 00h, 82h, 00h, 06h, 00h, 06h, 00h, 07h, 00h, 07h, 03h, 0ah, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 0feh, 0ffh, 00h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	01h, 80h, 00h, 00h, 00h, 00h

Crc16Table:
                dw	0000h, 0c0c1h, 0c181h, 0140h, 0c301h, 03c0h, 0280h, 0c241h
                dw	0c601h, 06c0h, 0780h, 0c741h, 0500h, 0c5c1h, 0c481h, 0440h
                dw	0cc01h, 0cc0h, 0d80h, 0cd41h, 0f00h, 0cfc1h, 0ce81h, 0e40h
                dw	0a00h, 0cac1h, 0cb81h, 0b40h, 0c901h, 09c0h, 0880h, 0c841h
                dw	0d801h, 18c0h, 1980h, 0d941h, 1b00h, 0dbc1h, 0da81h, 1a40h
                dw	1e00h, 0dec1h, 0df81h, 1f40h, 0dd01h, 1dc0h, 1c80h, 0dc41h
                dw	1400h, 0d4c1h, 0d581h, 1540h, 0d701h, 17c0h, 1680h, 0d641h
                dw	0d201h, 12c0h, 1380h, 0d341h, 1100h, 0d1c1h, 0d081h, 1040h
                dw	0f001h, 30c0h, 3180h, 0f141h, 3300h, 0f3c1h, 0f281h, 3240h
                dw	3600h, 0f6c1h, 0f781h, 3740h, 0f501h, 35c0h, 3480h, 0f441h
                dw	3c00h, 0fcc1h, 0fd81h, 3d40h, 0ff01h, 3fc0h, 3e80h, 0fe41h
                dw	0fa01h, 3ac0h, 3b80h, 0fb41h, 3900h, 0f9c1h, 0f881h, 3840h
                dw	2800h, 0e8c1h, 0e981h, 2940h, 0eb01h, 2bc0h, 2a80h, 0ea41h
                dw	0ee01h, 2ec0h, 2f80h, 0ef41h, 2d00h, 0edc1h, 0ec81h, 2c40h
                dw	0e401h, 24c0h, 2580h, 0e541h, 2700h, 0e7c1h, 0e681h, 2640h
                dw	2200h, 0e2c1h, 0e381h, 2340h, 0e101h, 21c0h, 2080h, 0e041h
                dw	0a001h, 60c0h, 6180h, 0a141h, 6300h, 0a3c1h, 0a281h, 6240h
                dw	6600h, 0a6c1h, 0a781h, 6740h, 0a501h, 65c0h, 6480h, 0a441h
                dw	6c00h, 0acc1h, 0ad81h, 6d40h, 0af01h, 6fc0h, 6e80h, 0ae41h
                dw	0aa01h, 6ac0h, 6b80h, 0ab41h, 6900h, 0a9c1h, 0a881h, 6840h
                dw	7800h, 0b8c1h, 0b981h, 7940h, 0b801h, 7bc0h, 7a80h, 0ba41h
                dw	0be01h, 7ec0h, 7f80h, 0bf41h, 7d00h, 0bdc1h, 0bc81h, 7c40h
                dw	0b401h, 74c0h, 7580h, 0b541h, 7700h, 0b7c1h, 0b681h, 7640h
                dw	7200h, 0b2c1h, 0b381h, 7340h, 0b101h, 71c0h, 7080h, 0b041h
                dw	5000h, 90c1h, 9181h, 5140h, 9301h, 53c0h, 5280h, 9241h
                dw	9601h, 56c0h, 5780h, 9741h, 5500h, 95c1h, 9481h, 5440h
                dw	9c01h, 5cc0h, 5d80h, 9d41h, 5f00h, 9fc1h, 9e81h, 5e40h
                dw	5a00h, 9ac1h, 9b81h, 5b40h, 9901h, 59c0h, 5880h, 9841h
                dw	8801h, 48c0h, 4980h, 8941h, 4b00h, 8bc1h, 8a81h, 4a40h
                dw	4e00h, 8ec1h, 8f81h, 4f40h, 8d01h, 4dc0h, 4c80h, 8c41h
                dw	4400h, 84c1h, 8581h, 4540h, 8701h, 47c0h, 4680h, 8641h
                dw	8201h, 42c0h, 4380h, 8341h, 4100h, 81c1h, 8081h, 4040h

Crc16TableTrailer:
                dw	030fh

UnusedRomSpace:
                db	064fh dup (0ffh)

; Reset entry when this image occupies physical fe000h-fffffh.

RomResetEntry:
                jmp	far ptr MotherboardRomEntry

UnusedRomTail:
                db	000bh dup (0ffh)

OptionRom       ends
                end	OptionRomEntry
