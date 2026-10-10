# Artifact provenance

The historical inputs were supplied from the Internet Archive item
[`destek-isa-network-card`](https://archive.org/download/destek-isa-network-card),
as recorded in [ARTIFACTS.md](ARTIFACTS.md). The Option ROM binary is preserved unchanged. The Z80 card firmware is
identified below for context and remains available from the original archive;
it is not bundled in this Option ROM snapshot.

| Input | Size | SHA256 |
| --- | ---: | --- |
| `5150 Option ROM.bin` | 8,192 bytes | `BB1AD6A65F5911F8EFBEC8FD6CC916495ADC1C024FB036B7AEBE3F0287311666` |
| `Destek MON100.BIN` | 4,096 bytes | `664AC9496BB025EAD9DFE5715A7F7EC53928AC75D737C0BCE01C7D0ED093FB82` |

The Option ROM contains the notice `MAGIX COPR. SABAKI ENTERPRISES, INC. 1985`.
The reconstructed Option ROM assembly, source fragments, symbols and
radare2 overlay describe that historical binary. The original archive also contains the Z80 disassembly. A byte-identical rebuild preserves the original
program; it does not establish ownership or permission to relicense it.

The newly authored PowerShell serial host, example applications, build and
test tooling, and explanatory documentation are provided under the
[MIT License](LICENSE). That grant does not relicense the historical ROMs,
their reconstructed listings, or extracted firmware data such as the
original CRC table.

86Box source, emulator binaries, IBM BIOS/BASIC and MDA font files are
external runtime dependencies. Their upstream notices and terms apply.
Local emulator source and runtime directories are excluded from the project
by `.gitignore`; the setup guide identifies the required revision and files.
The patches under `testing/boot/86box` include context from 86Box source;
the upstream license continues to apply to that third-party material.
