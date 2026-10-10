# Boot-Image.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Send', 'Trace', 'Replay')]
    [string]$Mode,
    [string]$Image,
    [string]$Menu,
    [string]$Trace,
    [string]$Port,
    [switch]$KeepPipeOpen,
    [ValidateSet(1200, 2400, 4800, 9600)]
    [int]$BaudRate = 9600,
    [string]$PipeName = 'destek-bootstrap',
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 180,
    [string]$LogPath,
    [ValidateRange(-1, 248)][int]$PreviousCounterAtRecord = -1
)

$ErrorActionPreference = 'Stop'
if (-not $LogPath) { $LogPath = Join-Path $PSScriptRoot 'bootstrap-wire.log' }
$LogPath = [IO.Path]::GetFullPath($LogPath)
if ($Mode -eq 'Replay') {
    if (-not $Trace -or $Image -or $Menu) { throw 'Replay requires -Trace, without -Image or -Menu.' }
    & "$PSScriptRoot/Bootstrap-server.ps1" -Mode Replay -TracePath $Trace `
        -Port $Port -BaudRate $BaudRate -PipeName $PipeName -LogPath $LogPath `
        -TimeoutSeconds $TimeoutSeconds
    return
}
if ($Menu) {
    if ($Mode -ne 'Send' -or $Trace) { throw 'Menu selection requires Send mode, without -Trace.' }
    & "$PSScriptRoot/Bootstrap-server.ps1" -Mode Slots -Menu $Menu -CompleteSlots `
        -Port $Port -BaudRate $BaudRate -PipeName $PipeName -LogPath $LogPath `
        -TimeoutSeconds $TimeoutSeconds -PreviousCounterAtRecord $PreviousCounterAtRecord -KeepPipeOpen:$KeepPipeOpen
    return
}
if (-not $Image) { throw 'Send and Trace require -Image.' }
$Image = (Resolve-Path -LiteralPath $Image).Path
$length = (Get-Item -LiteralPath $Image).Length
if ($length -lt 128 -or $length -gt 31744 -or $length % 128) {
    throw 'Image must contain 1 through 248 complete 128-byte blocks.'
}
if ($Image -eq $LogPath) { throw 'The log must not overwrite the image.' }
if ($Mode -eq 'Send') {
    if ($Trace) { throw 'Use -LogPath for the trace recorded while sending.' }
    & "$PSScriptRoot/Bootstrap-server.ps1" -Mode Slots -SlotImagePath $Image `
        -CompleteSlots -Port $Port -BaudRate $BaudRate -PipeName $PipeName `
        -LogPath $LogPath -TimeoutSeconds $TimeoutSeconds -PreviousCounterAtRecord $PreviousCounterAtRecord -Menu $Menu -KeepPipeOpen:$KeepPipeOpen
    return
}
if (-not $Trace -or $Port) { throw 'Trace requires -Trace and uses the optional emulator tests.' }
$recorder = Join-Path $PSScriptRoot '../testing/boot/Record-Image.ps1'
if (-not (Test-Path -LiteralPath $recorder)) {
    throw 'Trace generation requires the repository testing/boot tools. Send and Replay work with this folder alone.'
}
& $recorder -Image $Image -Trace $Trace -TimeoutSeconds $TimeoutSeconds
