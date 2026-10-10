# Build-HelloImages.ps1

[CmdletBinding()]
param([string]$Assembler)
$ErrorActionPreference = 'Stop'
$distribution = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../boot'))
$build = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force -Path $build | Out-Null
if (-not $Assembler) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $Assembler = @(& $vswhere -latest -products '*' -find '**/Hostx64/x86/ml.exe')[0]
}
if (-not $Assembler) { throw 'Specify the path to Microsoft ml.exe with -Assembler.' }
foreach ($name in 'Bootstrap', 'Hello') {
    $base = Join-Path $distribution $name
    $objectBase = Join-Path $build $name
    $source = "$base.asm"
    $origin = 0
    $defines = @()
    $size = if ($name -eq 'Bootstrap') { 256 } else { 128 }
    if ($name -eq 'Bootstrap') { $origin = 0x7c00 }
    & $Assembler /nologo /c /omf @defines `
        "/I$distribution" "/Fo$objectBase.obj" "/Fl$objectBase.lst" $source
    if ($LASTEXITCODE) { throw 'MASM assembly failed.' }
    $object = [IO.File]::ReadAllBytes("$objectBase.obj")
    $image = $null
    $segments = 0
    $absoluteSegments = @{}
    $imageSegment = 0
    for ($position = 0; $position -lt $object.Length;) {
        $type = $object[$position]
        $length = [BitConverter]::ToUInt16($object, $position + 1)
        if ($length -lt 1 -or $position + 3 + $length -gt $object.Length) {
            throw 'Invalid OMF record extent.'
        }
        $sum = 0
        for ($index = $position; $index -lt $position + 3 + $length; $index++) {
            $sum += $object[$index]
        }
        if ($sum -band 255) { throw 'Invalid OMF checksum.' }
        $data = $position + 3
        switch ($type) {
            0x98 {
                $segments++
                if ($object[$data] -eq 0) {
                    $absoluteSegments[$segments] = [BitConverter]::ToUInt16($object, $data + 1)
                    if ($object[$data + 3] -ne 0) { throw 'Nonzero absolute segment byte offset.' }
                    break
                }
                if ($imageSegment -ne 0 -or $object[$data] -ne 0x28) {
                    throw 'Expected one byte-aligned, 16-bit public segment.'
                }
                $imageSegment = $segments
                $image = [byte[]]::new([BitConverter]::ToUInt16($object, $data + 1))
            }
            0xa0 {
                if ($null -eq $image -or $object[$data] -ne $imageSegment) { throw 'Unexpected data segment.' }
                $offset = [BitConverter]::ToUInt16($object, $data + 1)
                $lastDataOffset = $offset
                $lastDataLength = $length - 4
                [Array]::Copy($object, $data + 3, $image, $offset, $length - 4)
            }
            0x9c {
                # Resolve local offsets and far pointers to absolute segments.
                for ($fix = $data; $fix -lt $data + $length - 1; $fix += 6) {
                    if ($fix + 6 -gt $data + $length - 1 -or
                        ($object[$fix] -band 0xfc) -notin 0xc4, 0xcc -or
                        $object[$fix + 2] -ne 0x50) {
                        throw 'Unsupported OMF fixup.'
                    }
                    $farPointer = ($object[$fix] -band 0xfc) -eq 0xcc
                    $targetSegment = [int]$object[$fix + 3]
                    if (($farPointer -and -not $absoluteSegments.ContainsKey($targetSegment)) -or
                        (-not $farPointer -and $targetSegment -ne $imageSegment)) {
                        throw 'Fixup target is not a local offset or an absolute far pointer.'
                    }
                    $location = (($object[$fix] -band 3) * 256) + $object[$fix + 1]
                    $width = if ($farPointer) { 4 } else { 2 }
                    if ($location + $width -gt $lastDataLength) { throw 'Fixup outside data record.' }
                    $target = $lastDataOffset + $location
                    $value = [BitConverter]::ToUInt16($image, $target) +
                        [BitConverter]::ToUInt16($object, $fix + 4)
                    [BitConverter]::GetBytes([UInt16]$value).CopyTo($image, $target)
                    if ($farPointer) {
                        [BitConverter]::GetBytes([UInt16]$absoluteSegments[$targetSegment]).CopyTo($image, $target + 2)
                    }
                }
            }
            { $_ -in 0x9d, 0xa1, 0xa2, 0xa3, 0x99 } {
                throw 'Iterated data and 32-bit records are not supported.'
            }
        }
        $position += 3 + $length
    }
    if ($image.Length -ne $origin + $size) { throw "Expected $size bytes at the declared origin." }
    $image = [byte[]]$image[$origin..($origin + $size - 1)]
    [IO.File]::WriteAllBytes("$base.bin", $image)
    Write-Host "$name assembled and fixed at its declared origin: $size bytes."
}
& cmd.exe /c "$distribution/hello.bat"
if ($LASTEXITCODE) { throw 'Binary composition failed.' }
foreach ($staged in 0, 1) {
    $name = if ($staged) { 'HelloStaged' } else { 'Hello' }
    $base = Join-Path $distribution $name
    $image = [IO.File]::ReadAllBytes("$base.bin")
    $done = -1
    for ($index = 0; $index -lt $image.Length - 2; $index++) {
        if ($image[$index] -eq 0xfa -and $image[$index + 1] -eq 0xeb -and $image[$index + 2] -eq 0xfd) {
            if ($done -ge 0) { throw 'Ambiguous Hello completion label.' }
            $done = $index - (256 * $staged)
        }
    }
    if ($done -lt 0) { throw 'Hello completion loop not found.' }
    $helloSegment = if ($staged) { 0x50 } else { 0x800 }
    $helloEntry = 5
    [pscustomobject]@{ _comment = "$name.json"; Name = $name; ImagePath = "../../boot/$name.bin"; Blocks = $image.Length / 128; Entry = 0x7c00; Done = $done; HelloSegment = $helloSegment; HelloEntry = $helloEntry; Staged = [bool]$staged } |
        ConvertTo-Json | Set-Content -LiteralPath "$PSScriptRoot/$name.json" -Encoding ascii
    Write-Host "$name composed: $($image.Length) bytes."
}
