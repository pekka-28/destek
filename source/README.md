<!-- README.md -->

# Option ROM source fragments

`OptionRomLayout.asm` orders the definitions and code fragments used to
generate the self-contained `../5150 Option ROM.asm`. Definitions occur
once before the code. Includes do not represent separately linked objects.

After editing fragments, use *Listing Compose and verify* to regenerate
the root listing and verify all 8,192 bytes against the original ROM.

*Listing Compose and verify*

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File source/Compose-OptionRom.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File testing/rom/Build-OptionRom.ps1
```

Run these commands from the repository root. Assembly uses Microsoft MASM
14.42.34438.0. The generated root listing needs none of these include files
to assemble.

