<!-- README.md -->

# Serial boot package

This folder is the standalone serial boot package. It contains the boot images,
assembler fragments, CMD composition, serial sender, replay engine, CRC
table, and protocol documentation. Sending an image requires Windows
PowerShell and a serial port, not an assembler, emulator, or this repository.

# Choose an image

`Hello.bin` is the minimal complete download: one 128-byte block entered
directly at `0040:7c00`. It prints `Hello, world!` at the existing BIOS cursor.
Its entry jump and Hello body fit in that block; it needs no separate
startup or initialisation fragment.

`HelloStaged.bin` demonstrates the larger-image arrangement. It contains
the 256-byte `Bootstrap.bin` preamble followed by the unchanged `Hello.bin`.
Startup prints `Starting ...` at the ROM's loading-message position, calls
the empty `Initialise` routine, and enters the
bulk payload. The [image contract](BootstrapDistribution.md) describes the
layout and how to replace the payload. The [memory map](BootMemoryMap.md)
shows the download areas, segment-relative entries and surrounding ROMs.

Both use BIOS text services, including those available with MDA. No VGA
driver or DOS is required. Both use the stack restored by the option ROM.

# Compose the images

Run `hello.bat` in this folder. It uses only CMD `copy /b` to regenerate the
staged image from the two supplied binaries. `Hello.bin` needs
no composition. `Bootstrap.asm` contains startup and the dummy Initialise
subroutine. An application shorter than 256 bytes can replace the preamble
and run directly in the introductory area, padded to a 128-byte boundary.
The `.asm` files document the binaries; assembly is unnecessary unless changing
their code. No files from the test environment belong in either image.

# Required files

*Table Package files* separates the minimal sending path from optional
composition and replay. Emulator binaries, debugger scripts and build tools
remain under `testing/boot`. The package includes example channel traces.

*Table Package files*

| Use | Files |
| --- | --- |
| Send the minimal image | Hello.bin, Boot-Image.ps1, Bootstrap-server.ps1, RomCrc16.txt |
| Send the staged image | HelloStaged.bin and the same sender files |
| Offer boot choices | Menu.json, its referenced images, and the sender files |
| Compose the staged image | hello.bat, Bootstrap.bin, Hello.bin |
| Change startup or initialisation | Bootstrap.asm |
| Change Hello | Hello.asm |
| Replay a recorded exchange | BootstrapReplay.ps1, the sender files, and the selected trace |
| Understand the package | README.md, BootstrapDistribution.md, BootMemoryMap.md, SerialBootstrapProtocol.md, ChannelTrace.md |

# Send an image

Connect the host serial port to the PC's regular IBM UART with a null-modem
cable. Select the same baud rate at both ends. The host uses 8N1, no hardware
flow control, and asserts DTR and RTS. Run *Listing Send Hello* from this
folder, then start the PC in its IBM UART transport. Replace COM3 with the
host port; supported rates are 1200, 2400, 4800, and 9600 bps.
This path opens a Windows `System.IO.Ports.SerialPort`; it does not use
the emulator named pipe. The host port must provide
RS-232 electrical signalling, not a TTL-level UART connection.

*Listing Send Hello*

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Boot-Image.ps1 -Mode Send -Image .\Hello.bin -Port COM3 -BaudRate 9600
```

Use `HelloStaged.bin` instead for the larger-image example. The sender
handles live requests, counters, and explicit retry requests. It exits on
the client's COMPLETE message and records the exchange in
`bootstrap-wire.log`; `-LogPath` selects another output. Lack of progress
fails after 180 seconds; `-TimeoutSeconds` changes this host-side limit.

The [protocol](SerialBootstrapProtocol.md) defines the exchange. Images must
contain 1 through 248 complete 128-byte blocks. The sender supplies their
count and entry offset `7c00h` in a separate control record. `RomCrc16.txt`
contains the extracted CRC table, including its nonstandard entry. The
sender does not need the original option-ROM image.

# Offer a boot menu

*Listing Serve menu* downloads the menu in Menu.json and waits for the PC's
function-key selection. F1 loads Hello.bin; F3 loads HelloStaged.bin.
F2 and F4-F8 are disabled. The captions themselves are downloaded.

*Listing Serve menu*

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Boot-Image.ps1 -Mode Send -Menu .\Menu.json -Port COM3 -BaudRate 9600 -LogPath .\Menu.trace.log
```

Each Items entry defines Key, Text and Image. Key is 1-8, Text contains at
most 30 printable ASCII characters, and Image is relative to Menu.json.
The server pads captions and constructs the two menu records, then serves
the selected image with live counters. No concatenation of the menu and
application binaries is required. The host progress timeout defaults to
180 seconds and can be changed with TimeoutSeconds.

[MenuF1.trace.log](MenuF1.trace.log) and [MenuF3.trace.log](MenuF3.trace.log)
preserve the validated exchanges. Interactive menu use should use Send;
strict replay also requires the matching key selection and session state.
The [protocol](SerialBootstrapProtocol.md) specifies the menu and request
payloads.

# Replay a capture

*Listing Replay capture* sends recorded wire bytes with recorded timing and
checks every expected response. A mismatch, missing response, disconnect,
or malformed hex record terminates playback. There is no resynchronisation
or fallback to the interpreter. The client must begin in the captured state.

*Listing Replay capture*

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Boot-Image.ps1 -Mode Replay -Trace .\Session.trace.log -Port COM3 -BaudRate 9600
```

The package includes [Hello.trace.log](Hello.trace.log) for Hello.bin and
[HelloStaged.trace.log](HelloStaged.trace.log) for the combined image.
Both contain ANNOUNCE, the numbered download exchange and COMPLETE.
Their decoded image bytes match the supplied binaries.

Supply the selected trace filename to Replay. The
[trace format](ChannelTrace.md) explains the raw and readable records.
Send mode already records a replayable trace. The separate Trace mode is a
historical development facility not included in this publication snapshot.
Use the log recorded by Send mode for new captures.

Both images have passed native 8088/MDA execution tests in a locally
modified 86Box build. [Emulator validation](Validation.md) describes the
boot process, compatibility adjustments and preserved evidence. Physical
5150 and serial-port validation remain to be performed.

# License

The sender, replay tooling, examples and documentation use the [MIT License](LICENSE).
The license identifies the extracted historical CRC table separately.
