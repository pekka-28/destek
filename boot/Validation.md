<!-- Validation.md -->

# Emulator validation

86Box is the current validation platform. The tests use an IBM PC 5150
with its original BIOS, an 8088 at 4.77 MHz, MDA and a COM1 8250 UART [1].
The original option ROM remains unchanged. Configuration and debugger scripts reside under `testing/boot/86box` [3].

# Boot process

The IBM BIOS runs POST, initialises its display and interrupt services,
and scans the adapter-ROM area. The emulator maps the 8 KiB option ROM at
physical c8000h [2]. Its header passes the BIOS scan and transfers control to
the ROM entry. No floppy boot sector or local disk participates.

The option ROM initialises the display, single Intel 8259A interrupt
controller, timer and selected UART. Its PIC configuration uses vector
base 20h and automatic end-of-interrupt. The UART raises IRQ4; IRQ0 supplies
the timer ticks for protocol timeouts. The host answers the live session
requests and transmits the image in numbered 128-byte blocks.

After the final block, the ROM sends COMPLETE, waits for transmission to
finish, restores BIOS-facing interrupt and display state, restores the
caller's stack and jumps to the downloaded entry. The ROM clears the
screen during this handoff. Bootstrap.bin writes Starting at the former
loading-message position without another clear, calls Initialise and
enters the bulk application. The [image description](BootstrapDistribution.md)
and [memory map](BootMemoryMap.md) specify the layout.

# Compatibility adjustments

The 86Box test build contains three local changes. Its debugger listens only
on loopback. Its UART model sets transmitter-empty status when the shift
register drains without raising another holding-register-empty interrupt.
The uncorrected model raised that extra interrupt, whose ROM handler left
DX at the interrupt-identification port; the ROM's final transmit-status
poll then read the wrong port and stalled.

The receive-timing patch delivers one byte per complete character, using
the configured baud rate and character format. The server connects directly
to 86Box's named pipe. The earlier 20 ms pacing bridge is no longer needed.
The real serial sender uses the physical UART's 8N1 timing.

The receive-timing modification is restricted to the documented Destek setup
and should not be used for other purposes. It resembles upstream attempt
[3fd3907](https://github.com/86Box/86Box/commit/3fd3907848808e6b2aba35aa5b6c27713e75a0f8), reverted by [d4623f9](https://github.com/86Box/86Box/commit/d4623f95b66504f7af169c87dc2b6f01206ad9d1) after modem regressions.
Slowing the shared receive callback can delay internal processing required
by other devices. It is not a general correction or an upstream merge candidate.
No upstream submission or further emulator change is planned for this workaround.

# Verified results

*Table Validation results* separates completed emulator checks from the
remaining hardware test. The preserved traces contain both raw wire bytes
and readable records; their Comment entries identify the image and test.

*Table Validation results*

| Check | Result |
| --- | --- |
| Original ROM entry through IBM POST | Passed without a floppy harness or ROM patch |
| Standalone Hello.bin | All 128 bytes matched; Hello executed on MDA |
| Bootstrap.bin plus Hello.bin | All 384 bytes matched; Starting and Hello displayed |
| Marked large image | All 256 introductory bytes and 20,480 bulk bytes matched |
| Progress indicator | All 163 increments matched; final character code c3h |
| Previous DATA receive sequence | Rejected without an extra application dispatch; corrected frame completed the image |
| Downloaded menu | All 256 bytes and the enabled F1/F3 captions verified on MDA |
| Disabled F2 | Returned to keyboard polling without submitting a selection |
| F1 selection | Selected and executed the byte-verified 128-byte Hello image |
| F3 selection | Selected and executed the byte-verified 384-byte staged image |
| Reassembled ROM equivalence | All 8,192 bytes and SHA256 match the original using MASM 14.42.34438.0 |
| Physical IBM 5150 and serial cable | Not yet tested |

# References

1. [86Box ports](https://86box.readthedocs.io/en/latest/settings/ports.html)
   (serial configuration), 86Box project.
2. [86Box other peripherals](https://86box.readthedocs.io/en/latest/settings/peripherals.html)
   (custom ROM and memory configuration), 86Box project.
3. Reference execution is described in the repository walkthrough and emulator
   setup guide. Historical development captures are not bundled.
