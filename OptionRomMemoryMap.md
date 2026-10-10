<!-- OptionRomMemoryMap.md -->

# Option ROM Memory Map

The current build assembles the self-contained `5150 Option ROM.asm` as
one translation unit. `source/OptionRomLayout.asm` orders the fragments
that `source/Compose-OptionRom.ps1` folds into it. No linker ordering is
required. The ranges below describe the earlier module partition.

| ROM range | Module responsibility | First symbol |
| --- | --- | --- |
| `0000h-0048h` | Header and manufacturer string | `OptionRomHeader` |
| `0049h-00e7h` | Entry and startup relocation | `OptionRomEntry` |
| `00e8h-013ah` | Intel 8259A PIC/vector setup | `InstallInterruptVectors` |
| `0951h-0a0ch` | Display setup and text output utilities | `InitializeDisplay` |
| `0b34h-0cfch` | Tigan LAN initialisation and adapter-RAM setup | `InitializeTiganLan` |
| `0cfdh-1fffh` | Remaining transport code, tables, and static data | `PcNetServiceStubTable` |

`source/OptionRomMemoryMap.inc` preserves the absolute base and module offsets. A
separate module uses `RomModuleBegin` with its assigned offset and
`RomModuleEnd` at its end. This is deterministic even if the linker receives
objects in another order, provided no two modules claim overlapping ranges.

The independent-module experiment is retained under `source` but is not
part of the build. Its objects must not be combined with the consolidated
listing because they define the same bytes and symbols.
