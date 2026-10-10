<!-- BootstrapDistribution.md -->

# Bootstrap distribution

The staged image consists of a 256-byte preamble followed by the application,
padded to 128-byte blocks. `Bootstrap.asm` contains the complete preamble:
startup, the dummy Initialise subroutine and space for image-specific data.
The ROM downloads the complete image, then enters startup at `0040:7c00`.
No second network loader is needed.

# Files and composition

*Table Distribution fragments* lists the two inputs to the staged
image. Each source assembles independently. `Hello.asm` is self-contained. Its binary
runs directly as a standalone download and is included unchanged as the
staged bulk image. A five-byte far jump normalises the standalone entry;
staged startup selects the bulk segment and enters the Hello body directly.

*Table Distribution fragments*

| Source | Binary | Size (bytes) | Runtime address |
| --- | --- | ---: | --- |
| [Bootstrap.asm](Bootstrap.asm) | Bootstrap.bin | 256 | 0040:7c00 |
| [Hello.asm](Hello.asm) | Hello.bin | 128 | 0050:0005 |

After assembly, composition uses the Windows command interpreter.
Run [hello.bat](hello.bat), or execute the
command in *Listing Staged image composition* from this directory:

*Listing Staged image composition*

`copy /b Bootstrap.bin+Hello.bin HelloStaged.bin`

The minimal form is Hello.bin itself: one 128-byte block entered directly
at 0040:7c00. No composition or second block
is required.

An application shorter than 256 bytes can replace the preamble entirely.
Pad it to one or two 128-byte blocks and send that file directly. The ROM
places both introductory blocks contiguously in RAM, so a small application
can execute there without a separate startup module. Hello.bin demonstrates
the one-block case. Its entry jump is part of the application itself.

These commands concatenate already padded binary fragments. No linker,
Python, PowerShell, or custom composition tool is needed to distribute
and combine them. A replacement bulk binary must be padded to a multiple
of 128 bytes and assembled for its actual runtime address.

The repository's `testing/boot/Build-HelloImages.ps1` is the development
build, outside this package. It invokes Microsoft
MASM 14.42.34438.0 (`ml.exe /c /omf`) separately for each source,
checks and extracts the single OMF data
segment, resolves local 16-bit offsets and far pointers to absolute
segments, and runs the same CMD composition script. It rejects unsupported
fixups. `Hello.asm` copies CS into DS, so string addressing is simply
`mov si,offset HelloText`. The standalone entry jumps from 0040:7c00 to
0800:0005; staged startup enters the same body at 0050:0005. The string
offset is 0021h in both cases. Segment selection supplies the relocation;
initialisation neither copies nor patches the image.
The extractor omits the bytes below that origin from the distributed file.
The supplied binaries can be used without this build step. The sources
use 16-bit segments and the assembler's default 8086 instruction set.

The [boot memory map](BootMemoryMap.md) relates file offsets to physical
RAM addresses and identifies the ROM, display and working-memory regions.

# Startup contract

Hello uses a NUL-terminated string. Its loop jumps to the character scan
on entry, then prints and scans until it finds NUL. It neither needs a
length counter nor reads another character after the terminator.

Staged startup enters with CS=0040h, IP=7c00h, IF clear, and the stack restored by
the ROM. Startup uses BIOS INT 10h to print `Starting ...` at row 10,
column 31, without clearing cells or changing the video mode. It then positions
the cursor at row 12, column 33 for the payload.

The original ROM clears the screen in its display-completion routine
before entering the downloaded image. Startup writes at the former
loading-message position; it does not cause that clear. Standalone Hello
prints at the cursor left by the ROM, at the top left in the native test.

The status remains visible if the bulk code fails. There is no second
startup banner in either sample. Hello is the application's output,
not another initialisation message. Coordinates are zero based.

Startup near-calls `Initialise` at 7c80h. The supplied routine contains
only `ret`; add application-specific hardware initialisation there.
It must preserve a usable return stack and return normally. Startup then
makes a far jump to `BulkImage` at 0050:0005. The remainder of the second
128-byte block is available for image-specific initialisation and data;
its source marks that location. The image implementor defines any required
processor state. The sample does not impose a register table or new stack.

The standalone Hello uses the ROM-restored stack and carries no register
table. It needs its 0040:7c00 entry, a working stack, and the already
initialised BIOS text display.

`Hello.bin` is a standalone BIOS application, not a boot sector or an option
ROM. It needs no DOS, VGA driver, or sample initialisation routine. Its BIOS
teletype call works with the original IBM monochrome adapter as well as
colour text displays [1]. It prints at the existing cursor using the text
cells' existing attributes. POST must already have established the BIOS
video state and interrupt vector, and the machine must have a usable stack.

The ROM always supplies segment 0040h for its continuation. Hello.bin's
standalone entry jump changes CS to 0800h so the body can use zero-based
offsets. Staged startup skips that jump and supplies CS=0050h instead.
Neither path requires VGA register access or extra video-support code.

# Download and validation

The host's initial application control record contains the number of
128-byte blocks and entry offset 7c00h. It is separate from the image.
The host then sends the binary blocks in file order with dispatch 0Ch,
honouring the client's session state and window requests. The staged
Hello has count 3; the standalone Hello has count 1.

This is not one poll followed by an unprompted image stream. A successful
exchange has one initial announcement/START phase, followed by a control
request and repeated requests for up to eight blocks. The client
acknowledges progress between blocks and can poll again while waiting.
The 162-block marked test required 21 image windows. The ROM repeats the
initial announcement if the session does not establish successfully.

The successful marked trace contains no timeout POLL (f2) frames. Its
normal exchange contains one ANNOUNCE, 22 REQUEST records (one initial
control request and 21 windows), 141 ACK records, and one COMPLETE.
The supplied traces retain both raw bytes and decoded records.

Both forms have been downloaded and executed on the 86Box IBM 5150
configuration with an 8088 and MDA. Debugger assertions verify the entire
image at handoff, the displayed text and arrival at the completion loop.
The minimal image prints at the existing cursor and has no banner; the
staged image also displays `Starting ...`.

[Emulator validation](Validation.md) describes the boot process and local
UART modifications. Emulator support remains under `testing/boot`;
neither distributed image contains emulator-specific hardware code.

# References

1. IBM PC BIOS source listing (PC BIOS), https://github.com/philspil66/IBM-PC-BIOS/blob/main/PCBIOS.ASM,
   IBM, 1981. Transcription of the original listing; VIDEO_IO and WRITE_TTY
   implement the BIOS calls used here.
