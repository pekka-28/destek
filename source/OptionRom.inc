; OptionRom.inc

; Recovered logical segments, constants, and MASM-compatible data
; macros.

                include	Pc5150Hardware.inc

                include	OptionRomAdapterHardware.inc

                include	OptionRomUtilities.inc

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

                include	OptionRomInitialization.inc

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
