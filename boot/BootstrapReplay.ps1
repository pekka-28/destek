# BootstrapReplay.ps1

function Read-WireTrace {
    param([Parameter(Mandatory)][string]$Path)
    $lastTime = $null
    $count = 0
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -notmatch '^\s*(\S+)\s+(Send|Receive)\s+(.*?)\s*$') { continue }
        $time = [DateTimeOffset]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture)
        $direction = $Matches[2]
        $hex = $Matches[3]
        if ($hex -notmatch '^[0-9a-fA-F]{2}(\s+[0-9a-fA-F]{2})*$') {
            throw "Invalid hex row: $line"
        }
        if ($null -ne $lastTime -and $time -lt $lastTime) { throw 'Trace timestamps run backwards.' }
        $bytes = [byte[]]@($hex -split '\s+' | ForEach-Object { [Convert]::ToByte($_, 16) })
        [pscustomobject]@{ Time = $time; Direction = $direction; Bytes = $bytes }
        $lastTime = $time
        $count++
    }
    if ($count -eq 0) { throw 'Trace contains no Send/Receive hex records.' }
}

function Invoke-WireReplay {
    param($Pipe, [object[]]$Events, [int]$ReceiveTimeoutMilliseconds = 10000)
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $lastRecorded = $Events[0].Time
    $lastActual = 0.0
    $record = 0
    foreach ($event in $Events) {
        $record++
        $gap = ($event.Time - $lastRecorded).TotalMilliseconds
        $due = $lastActual + $gap
        if ($event.Direction -eq 'Send') {
            while ($clock.Elapsed.TotalMilliseconds -lt $due) {
                $remaining = $due - $clock.Elapsed.TotalMilliseconds
                Start-Sleep -Milliseconds ([Math]::Max(1, [Math]::Min(50, [int]$remaining)))
            }
            $eventTime = $clock.Elapsed.TotalMilliseconds
            Add-Log -Event Send -Text (Format-WireHex $event.Bytes)
            $Pipe.Write($event.Bytes, 0, $event.Bytes.Length)
            $Pipe.Flush()
            Add-Log -Event Sent -Text ("Replay {0} octets; recorded gap {1:F3} ms; scheduling lag {2:F3} ms" -f $event.Bytes.Length, $gap, ($eventTime - $due))
        }
        else {
            # Match the byte stream, regardless of how pipe reads are split.
            $buffer = New-Object byte[] $event.Bytes.Length
            $position = 0
            $deadline = [Math]::Max($due, $clock.Elapsed.TotalMilliseconds) + $ReceiveTimeoutMilliseconds
            while ($position -lt $buffer.Length) {
                $read = $Pipe.BeginRead($buffer, $position, $buffer.Length - $position, $null, $null)
                $timeout = [Math]::Max(1, [int]($deadline - $clock.Elapsed.TotalMilliseconds))
                if (-not $read.AsyncWaitHandle.WaitOne($timeout)) {
                    $Pipe.Dispose()
                    throw "Replay record ${record}: expected response timed out."
                }
                $size = $Pipe.EndRead($read)
                $eventTime = $clock.Elapsed.TotalMilliseconds
                if ($size -eq 0) { throw "Replay record ${record}: peer disconnected before the expected response." }
                Add-Log -Event Receive -Text (Format-WireHex $buffer[$position..($position + $size - 1)])
                for ($index = $position; $index -lt $position + $size; $index++) {
                    if ($buffer[$index] -ne $event.Bytes[$index]) {
                        Add-Log -Event Expected -Text (Format-WireHex $event.Bytes)
                        throw ('Replay record {0}, byte {1}: expected {2:X2}, received {3:X2}. Playback aborted.' -f `
                            $record, $index, $event.Bytes[$index], $buffer[$index])
                    }
                }
                $position += $size
            }
            Add-Log -Event Received -Text ("Replay matched {0} octets" -f $buffer.Length)
        }
        $lastRecorded = $event.Time
        $lastActual = $eventTime
    }
    Add-Log -Event Complete -Text 'Replay finished; all expected input matched.'
}
