# Bootstrap-server.ps1

[CmdletBinding()]
param(
    [ValidateSet('Handshake', 'Slots', 'Replay')]
    [string]$Mode = 'Slots',

    [string]$PipeName = 'destek-bootstrap',

    [string]$Port,

    [switch]$KeepPipeOpen,

    [ValidateSet(1200, 2400, 4800, 9600)]
    [int]$BaudRate = 9600,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 180,

    [string]$LogPath,

    [string]$TracePath,

    [string]$PayloadFile,

    [string]$SlotImagePath,

    [string]$Menu,

    [switch]$CompleteSlots,

    [ValidateRange(-1, 248)][int]$PreviousCounterAtRecord = -1,

    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($KeepPipeOpen -and $Port) { throw 'KeepPipeOpen applies only to the emulator named pipe.' }

# Match the extracted image, including its nonstandard entry a4h.
$crcWords = ((Get-Content -LiteralPath (Join-Path $PSScriptRoot 'RomCrc16.txt') |
    Where-Object { $_ -notmatch '^\s*#' }) -join ' ').Trim() -split '\s+'
if ($crcWords.Count -ne 256 -or @($crcWords | Where-Object { $_ -notmatch '^[0-9a-fA-F]{4}$' }).Count) {
    throw 'RomCrc16.txt must contain exactly 256 hexadecimal words.'
}
$crcTable = [UInt16[]]@($crcWords | ForEach-Object { [Convert]::ToUInt16($_, 16) })

if (-not $LogPath) {
    $LogPath = Join-Path $PSScriptRoot 'bootstrap-wire.log'
}
$LogPath = [IO.Path]::GetFullPath($LogPath)

function Add-Log {
    param([string]$Text, [string]$Event = 'Status')

    $line = '{0:O}{1}{2,-8}{1}{3}' -f (Get-Date), "`t", $Event, $Text
    $traceWriter.WriteLine($line)
    $traceWriter.Flush()
    [Console]::WriteLine($line)
}

function Get-Crc16 {
    param([byte[]]$Bytes)

    [UInt16]$crc = 0
    foreach ($value in $Bytes) {
        $crc = [UInt16](($crc -shr 8) -bxor $crcTable[($crc -bxor $value) -band 0xff])
    }
    return $crc
}

function Add-QuotedByte {
    param(
        [System.Collections.Generic.List[byte]]$Wire,
        [byte]$Value
    )

    if ($Value -eq 0xAA) {
        $Wire.Add(0xAA)
        $Wire.Add(0xFF)
        return
    }
    $Wire.Add($Value)
}

function New-Frame {
    param(
        [byte]$Class,
        [byte[]]$SessionPayload
    )

    $decoded = New-Object 'System.Collections.Generic.List[byte]'
    $decoded.Add($Class)
    foreach ($value in $SessionPayload) {
        $decoded.Add($value)
    }
    $crc = Get-Crc16 -Bytes $decoded.ToArray()
    $decoded.Add([byte]($crc -band 0xFF))
    $decoded.Add([byte](($crc -shr 8) -band 0xFF))

    $wire = New-Object 'System.Collections.Generic.List[byte]'
    $wire.Add(0xAA)
    $wire.Add($Class)
    for ($index = 0; $index -lt $SessionPayload.Length; $index++) {
        Add-QuotedByte -Wire $wire -Value $SessionPayload[$index]
    }
    Add-QuotedByte -Wire $wire -Value ([byte]($crc -band 0xFF))
    Add-QuotedByte -Wire $wire -Value ([byte](($crc -shr 8) -band 0xFF))
    $wire.Add(0xAA)
    $wire.Add(0xFE)
    return $wire.ToArray()
}

function New-LoadPayload {
    param(
        [byte]$Address,
        [byte]$Local,
        [byte]$Remote,
        [byte[]]$Code
    )

    $payload = New-Object 'System.Collections.Generic.List[byte]'
    $payload.Add($Address)
    $payload.Add($Local)
    $payload.Add($Remote)
    foreach ($value in $Code) {
        $payload.Add($value)
    }
    $payload.Add(0x0D)
    return $payload.ToArray()
}

function New-TransferPayload {
    param(
        [byte]$Address,
        [byte]$Local,
        [byte]$Remote,
        [UInt16]$Control,
        [UInt16]$Offset
    )

    return [byte[]]@(
        $Address,
        $Local,
        $Remote,
        [byte]($Control -band 0xFF),
        [byte](($Control -shr 8) -band 0xFF),
        [byte]($Offset -band 0xFF),
        [byte](($Offset -shr 8) -band 0xFF),
        0x0C
    )
}

function Format-WireHex {
    param([byte[]]$Bytes)

    return (($Bytes | ForEach-Object { $_.ToString('X2') }) -join ' ')
}

function Describe-Frame {
    param($Frame, [switch]$FromClient)
    if (-not $Frame.Valid) { return 'Invalid frame: incomplete or CRC mismatch' }
    $name = switch ($Frame.Class) {
        0xf0 { 'DATA' } 0xf1 { 'ACK' } 0xf2 { 'POLL' }
        0xf3 { 'RETRY' } 0xf4 { 'ANNOUNCE' } 0xf5 { 'START' }
        0xf6 { 'COMPLETE' } default { 'UNKNOWN' }
    }
    $body = $Frame.Session
    if ($FromClient -and $Frame.Class -eq 0xf0 -and $body.Length -eq 8 -and $body[7] -eq 0x0c) {
        $first = [BitConverter]::ToUInt16([byte[]]$body, 3)
        $last = [BitConverter]::ToUInt16([byte[]]$body, 5)
        if ($first -eq 0x8001) {
            return 'REQUEST {0:X2} {1:X2} {2:X2} INITIAL MASK {3:X2} [{4:X4}]' -f `
                $body[0], $body[1], $body[2], ($last-band 255), $Frame.Crc
        }
        if ($first -eq 0x8002) {
            return 'REQUEST {0:X2} {1:X2} {2:X2} SELECT F{3} MASK {4:X2} [{5:X4}]' -f `
                $body[0], $body[1], $body[2], (($last-shr 8)+1), ($last-band 255), $Frame.Crc
        }
        $request = 'SLOTS'
        return 'REQUEST {0:X2} {1:X2} {2:X2} {3} {4:X4}..{5:X4} [{6:X4}]' -f `
            $body[0], $body[1], $body[2], $request, $first, $last, $Frame.Crc
    }
    $description = $name
    if ($body.Length -ge 3) {
        $description += ' {0:X2} {1:X2} {2:X2}' -f $body[0], $body[1], $body[2]
        if ($body.Length -gt 3) {
            $dispatch = $body[$body.Length - 1]
            $command = switch ($dispatch) { 12 { 'TRANSFER' } 13 { 'LOAD' } default { 'unknown' } }
            $description += ' ' + $command
            if ($body.Length -gt 4) {
                $content = [byte[]]$body[3..($body.Length - 2)]
                $printable = -not @($content | Where-Object { $_ -lt 32 -or $_ -gt 126 }).Count
                if ($printable) {
                    $quoted = [Text.Encoding]::ASCII.GetString($content).Replace('\', '\\').Replace('"', '\"')
                    $description += ' "' + $quoted + '"'
                }
                else { $description += ' {' + (Format-WireHex $content) + '}' }
            }
        }
    }
    return $description + (' [{0:X4}]' -f $Frame.Crc)
}

function Write-WireFrame {
    param([byte[]]$Wire)
    Add-Log -Event Send -Text (Format-WireHex $Wire)
    $write = $pipe.BeginWrite($Wire, 0, $Wire.Length, $null, $null)
    if (-not $write.AsyncWaitHandle.WaitOne(10000)) { throw 'Wire write timed out.' }
    $pipe.EndWrite($write)
    $descriptionParser = New-FrameParser
    foreach ($octet in $Wire) {
        $decoded = Add-ReceivedByte $descriptionParser $octet
        if ($null -ne $decoded) { Add-Log -Event Sent -Text (Describe-Frame $decoded) }
    }
}

function New-FrameParser {
    return [pscustomobject]@{
        Active = $false
        Introducer = $false
        Bytes = New-Object 'System.Collections.Generic.List[byte]'
    }
}

function Reset-FrameParser {
    param([psobject]$Parser)

    $Parser.Active = $false
    $Parser.Introducer = $false
    $Parser.Bytes.Clear()
}

function Add-ReceivedByte {
    param(
        [psobject]$Parser,
        [byte]$Value
    )

    if ($Parser.Introducer) {
        $Parser.Introducer = $false
        if ($Value -eq 0xFF -and $Parser.Active) {
            $Parser.Bytes.Add(0xAA)
            return $null
        }
        if ($Value -ge 0xF0 -and $Value -le 0xF6) {
            $Parser.Active = $true
            $Parser.Bytes.Clear()
            $Parser.Bytes.Add($Value)
            return $null
        }
        if ($Value -eq 0xFE -and $Parser.Active) {
            [byte[]]$frame = $Parser.Bytes.ToArray()
            Reset-FrameParser -Parser $Parser
            if ($frame.Length -lt 3 -or (Get-Crc16 -Bytes $frame) -ne 0) {
                return [pscustomobject]@{ Valid = $false; Bytes = $frame }
            }
            [byte[]]$session = @()
            if ($frame.Length -gt 3) { $session = $frame[1..($frame.Length - 3)] }
            return [pscustomobject]@{
                Valid = $true
                Class = $frame[0]
                Session = $session
                Crc = [UInt16]([int]$frame[$frame.Length - 2] -bor ([int]$frame[$frame.Length - 1] -shl 8))
                Bytes = $frame
            }
        }
        if ($Value -lt 0xf0 -and $Parser.Active) {
            # The ROM omits ff quoting when the following byte is below f0.
            $Parser.Bytes.Add(0xaa)
        }
        else {
            Reset-FrameParser -Parser $Parser
            return $null
        }
    }

    if ($Value -eq 0xAA) {
        $Parser.Introducer = $true
    }
    elseif ($Parser.Active) {
        $Parser.Bytes.Add($Value)
    }
    return $null
}

if ($Mode -eq 'Replay') {
    . (Join-Path $PSScriptRoot 'BootstrapReplay.ps1')
    if (-not $TracePath) { throw 'Replay mode requires -TracePath.' }
    $replayEvents = @(Read-WireTrace -Path $TracePath)
    if ([IO.Path]::GetFullPath($TracePath) -eq [IO.Path]::GetFullPath($LogPath)) {
        throw 'Replay input and output logs must be different files.'
    }
}
$testPayloads = @([byte[]]@(0x90))
if ($SlotImagePath) {
    if ($PayloadFile) { throw 'Choose either SlotImagePath or PayloadFile.' }
    $image = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $SlotImagePath))
    if ($image.Length -lt 128 -or $image.Length % 128 -ne 0 -or $image.Length -gt 31744) {
        throw 'Slot image must contain 1 through 248 complete 128-byte blocks.'
    }
    $testPayloads = [Collections.Generic.List[byte[]]]::new()
    for ($offset = 0; $offset -lt $image.Length; $offset += 128) {
        $testPayloads.Add([byte[]]$image[$offset..($offset + 127)])
    }
}
if ($PayloadFile) {
    $texts = ConvertFrom-Json -InputObject (Get-Content -Raw -LiteralPath $PayloadFile)
    if ($texts.Count -eq 0) { throw 'Payload file must contain a nonempty JSON string array.' }
    $testPayloads = [Collections.Generic.List[byte[]]]::new()
    foreach ($text in $texts) {
        if ($text -isnot [string] -or $text.Length -gt 128 -or $text -match '[^\x00-\x7f]') {
            throw 'Each test payload must be an ASCII string of at most 128 bytes.'
        }
        $testPayloads.Add([Text.Encoding]::ASCII.GetBytes($text))
    }
}

if ($PreviousCounterAtRecord -ge 0 -and
    ($Mode -ne 'Slots' -or $PreviousCounterAtRecord -gt $testPayloads.Count)) {
    throw 'PreviousCounterAtRecord must select an existing record in Slots mode.'
}

$menuEntries = @{}
$menuBytes = New-Object byte[] 256
if ($Menu) {
    if ($Mode -ne 'Slots' -or -not $CompleteSlots -or $PreviousCounterAtRecord -ge 0) {
        throw 'Menu requires completed Slots transfers without sequence fault injection.'
    }
    $menuPath = (Resolve-Path -LiteralPath $Menu).Path
    $menuConfiguration = Get-Content -Raw -LiteralPath $menuPath | ConvertFrom-Json
    foreach ($entry in $menuConfiguration.Items) {
        $key = [int]$entry.Key
        if ($key -lt 1 -or $key -gt 8 -or $menuEntries.ContainsKey($key) -or
            $entry.Text.Length -gt 30 -or $entry.Text -match '[^\x20-\x7e]') {
            throw 'Menu entries require unique keys 1-8 and at most 30 printable ASCII characters.'
        }
        $path = [IO.Path]::GetFullPath((Join-Path (Split-Path $menuPath) $entry.Image))
        $data = [IO.File]::ReadAllBytes($path)
        if ($data.Length -lt 128 -or $data.Length -gt 31744 -or $data.Length % 128) {
            throw "Invalid menu image: $path"
        }
        $menuEntries[$key] = @{ Text=$entry.Text; Path=$path; Bytes=$data }
        $menuBytes[1+$key] = 1
        [Text.Encoding]::ASCII.GetBytes($entry.Text.PadRight(30)).CopyTo($menuBytes,10+30*($key-1))
    }
    if (-not $menuEntries.Count) { throw 'The menu must enable at least one key.' }
}

if ($ValidateOnly) {
    $candidate = New-Frame -Class 0xF5 -SessionPayload ([byte[]]@(0x00, 0xFF, 0x00))
    $actual = Format-WireHex -Bytes $candidate
    $expected = 'aa f5 00 ff 00 72 3c aa fe'
    if ($actual -ne $expected) {
        throw "Frame encoder mismatch: $actual"
    }
    Write-Host "Frame encoder verified: $actual"
    $parser = New-FrameParser
    $parsed = $null
    foreach ($octet in (New-Frame -Class 0xf4 -SessionPayload ([byte[]]@(0, 0xff, 0x0a)))) {
        $result = Add-ReceivedByte -Parser $parser -Value $octet
        if ($null -ne $result) { $parsed = $result }
    }
    if ($null -eq $parsed -or -not $parsed.Valid -or $parsed.Crc -ne 0xc7f3 -or
        (Format-WireHex -Bytes $parsed.Session) -ne '00 ff 0a') {
        throw 'Captured-frame parser validation failed.'
    }
    Write-Host 'Captured initial frame parser verified, including CRC c7f3.'
    if ((Get-Crc16 -Bytes ([byte[]]@(0xa4))) -ne 0xb801 -or
        (Get-Crc16 -Bytes ([byte[]]@(0xa4, 0x01, 0xb8))) -ne 0) {
        throw 'ROM-specific CRC table regression.'
    }
    $parser = New-FrameParser
    $parsed = $null
    foreach ($octet in [byte[]]@(0xaa,0xf1,0x14,0x9f,0xaa,0x9b,0x77,0xaa,0xfe)) {
        $result = Add-ReceivedByte $parser $octet
        if ($null -ne $result) { $parsed = $result }
    }
    if ($null -eq $parsed -or -not $parsed.Valid -or
        (Format-WireHex $parsed.Session) -ne '14 9F AA') {
        throw 'ROM look-ahead quoting regression.'
    }
    Write-Host 'Verified nonstandard CRC entry a4 and unquoted aa before a byte below f0.'
    return
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
$traceWriter = [IO.StreamWriter]::new($LogPath, $false, [Text.Encoding]::ASCII)

$serial = $null
$pipe = $null
if (-not $Port) {
$pipe = [System.IO.Pipes.NamedPipeServerStream]::new(
    $PipeName,
    [System.IO.Pipes.PipeDirection]::InOut,
    1,
    [System.IO.Pipes.PipeTransmissionMode]::Byte,
    [System.IO.Pipes.PipeOptions]::Asynchronous,
    65536,
    65536
)
}

try {
    Add-Log -Event Comment -Text ([IO.Path]::GetFileName($LogPath))
    Add-Log -Event Comment -Text "Server mode $Mode; wire directions are relative to the host."
    Add-Log -Event Comment -Text 'CRC uses the extracted ROM table (entry a4=b801); decoder accepts conditional aa quoting.'
    if ($SlotImagePath) {
        Add-Log -Event Comment -Text "Image $SlotImagePath; $($testPayloads.Count) blocks of 128 bytes; completion requested: $CompleteSlots."
    }
    elseif ($PayloadFile) {
        Add-Log -Event Comment -Text "Text fixture $PayloadFile; $($testPayloads.Count) records."
    }
    if ($Port) {
        $serial = [IO.Ports.SerialPort]::new($Port, $BaudRate, [IO.Ports.Parity]::None, 8, [IO.Ports.StopBits]::One)
        $serial.Handshake = [IO.Ports.Handshake]::None
        $serial.DtrEnable = $true
        $serial.RtsEnable = $true
        $serial.Open()
        $pipe = $serial.BaseStream
        Add-Log "Serial port $Port opened at $BaudRate bps, 8N1; DTR and RTS asserted."
    }
    else {
        Add-Log "Waiting for emulator named-pipe client '$PipeName'."
        $connection = $pipe.BeginWaitForConnection($null, $null)
        if (-not $connection.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000)) { throw 'Client connection timed out.' }
        $pipe.EndWaitForConnection($connection)
    }
    Add-Log 'Client connected.'
    if ($Mode -eq 'Replay') {
        Invoke-WireReplay -Pipe $pipe -Events $replayEvents
        return
    }

    $sent = $false
    $recordNumber = 0
    $initialFrame = $null
    $lastSlotFrame = $null
    $stalePending = $false
    $staleInjected = $false
    $menuPhase = 0
    $sequenceBase = 0
    if ($Menu) {
        Add-Log -Event Comment -Text "Downloaded menu $menuPath; two 128-byte records; enabled keys: $((@($menuEntries.Keys | Sort-Object) | ForEach-Object { 'F'+$_ }) -join ', ')."
    }
    $parser = New-FrameParser
    $buffer = New-Object byte[] 256
    $read = $pipe.BeginRead($buffer, 0, $buffer.Length, $null, $null)

    $activity = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        if ($activity.Elapsed.TotalSeconds -gt $TimeoutSeconds) { throw 'Protocol progress timed out.' }
        if ($read.AsyncWaitHandle.WaitOne(100)) {
            $count = $pipe.EndRead($read)
            if ($count -eq 0) {
                if ($Mode -eq 'Slots' -and $CompleteSlots) {
                    throw 'Peer disconnected before acknowledging image completion.'
                }
                Add-Log -Event Status -Text 'Peer disconnected.'
                break
            }
            [byte[]]$receivedChunk = $buffer[0..($count - 1)]
            # Keep a read pending while replies are written: the emulator
            # may produce output concurrently with receiving the next frame.
            $read = $pipe.BeginRead($buffer, 0, $buffer.Length, $null, $null)
            Add-Log -Event Receive -Text (Format-WireHex -Bytes $receivedChunk)
            :ReceivedOctets foreach ($value in $receivedChunk) {
                $receivedFrame = Add-ReceivedByte -Parser $parser -Value $value
                if ($null -eq $receivedFrame) {
                    continue
                }
                if (-not $receivedFrame.Valid) {
                    Add-Log -Event Received -Text (Describe-Frame $receivedFrame)
                    continue
                }
                Add-Log -Event Received -Text (Describe-Frame $receivedFrame -FromClient)
                if ($stalePending -and $receivedFrame.Session.Length -ge 3) {
                    if ($receivedFrame.Session[1] -ne (($recordNumber - 1) -band 255)) {
                        throw 'Client advanced its receive counter after the stale record.'
                    }
                    Add-Log -Event Comment -Text "Stale sequence rejected: client still acknowledges $($recordNumber - 1); sending correct record $recordNumber."
                    Write-WireFrame $lastSlotFrame
                    $stalePending = $false
                    $recordNumber++
                    $sent = $recordNumber -gt $testPayloads.Count
                    $activity.Restart()
                    continue
                }
                if ($Mode -eq 'Slots' -and $CompleteSlots -and $sent -and $receivedFrame.Class -eq 0xf6) {
                    Add-Log -Event Complete -Text 'Image transfer acknowledged by client.'
                    # The launcher owns emulator lifetime; keep its virtual cable attached.
                    if ($KeepPipeOpen) {
                        Add-Log -Event Status -Text 'Transfer finished; emulator pipe remains connected until launcher shutdown.'
                        while ($true) { Start-Sleep -Seconds 1 }
                    }
                    return
                }
                if ($Mode -eq 'Slots' -and $receivedFrame.Class -eq 0xf3 -and $null -ne $lastSlotFrame) {
                    Add-Log -Event Status -Text 'Peer reported a receive error; retransmitting the outstanding record.'
                    Write-WireFrame $lastSlotFrame
                    continue
                }
                if ($sent) {
                    continue
                }
                switch ($Mode) {
                    'Slots' {
                        if ($receivedFrame.Session.Length -lt 3) { continue ReceivedOctets }
                        if ($null -eq $initialFrame) {
                            $initialFrame = $receivedFrame
                            Write-WireFrame (New-Frame -Class 0xf5 -SessionPayload ([byte[]]@(0, 0, 0xff)))
                            # Permit the ROM's initial control request before replying.
                            Write-WireFrame (New-Frame -Class 0xf1 -SessionPayload ([byte[]]@(0, 0, 0)))
                            continue ReceivedOctets
                        }
                        if ($Menu -and $menuPhase -lt 3) {
                            if ($menuPhase -eq 0) {
                                if ($receivedFrame.Session.Length -le 3) { continue ReceivedOctets }
                                $body = New-LoadPayload -Address 0 -Local $receivedFrame.Session[0] `
                                    -Remote (($receivedFrame.Session[0]+1)-band 255) -Code ([byte[]]$menuBytes[0..127])
                                $body[$body.Length-1] = 0x0c
                                $menuPhase = 1
                            }
                            elseif ($menuPhase -eq 1) {
                                if ($receivedFrame.Session[1] -ne 0) { continue ReceivedOctets }
                                $body = New-LoadPayload -Address 1 -Local $receivedFrame.Session[0] `
                                    -Remote (($receivedFrame.Session[0]+1)-band 255) -Code ([byte[]]$menuBytes[128..255])
                                $body[$body.Length-1] = 0x0c
                                $menuPhase = 2
                            }
                            else {
                                if ($receivedFrame.Class -ne 0xf0 -or $receivedFrame.Session.Length -ne 8 -or
                                    $receivedFrame.Session[3] -ne 2 -or $receivedFrame.Session[4] -ne 0x80) {
                                    continue ReceivedOctets
                                }
                                $key = [int]$receivedFrame.Session[6]+1
                                if (-not $menuEntries.ContainsKey($key)) { throw "Client selected disabled F$key" }
                                $selected = $menuEntries[$key]
                                Add-Log -Event Comment -Text "Menu selection F${key}: $($selected.Text); image $($selected.Path)."
                                $testPayloads = [Collections.Generic.List[byte[]]]::new()
                                for ($offset=0; $offset -lt $selected.Bytes.Length; $offset+=128) {
                                    $testPayloads.Add([byte[]]$selected.Bytes[$offset..($offset+127)])
                                }
                                $sequenceBase = 2
                                $menuPhase = 3
                            }
                            if ($menuPhase -lt 3) {
                                $lastSlotFrame = New-Frame -Class 0xf0 -SessionPayload $body
                                Write-WireFrame $lastSlotFrame
                                $activity.Restart()
                                continue ReceivedOctets
                            }
                        }
                        if ($recordNumber -eq 0) {
                            if ($receivedFrame.Session.Length -le 3) { continue ReceivedOctets }
                            $slotCount = $testPayloads.Count + 4
                            $entryOffset = 0
                            if ($CompleteSlots) {
                                $slotCount = $testPayloads.Count
                                $entryOffset = 0x7c00
                            }
                            $body = New-TransferPayload -Address $sequenceBase -Local $receivedFrame.Session[0] -Remote (($receivedFrame.Session[0]+1)-band 255) `
                                -Control $slotCount -Offset $entryOffset
                        }
                        else {
                            if ($receivedFrame.Session[1] -ne (($sequenceBase + $recordNumber - 1) -band 0xff)) {
                                continue ReceivedOctets
                            }
                            $body = New-LoadPayload -Address (($sequenceBase+$recordNumber)-band 255) `
                                -Local $receivedFrame.Session[0] -Remote (($receivedFrame.Session[0] + 1) -band 0xff) `
                                -Code ([byte[]]$testPayloads[$recordNumber - 1])
                            $body[$body.Length - 1] = 0x0c
                        }
                        $lastSlotFrame = New-Frame -Class 0xf0 -SessionPayload $body
                        if (-not $staleInjected -and $recordNumber -eq $PreviousCounterAtRecord) {
                            $stale = [byte[]]$body.Clone()
                            $stale[0] = ($stale[0] + 255) -band 255
                            Add-Log -Event Comment -Text "Inject previous DATA receive sequence $($stale[0]) instead of $($body[0]); payload unchanged and CRC recomputed."
                            Write-WireFrame (New-Frame -Class 0xf0 -SessionPayload $stale)
                            $stalePending = $true
                            $staleInjected = $true
                            continue ReceivedOctets
                        }
                        Write-WireFrame $lastSlotFrame
                        $recordNumber++
                        $activity.Restart()
                        $sent = $recordNumber -gt $testPayloads.Count
                        continue ReceivedOctets
                    }
                    'Handshake' {
                        if ($receivedFrame.Session.Length -ne 3) { continue ReceivedOctets }
                        if ($null -eq $initialFrame) {
                            $initialFrame = $receivedFrame
                            $start = New-Frame -Class 0xF5 -SessionPayload ([byte[]]@($initialFrame.Session[0], 0, 0xff))
                            Write-WireFrame $start
                        }
                        elseif ($receivedFrame.Session[1] -ne (($initialFrame.Session[0] + $recordNumber - 1) -band 0xff)) {
                            Add-Log -Event Status -Text 'Waiting for acknowledgement of the preceding LOAD.'
                            continue ReceivedOctets
                        }
                        $body = New-LoadPayload -Address (($initialFrame.Session[0] + $recordNumber) -band 0xff) `
                            -Local (($initialFrame.Session[2] + $recordNumber) -band 0xff) `
                            -Remote 0xff -Code ([byte[]]$testPayloads[$recordNumber])
                        Write-WireFrame (New-Frame -Class 0xF0 -SessionPayload $body)
                        $recordNumber++
                        $sent = $recordNumber -ge $testPayloads.Count
                        continue ReceivedOctets
                    }
                }
            }
        }
    }
}
finally {
    if ($null -ne $pipe) { $pipe.Dispose() }
    if ($null -ne $serial) { $serial.Dispose() }
    $traceWriter.Dispose()
}
