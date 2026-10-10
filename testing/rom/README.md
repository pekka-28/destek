# Build and verify the ROM

From the repository root, run source/Compose-OptionRom.ps1 and then
testing/rom/Build-OptionRom.ps1 using PowerShell. Microsoft MASM is required.
The build verifies every one of the 8,192 bytes against the original ROM.
MASM warning A4013 for the absolute segment is expected.

Format-Assembly.ps1 enforces source layout. Test-AssemblyFormatter.ps1 and
../boot/Test-AssemblyLayout.ps1 check the formatting rules. Generated object,
listing and candidate files are local build output.
