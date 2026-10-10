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
