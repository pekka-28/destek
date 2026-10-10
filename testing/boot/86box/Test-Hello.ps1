# Test-Hello.ps1

[CmdletBinding()]
param([switch]$Staged)
$ErrorActionPreference = 'Stop'
$boot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../boot'))
$name = if ($Staged) { 'Staged' } else { 'Hello' }
$video = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "$name.video.bin"))
$screen = -join (0..1999 | ForEach-Object { [char]$video[2 * $_] })
$helloCell = if ($Staged) { 12 * 80 + 33 } else { 0 }
if ($screen.Substring($helloCell, 13) -ne 'Hello, world!') { throw 'MDA Hello differs.' }
for ($index = 0; $index -lt 13; $index++) {
    if ($video[2 * ($helloCell + $index) + 1] -ne 7) { throw 'Hello attribute differs.' }
}
if ($Staged) {
    $image = [IO.File]::ReadAllBytes((Join-Path $boot 'HelloStaged.bin'))
    $intro = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Staged.intro.bin'))
    $bulk = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Staged.bulk.bin'))
    if ([Convert]::ToBase64String($image) -ne [Convert]::ToBase64String([byte[]]($intro + $bulk))) {
        throw 'Staged memory differs from the composed image.'
    }
    if ($screen.Substring(10 * 80 + 31, 12) -ne 'Starting ...') { throw 'Starting message differs.' }
    & "$PSScriptRoot/Test-DownloadedImage.ps1" -Image (Join-Path $boot 'Hello.bin') `
        -Memory (Join-Path $PSScriptRoot 'Staged.bulk.bin')
    if ($image[128] -ne 0xc3) { throw 'Initialise is not the empty RET routine.' }
}
else {
    & "$PSScriptRoot/Test-DownloadedImage.ps1" -Image (Join-Path $boot 'Hello.bin') `
        -Memory (Join-Path $PSScriptRoot 'Hello.loaded.bin')
    if ($screen.Contains('Starting ...')) { throw 'Minimal Hello unexpectedly used staged startup.' }
}
Write-Host "Verified $name image, MDA output, and initialisation."
