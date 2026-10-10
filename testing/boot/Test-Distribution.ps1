# Test-Distribution.ps1

$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../boot'))
$testRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$copy = Join-Path $testRoot ('Adrian package ' + [Guid]::NewGuid().ToString('N'))
try {
    Copy-Item -LiteralPath $source -Destination $copy -Recurse
    foreach ($name in 'bochs', 'testing', 'traces', '5150 Option ROM.bin') {
        if (Test-Path -LiteralPath (Join-Path $copy $name)) { throw "Test dependency shipped: $name" }
    }
    $expected = @{}
    foreach ($name in 'Hello.bin', 'HelloStaged.bin') {
        $expected[$name] = (Get-FileHash -LiteralPath (Join-Path $copy $name)).Hash
    }
    & cmd.exe /c "$copy/hello.bat"
    if ($LASTEXITCODE) { throw 'Copied-folder composition failed.' }
    foreach ($name in $expected.Keys) {
        if ((Get-FileHash -LiteralPath (Join-Path $copy $name)).Hash -ne $expected[$name]) {
            throw "Composition changed $name."
        }
    }
    $hello = [IO.File]::ReadAllBytes((Join-Path $copy 'Hello.bin'))
    $staged = [IO.File]::ReadAllBytes((Join-Path $copy 'HelloStaged.bin'))
    if ($hello.Length -ne 128 -or $staged.Length -ne 384 -or
        [BitConverter]::ToString($hello, 0, 5) -ne 'EA-05-00-00-08') {
        throw 'Hello standalone entry is not JMP 0800:0005 in one block.'
    }
    if ([Convert]::ToBase64String($hello) -ne [Convert]::ToBase64String($staged, 256, 128)) {
        throw 'Staged payload differs from the standalone Hello binary.'
    }
    if ($staged[128] -ne 0xc3 -or @($staged[129..255] | Where-Object { $_ -ne 0 }).Count) {
        throw 'Initialisation must be RET followed by unused padding.'
    }
    if (-not [BitConverter]::ToString($staged, 0, 128).Contains('EA-05-00-50-00')) {
        throw 'Startup does not enter the bulk Hello body at 0050:0005.'
    }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$copy/Bootstrap-server.ps1" -ValidateOnly
    if ($LASTEXITCODE) { throw 'Copied sender requires a missing dependency.' }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$copy/Bootstrap-server.ps1" `
        -Menu "$copy/Menu.json" -CompleteSlots -ValidateOnly
    if ($LASTEXITCODE) { throw 'Copied menu requires a missing dependency.' }
    foreach ($file in Get-ChildItem -LiteralPath $copy -Filter *.md) {
        foreach ($match in [regex]::Matches([IO.File]::ReadAllText($file.FullName), '\]\(([^)#]+)(?:#[^)]*)?\)')) {
            $link = $match.Groups[1].Value
            if ($link -match '^(https?:|mailto:|#)') { continue }
            $target = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $link))
            if (-not $target.StartsWith($copy + '\', [StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath $target)) {
                throw "Distribution document requires an external file: $link"
            }
        }
    }
    Write-Host 'Verified copied-folder composition, sender/CRC independence, and self-contained document links.'
}
finally {
    $resolved = [IO.Path]::GetFullPath($copy)
    if ((Split-Path $resolved -Parent) -ne $testRoot -or
        -not ([IO.Path]::GetFileName($resolved)).StartsWith('Adrian package ')) {
        throw 'Refusing unsafe test cleanup.'
    }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
