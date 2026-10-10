# Contributing to Destek

Hardware reports, new boot applications and improvements to the ROM
interpretation are welcome. A failed run with enough detail to reproduce
it is also useful.

## Report a hardware run

Start with the 128-byte Hello image and the [serial boot guide](boot/README.md).
The first useful result is a complete download followed by visible application
output. The host's COMPLETE record by itself does not prove that the PC
entered the application.

Include these details in an issue or a report:

- PC model, CPU, BIOS version, installed RAM and display adapter.
- Option ROM checksum and mapping, the adapter or ROM carrier used, and
  any relevant switches or jumpers.
- Target UART, I/O address and IRQ; host serial adapter, cable arrangement
  and baud rate.
- Image name and SHA256, exact sender command, and the host's wire log.
- A photograph of the loading display and final output, or the last
  visible state if the run fails.

After direct Hello succeeds, try the menu: F1 should print Hello; F3 should
print `Starting ...` and then Hello; F2 should leave the menu waiting for
an enabled choice. Record what actually happened for each case. Please
identify any ROM, host or hardware modifications used in the test.

The reference emulator uses 512 KiB of RAM. Analysis places the fixed
workspace below 128 KiB, but a 128 KiB configuration has not been tested.
Reports from smaller machines and different displays would help establish
the actual compatibility range.

## Write a boot application

Begin with [Hello.asm](boot/Hello.asm) for a standalone application or
[Bootstrap.asm](boot/Bootstrap.asm) for startup plus a bulk payload.
Follow the [image contract](boot/BootstrapDistribution.md) and
[memory map](boot/BootMemoryMap.md): file order is not physical RAM order.
The host accepts complete 128-byte blocks, up to 248 in total.

The supplied Initialise subroutine is empty. Replace it with application
initialization as needed; applications with larger stack requirements
should establish their own stack. Include the source, build instructions,
expected output and the machine or emulator used for testing.

## Improve the ROM interpretation

Keep the original binary images unchanged. Edit the maintained fragments
under `source`, compose the consolidated listing, and run the byte comparison:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File source/Compose-OptionRom.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File testing/rom/Build-OptionRom.ps1
```

State whether a finding comes from static bytes, an emulator trace or a
hardware observation. Give the file offset and explain the address mapping
when referring to debugger addresses. Recovered symbols use a different base
from the reference emulator's physical ROM mapping.

The [walkthrough tooling list](docs/OptionRomWalkthrough.md#required-support-tooling)
and [artifact report](ARTIFACTS.md) explain the analysis environment.
The card's Z80 firmware and additional transport implementations are useful
areas for further investigation.

## Check changes

Use the focused checks described in [testing/boot/README.md](testing/boot/README.md)
and [testing/rom/README.md](testing/rom/README.md). Sender or image-layout changes
should pass the copied-package, replay-failure and menu checks.
Changes to executable behavior should also be exercised in the reference
emulator or on the affected hardware.

Keep generated build products, emulator installations and working logs out
of contributions. Include a small, named trace or memory fixture when it
supports a new regression test. Do not include third-party BIOS or font ROMs
in a contribution; identify the required files and their provenance instead.
