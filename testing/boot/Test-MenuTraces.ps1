# Test-MenuTraces.ps1

$ErrorActionPreference = 'Stop'
$boot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../boot'))
. "$boot/Bootstrap-server.ps1" -ValidateOnly
$configuration = Get-Content -Raw "$boot/Menu.json" | ConvertFrom-Json
$expectedMenu = New-Object byte[] 256
foreach ($item in $configuration.Items) {
    $expectedMenu[1+$item.Key] = 1
    [Text.Encoding]::ASCII.GetBytes($item.Text.PadRight(30)).CopyTo($expectedMenu,10+30*($item.Key-1))
}
$savedMenu = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot '86box/Menu.table.bin'))
if ([Convert]::ToBase64String($savedMenu) -ne [Convert]::ToBase64String($expectedMenu)) {
    throw 'Saved guest menu memory differs from all 256 configured bytes.'
}
foreach ($key in 1,3) {
    $records = [Collections.Generic.List[object]]::new()
    $selection = $null
    $complete = $false
    $parsers = @{ Send=(New-FrameParser); Receive=(New-FrameParser) }
    foreach ($line in Get-Content "$boot/MenuF$key.trace.log") {
        $fields = $line.Split([char]9,3)
        if ($fields.Count -ne 3 -or $fields[1].Trim() -notin 'Send','Receive') { continue }
        $direction = $fields[1].Trim()
        foreach ($hex in $fields[2].Trim() -split ' +') {
            $frame = Add-ReceivedByte $parsers[$direction] ([Convert]::ToByte($hex,16))
            if ($null -eq $frame) { continue }
            if (-not $frame.Valid) { throw 'Invalid captured frame.' }
            if ($direction -eq 'Send' -and $frame.Class -eq 0xf0) { $records.Add($frame) }
            if ($direction -eq 'Receive' -and $frame.Class -eq 0xf6) { $complete=$true }
            if ($direction -eq 'Receive' -and $frame.Class -eq 0xf0 -and $frame.Session.Length -eq 8 -and
                [BitConverter]::ToUInt16([byte[]]$frame.Session,3) -eq 0x8002) {
                if ($frame.Session[6] -ne $key-1) { throw 'Wrong selection in trace.' }
                $selection=$frame
            }
        }
    }
    if (-not $complete -or $null -eq $selection) { throw 'Missing selection or COMPLETE.' }
    $menuPayload = [byte[]]($records[0].Session[3..130]+$records[1].Session[3..130])
    if ([Convert]::ToBase64String($menuPayload) -ne [Convert]::ToBase64String($expectedMenu)) { throw 'Menu trace mismatch.' }
    $entry = $configuration.Items | Where-Object Key -eq $key
    $expectedImage = [IO.File]::ReadAllBytes((Join-Path $boot $entry.Image))
    $payload = [Collections.Generic.List[byte]]::new()
    for ($i=0; $i -lt $records.Count; $i++) {
        if ($records[$i].Session[0] -ne $i) { throw 'Menu/image receive sequence did not continue.' }
        if ($i -gt 2) { $payload.AddRange([byte[]]$records[$i].Session[3..130]) }
    }
    if ([BitConverter]::ToUInt16([byte[]]$records[2].Session,3) -ne $expectedImage.Length/128 -or
        [BitConverter]::ToUInt16([byte[]]$records[2].Session,5) -ne 0x7c00) { throw 'Wrong selected-image control.' }
    if ([Convert]::ToBase64String($payload.ToArray()) -ne [Convert]::ToBase64String($expectedImage)) { throw 'Selected image trace mismatch.' }
    Write-Host "Verified F$key menu, selection, continued sequences, image bytes and COMPLETE."
}
