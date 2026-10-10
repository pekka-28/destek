# Compose-OptionRom.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

function Expand-Source([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($PSScriptRoot + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw "Include outside source directory: $fullPath"
    }
    if (-not $seen.Add($fullPath)) { throw "Repeated or cyclic include: $fullPath" }
    foreach ($line in [IO.File]::ReadAllLines($fullPath)) {
        if ($line -match '^\s*include\s+([^;]+?)\s*(?:;.*)?$') {
            $include = $Matches[1].Trim().Trim('"')
            Expand-Source (Join-Path (Split-Path $fullPath -Parent) $include)
        } else {
            $line
        }
    }
}

$output = Join-Path $root '5150 Option ROM.asm'
$lines = @('; 5150 Option ROM.asm', '',
    '; Self-contained MASM source composed from source/OptionRomLayout.asm.',
    '; Regenerate with source/Compose-OptionRom.ps1.', '') +
    @(Expand-Source (Join-Path $PSScriptRoot 'OptionRomLayout.asm'))
[IO.File]::WriteAllLines($output, $lines, [Text.Encoding]::ASCII)
& (Join-Path $root 'Format-Assembly.ps1') -Path $output
Write-Output "Composed $($seen.Count) source files into $output"
