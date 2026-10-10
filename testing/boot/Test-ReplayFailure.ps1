# Test-ReplayFailure.ps1

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../boot/BootstrapReplay.ps1"
function Add-Log { param($Text, $Event) }
function Format-WireHex { param([byte[]]$Bytes) return [BitConverter]::ToString($Bytes) }

$event = [pscustomobject]@{
    Time = [DateTimeOffset]::UtcNow
    Direction = 'Receive'
    Bytes = [byte[]]@(0xaa, 0xf4, 0x00)
}
foreach ($case in @(
    @{ Bytes = [byte[]]@(0xaa, 0xf4, 0x00); Error = $null },
    @{ Bytes = [byte[]]@(0xaa, 0xf5, 0x00); Error = 'record 1, byte 1: expected F4, received F5' },
    @{ Bytes = [byte[]]@(0xaa); Error = 'peer disconnected' }
)) {
    $stream = [IO.MemoryStream]::new($case.Bytes, $false)
    $failure = $null
    try { Invoke-WireReplay -Pipe $stream -Events @($event) }
    catch { $failure = $_.Exception.Message }
    finally { $stream.Dispose() }
    if ($case.Error) {
        if (-not $failure -or $failure -notlike "*$($case.Error)*") {
            throw "Expected fatal replay error '$($case.Error)', got '$failure'."
        }
    }
    elseif ($failure) { throw $failure }
}
Write-Host 'Verified exact replay match, fatal byte mismatch, and fatal truncated response.'
