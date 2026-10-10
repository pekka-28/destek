# Run Destek in the reference emulator

The reference machine is an IBM PC 5150 with an 8088 at 4.77 MHz, MDA,
512 KiB RAM and COM1. It runs the original Option ROM at physical `c8000h`.
No disk image or DOS installation is required.

Use the locally modified 86Box build below only for the documented Destek
test setup. **It should not be used for other purposes.** The patches change
the PC emulator; the Destek Option ROM is unchanged.

The receive-timing workaround slows the entire receive callback from bit
rate to character rate. It is similar to upstream attempt [3fd3907](https://github.com/86Box/86Box/commit/3fd3907848808e6b2aba35aa5b6c27713e75a0f8),
reverted by [d4623f9](https://github.com/86Box/86Box/commit/d4623f95b66504f7af169c87dc2b6f01206ad9d1) after modem-detection regressions. It can delay
internal processing required by other serial devices and drivers. Our
workaround is not more general and is not intended for an upstream merge.
The build also changes transmit-empty interrupt behavior to allow application
entry.

## Install the build tools

Use Windows PowerShell and a MinGW64 toolchain. The tested installation
uses MSYS2 at `C:/msys64`, GCC 15.2.0, GDB 17.1, CMake and Ninja, with
SDL2, libpng, FreeType, libsndfile, libslirp and libserialport development
packages. The full [tooling list](OptionRomWalkthrough.md#required-support-tooling)
distinguishes these requirements from the much smaller hardware sender setup.

The build script discovers Visual Studio's CMake, then falls back to CMake
on PATH. Pass `-CMake` for another installation and `-Mingw` if the MinGW64
prefix is elsewhere. MASM is needed only if rebuilding the Destek ROM or
sample images; it is not needed to run their supplied binaries.

Git's Windows line-ending conversion is supported when applying the local
emulator patch; the script also recognizes an already patched checkout.

## Build the pinned emulator

From the Destek root, clone 86Box into the ignored source directory and
select the revision supported by the patch:

```powershell
git clone https://github.com/86Box/86Box.git testing/boot/86box/source
git -C testing/boot/86box/source checkout 4fef696a4eead1d55a28d6ac0e5bd2864e5454da
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/86box/Build-Debugger.ps1
```

Skip the clone if that directory already contains the checkout. The script
applies `LocalFixes.patch` and `SerialReceiveTiming.patch` once, enables the GDB stub, disables the dynamic
recompiler, and builds the SDL executable at
`testing/boot/86box/debug-build/src/86Box.exe`. Qt is not required.

For a different tool installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/86box/Build-Debugger.ps1 -Mingw D:/msys64/mingw64 -CMake C:/Tools/CMake/bin/cmake.exe
```

## Supply the machine ROMs

Supply the IBM BIOS, BASIC and MDA font files from the 86Box ROM set or
your own matching collection. They are external runtime inputs and are
not included in the Destek boot package. Keep the following paths under
`testing/boot/86box/runtime/roms`:

```text
machines/ibmpc82/BIOS_5150_27OCT82_1501476_U33.BIN
machines/ibmpc82/ibm-basic-1.10.rom
video/mda/mda.rom
```

Use the supplied `testing/boot/86box/86box.cfg`. It provides 256 KiB of
motherboard RAM plus a 256 KiB ISA expansion, selects MDA, attaches COM1
to the named pipe and maps the project's original 8 KiB Option ROM.
The launcher supplies the ROM search path.

## Run Hello

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/Start-86Box.ps1
```

The launcher starts the sender, the emulator and GDB,
then resumes the machine from reset. Allow time for BIOS POST. The display
should show version 2.20 and `FROM IBM UART`, then clear and display
`Hello, world!`. Close the emulator when finished; this also stops the
host. The default run limit is 180 seconds.

Pass `-Mingw D:/msys64/mingw64` to the launcher if using the alternative
prefix from the build example. Run only one instance at a time: the tools
share pipe names and loopback debugger port 12345.

## Verify the downloaded menu

This automated test rejects disabled F2, selects F3 through the emulator
keyboard, checks all 384 downloaded bytes and verifies the two messages:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/Start-86Box.ps1 -Image boot/HelloStaged.bin -Menu boot/Menu.json -MenuKey 3 -GdbScript testing/boot/86box/Inspect-Menu.gdb
```

For F1, substitute `-Image boot/Hello.bin -MenuKey 1`. With a debugger
script, the launcher closes the test after the assertions finish.
The last debugger output is `testing/boot/86box/debugger.log`;
timestamped captures are retained under `testing/boot/86box/traces`.

## Diagnose a problem

If the executable is missing, finish the build and check the output path.
If startup cannot find the machine or display ROM, check the three paths
above. A missing DLL normally means the launcher is using a different
MinGW64 installation from the build.

If GDB cannot connect, check that no other instance owns port 12345 and
that local security settings permit loopback access. Keep the debugger
bound to loopback. If the sender reports COMPLETE but Hello never appears,
verify that the patched debug build is selected, rather than `-Release`.

The server connects directly to COM1 through the `destek-86box` named pipe.
86Box's corrected receive timer delivers complete characters at the configured
baud rate. There is no separate bridge process. The launcher requests that
the server keep its pipe open after COMPLETE, so the virtual cable stays
attached while the downloaded program runs. Physical serial mode still exits
on COMPLETE. Emulator elapsed time is not a hardware throughput measurement.
