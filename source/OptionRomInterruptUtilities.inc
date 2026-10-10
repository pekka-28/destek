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
