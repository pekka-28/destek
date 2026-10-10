# Build-OptionRom.ps1

[CmdletBinding()]
param([string]$Assembler)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
& (Join-Path $root 'Format-Assembly.ps1') -Check
if (-not $Assembler) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $Assembler = @(& $vswhere -latest -products '*' -find '**/Hostx64/x86/ml.exe')[0]
}
Push-Location $root
try {
    & $Assembler /nologo /c /omf "/Fo$PSScriptRoot/OptionRom.obj" `
        "/Fl$PSScriptRoot/OptionRom.lst" '5150 Option ROM.asm'
    if ($LASTEXITCODE) { throw 'MASM assembly failed.' }
}
finally { Pop-Location }
$object = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'OptionRom.obj'))
$segments = [Collections.Generic.List[object]]::new()
$segments.Add($null)
$image = $null
$lastOffset = 0
$lastLength = 0
function Expand-Block([byte[]]$bytes, [ref]$cursor) {
    $repeat = [BitConverter]::ToUInt16($bytes, $cursor.Value)
    $children = [BitConverter]::ToUInt16($bytes, $cursor.Value + 2)
    $cursor.Value += 4
    $unit = [Collections.Generic.List[byte]]::new()
    if ($children) {
        for ($child = 0; $child -lt $children; $child++) {
            $unit.AddRange([byte[]](Expand-Block $bytes $cursor))
        }
    }
    else {
        $size = $bytes[$cursor.Value++]
        for ($index = 0; $index -lt $size; $index++) { $unit.Add($bytes[$cursor.Value++]) }
    }
    $result = [Collections.Generic.List[byte]]::new()
    for ($index = 0; $index -lt $repeat; $index++) { $result.AddRange($unit.ToArray()) }
    return ,$result.ToArray()
}
for ($position = 0; $position -lt $object.Length;) {
    $type = $object[$position]
    $length = [BitConverter]::ToUInt16($object, $position + 1)
    if ($length -lt 1 -or $position + 3 + $length -gt $object.Length) { throw 'Invalid OMF extent.' }
    $sum = 0
    for ($index = $position; $index -lt $position + 3 + $length; $index++) { $sum += $object[$index] }
    if ($sum -band 255) { throw 'Invalid OMF checksum.' }
    $data = [byte[]]$object[($position + 3)..($position + $length + 1)]
    switch ($type) {
        0x98 {
            if ($data[0] -ne 0 -or $data[3] -ne 0) { throw 'Expected paragraph-aligned absolute segment.' }
            $segment = @{ Frame = [BitConverter]::ToUInt16($data, 1); Size = [BitConverter]::ToUInt16($data, 4) }
            $segments.Add($segment)
            if ($segments.Count -eq 2) { $image = [byte[]]::new($segment.Size) }
        }
        { $_ -in 0xa0, 0xa2 } {
            if ($data[0] -ne 1) { throw 'Unexpected emitting segment.' }
            $lastOffset = [BitConverter]::ToUInt16($data, 1)
            if ($type -eq 0xa0) { $content = [byte[]]$data[3..($data.Length - 1)] }
            else {
                $content = [Collections.Generic.List[byte]]::new()
                $cursor = 3
                while ($cursor -lt $data.Length) { $content.AddRange([byte[]](Expand-Block $data ([ref]$cursor))) }
                $content = $content.ToArray()
            }
            $lastLength = $content.Length
            $content.CopyTo($image, $lastOffset)
        }
        0x9c {
            for ($cursor = 0; $cursor -lt $data.Length;) {
                $kind = $data[$cursor] -band 0xfc
                if ($kind -notin 0xc4, 0xcc) { throw 'Unsupported OMF relocation location.' }
                $location = (($data[$cursor] -band 3) * 256) + $data[$cursor + 1]
                $fix = $data[$cursor + 2]
                if ($fix -notin 0x50, 0x54) { throw 'Unsupported OMF relocation frame/target.' }
                $segment = $segments[$data[$cursor + 3]]
                $cursor += 4
                $displacement = 0
                if ($fix -eq 0x50) {
                    $displacement = [BitConverter]::ToUInt16($data, $cursor)
                    $cursor += 2
                }
                $width = if ($kind -eq 0xcc) { 4 } else { 2 }
                if ($location + $width -gt $lastLength) { throw 'Relocation outside data record.' }
                $target = $lastOffset + $location
                $offset = [BitConverter]::ToUInt16($image, $target) + $displacement
                [BitConverter]::GetBytes([UInt16]$offset).CopyTo($image, $target)
                if ($kind -eq 0xcc) { [BitConverter]::GetBytes([UInt16]$segment.Frame).CopyTo($image, $target + 2) }
            }
        }
        { $_ -in 0x99, 0x9d, 0xa1, 0xa3 } { throw '32-bit OMF records are unsupported.' }
    }
    $position += $length + 3
}
$output = Join-Path $PSScriptRoot 'OptionRom.candidate.bin'
[IO.File]::WriteAllBytes($output, $image)
$original = [IO.File]::ReadAllBytes((Join-Path $root '5150 Option ROM.bin'))
$differences = @()
for ($index = 0; $index -lt [Math]::Min($image.Length, $original.Length); $index++) {
    if ($image[$index] -ne $original[$index]) { $differences += ('{0:x4}: original {1:x2}, assembled {2:x2}' -f $index, $original[$index], $image[$index]) }
}
$differences | Select-Object -First 25 | Write-Host
if ($differences.Count -or $image.Length -ne $original.Length) {
    throw "ROM differs: $($image.Length) assembled bytes, $($original.Length) original bytes, $($differences.Count) differing common bytes."
}
Write-Host "Verified all $($image.Length) ROM bytes identical; SHA256 $((Get-FileHash $output).Hash)."
Copy-Item -LiteralPath $output -Destination (Join-Path $PSScriptRoot 'OptionRom.bin')
