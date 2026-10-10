<!-- BootMemoryMap.md -->

# Boot memory map

The ROM downloads 128-byte blocks into RAM, then enters the first block
at `0040:7c00`. File order is not physical-address order: the first two
blocks go to physical `08000h`, while the later blocks start at `00500h`.
The host sends the block count and entry offset separately from the image.

# Image layout

*Table Staged image layout* maps the concatenated file to RAM. The sample
uses the same 128-byte Hello.bin as the standalone download. Initialisation
is an empty subroutine; startup's far jump selects the bulk entry.
The first 256 bytes form Bootstrap.bin, assembled from Bootstrap.asm.
An application shorter than 256 bytes can occupy this introductory area
instead of the preamble; pad its file to a 128-byte block boundary.

*Table Staged image layout*

| File offset (hex) | Size (bytes) | Contents | Download address | Physical range (hex) |
| --- | ---: | --- | --- | --- |
| 0000-007f | 128 | Startup and Starting message | 0800:0000 | 08000-0807f |
| 0080-00ff | 128 | Initialise and space for image-specific data | 0800:0080 | 08080-080ff |
| 0100-017f | 128 | Unchanged Hello.bin | 0040:0100 | 00500-0057f |
| 0180 onward | 128 per block | Further bulk blocks | 0040:0180 onward | 00580 onward |

The standalone file contains only Hello.bin. Its five-byte entry jump
normalises CS before the Hello body sets DS equal to CS. Staged startup
enters that same body directly, skipping the standalone jump.
*Table Hello entry addresses* shows why neither package needs to change
the string offset or move any downloaded bytes.

*Table Hello entry addresses*

| Execution stage | CS:IP | Physical address (hex) |
| --- | --- | --- |
| ROM entry into standalone Hello.bin | 0040:7c00 | 08000 |
| Standalone jump to Hello body | 0800:0005 | 08005 |
| ROM entry into staged startup | 0040:7c00 | 08000 |
| Staged entry into Hello body | 0050:0005 | 00505 |

In both Hello executions, the body starts at offset `0005h` and the
string at offset `0021h`. CS selects which downloaded copy is addressed.
The introductory startup uses offsets `7c00h` through `7cffh` relative
to segment `0040h`; the bulk application uses offsets relative to
segment `0050h`. These are address conventions, not separate copies.

# Machine memory

*Table Machine memory map* describes the 512 KiB IBM 5150/MDA validation
configuration. Addresses are physical and ranges include both endpoints.
The option ROM occupies a pseudo adapter-ROM slot at `c8000h`; its 8 KiB
image is unchanged. The original system BIOS occupies `fe000h` through
`fffffh`, including the reset entry at `ffff0h`.

*Table Machine memory map*

| Physical range (hex) | Region | Use during this bootstrap |
| --- | --- | --- |
| 00000-003ff | RAM: interrupt vector table | BIOS vectors, temporary IRQ vectors and the BIOS stack in the upper part |
| 00400-004ff | RAM: BIOS data area | BIOS equipment, serial-port and video state |
| 00500-07fff | RAM: bulk download capacity | Up to 246 bulk blocks before reaching the introduction |
| 08000-080ff | RAM: introduction | Startup and initialisation; standalone Hello uses only the first block |
| 08100-09fff | RAM | Outside the demonstrated image destinations |
| 0a000-0af9f | RAM: saved text screen | CopyTextScreen saves the loading display here during menu selection and restores it afterwards |
| 0afa0-1f9ff | RAM | Outside the demonstrated image destinations |
| 1fa00-1fd0e | RAM: ROM workspace | Transport state, callbacks and copied CRC table |
| 1fd0f-1fdff | RAM | Gap before the ROM stack reservation |
| 1fe00-1feff | RAM: ROM stack | Initial SS:SP is 1fe0:0100; grows downwards |
| 1ff00-7ffff | RAM | Outside the demonstrated image destinations |
| 80000-affff | Unpopulated address space | No RAM or adapter mapped here in this configuration |
| b0000-b0fff | MDA display RAM | 80 by 25 character/attribute pairs plus unused page tail |
| b1000-c7fff | Adapter address space | Not used by the downloaded image |
| c8000-c9fff | Destek option ROM | Original transport and bootstrap code |
| ca000-f5fff | Expansion ROM address space | No additional ROM mapped in this configuration |
| f6000-fdfff | IBM BASIC ROM | Resident BASIC, not part of this download |
| fe000-fffff | IBM BIOS ROM | POST, interrupt services and reset entry |

The serial receiver also saves and restores four bytes immediately before
each selected image block while it handles the record header. For slot
zero, the 16-bit offset wraps to `0800:fffc`, physical `17ffch`. This
temporary header access is separate from the final image layout.

The ROM restores the caller's SS:SP before entering the introduction.
Startup, Initialise and Hello continue using that stack. The sample does
not reserve or install a separate application stack.
In the native test, the restored value is `0030:00f6`, physical `003f6h`.
The stack grows downwards in the upper part of the interrupt-vector area;
it is the stack established by this IBM BIOS, not part of the bulk image.

The 20 KiB marked test occupies `00500h-054ffh` plus the introduction.
The layout limit is 248 total blocks: two introductory blocks and 246
bulk blocks. Slot 248 would overwrite the introduction at `08000h`.
The host enforces this limit; the ROM does not protect the introduction.

The distribution description [1] specifies the initialisation entry and
composition. The protocol [2] specifies the separate control record and
block exchange. Emulator validation [3] describes the machine configuration
and the observations used in this map.

# References

1. [Bootstrap distribution](BootstrapDistribution.md) (image composition
   and entry), Destek ROM analysis, 10 September 2026.
2. [Serial bootstrap protocol](SerialBootstrapProtocol.md) (control records
   and block transfer), Destek ROM analysis, 10 September 2026.
3. [Emulator validation](Validation.md) (86Box configuration and results),
   Destek ROM analysis, 10 September 2026.
