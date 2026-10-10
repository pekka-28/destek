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
