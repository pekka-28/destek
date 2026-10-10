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
