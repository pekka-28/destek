# Start-86Box.ps1

[CmdletBinding()]
param(
    [string]$Image,
    [string]$Menu,
    [ValidateRange(1,8)][int]$MenuKey = 3,
    [string]$GdbScript,
    [switch]$WaitDebugger,
    [switch]$Release,
    [string]$Mingw = 'C:/msys64/mingw64',
    [switch]$Hidden,
    [ValidateRange(-1, 248)][int]$PreviousCounterAtRecord = -1,
    [ValidateRange(1, 3600)][int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$vm = Join-Path $PSScriptRoot '86box'
$exe = Join-Path $vm 'runtime/86Box.exe'
$autoContinue = -not $GdbScript -and -not $WaitDebugger -and -not $Release
if ($autoContinue) { $GdbScript = Join-Path $vm 'Continue.gdb' }
if ($GdbScript -or $WaitDebugger) {
    $exe = Join-Path $vm 'debug-build/src/86Box.exe'
    $env:PATH = "$Mingw/bin;$env:PATH"
    $env:QT_QPA_PLATFORM_PLUGIN_PATH = "$Mingw/share/qt5/plugins"
    if ($GdbScript) { $GdbScript = (Resolve-Path -LiteralPath $GdbScript).Path }
}
if (-not (Test-Path $exe)) { throw "86Box is not installed at $exe" }
if (-not $Image) { $Image = Join-Path $root 'boot/Hello.bin' }
$Image = (Resolve-Path -LiteralPath $Image).Path
$log = Join-Path $vm 'bootstrap-wire.log'
$captureDirectory = Join-Path $vm 'traces'
$startedAt = [DateTime]::UtcNow
$captureName = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [IO.Path]::GetFileNameWithoutExtension($Image)
$imageSnapshot = [IO.File]::ReadAllBytes($Image)
$previousImageEnvironment = $env:DESTEK_TEST_IMAGE
$env:DESTEK_TEST_IMAGE = $Image
$previousMenuKey = $env:DESTEK_MENU_KEY
$env:DESTEK_MENU_KEY = [string]$MenuKey
$hostProcess = $null
$emulator = $null

$debugger = $null
try {
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        ('"' + (Join-Path $root 'boot/Boot-Image.ps1') + '"'),
        '-Mode', 'Send', '-KeepPipeOpen', '-PipeName', 'destek-86box', '-Image', ('"' + $Image + '"'),
        '-PreviousCounterAtRecord', $PreviousCounterAtRecord,
        '-TimeoutSeconds', $TimeoutSeconds, '-LogPath', ('"' + $log + '"'))
    if ($Menu) { $arguments += @('-Menu', ('"'+(Resolve-Path -LiteralPath $Menu).Path+'"')) }
    $hostProcess = Start-Process powershell -ArgumentList $arguments `
        -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $vm 'host.out.log') `
        -RedirectStandardError (Join-Path $vm 'host.err.log')
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while (-not ([IO.Directory]::GetFiles('\\.\pipe\') -contains '\\.\pipe\destek-86box')) {
        if ($hostProcess.HasExited) { throw (Get-Content (Join-Path $vm 'host.err.log') -Raw) }
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Host did not create its named pipe.' }
        Start-Sleep -Milliseconds 100
    }
    $windowStyle = if ($Hidden) { 'Hidden' } else { 'Normal' }
    $emulator = Start-Process $exe -WorkingDirectory $vm -WindowStyle $windowStyle -PassThru `
        -ArgumentList @('-P', ('"' + $vm + '"'), '-N', '-R',
            ('"' + (Join-Path $vm 'runtime/roms') + '"'), '-L',
            ('"' + (Join-Path $vm '86box.log') + '"'))
    if ($GdbScript) {
        $deadline = [DateTime]::UtcNow.AddSeconds(15)
        while (-not (Get-NetTCPConnection -LocalPort 12345 -State Listen -ErrorAction SilentlyContinue)) {
            if ($emulator.HasExited) { throw '86Box exited before opening its debugger.' }
            if ([DateTime]::UtcNow -gt $deadline) { throw '86Box debugger did not listen.' }
            Start-Sleep -Milliseconds 100
        }
        $debugger = Start-Process (Join-Path $Mingw 'bin/gdb.exe') `
            -WindowStyle Hidden -PassThru -WorkingDirectory $root `
            -ArgumentList @('-q', '-batch', '-x', ('"' + $GdbScript + '"')) `
            -RedirectStandardOutput (Join-Path $vm 'debugger.log') `
            -RedirectStandardError (Join-Path $vm 'debugger.err.log')
        $null = $debugger.Handle
    }
    Write-Host '86Box: IBM PC, 8088, MDA, unchanged option ROM, COM1.'
    Write-Host "Channel log: $log"
    if ($WaitDebugger) { Write-Host 'Guest halted. Attach GDB to 127.0.0.1:12345, then continue.' }
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while (-not $emulator.HasExited) {
        if ($debugger -and $debugger.HasExited) {
            $debugger.WaitForExit()
            if ($debugger.ExitCode -ne 0) {
                throw "Debugger failed with exit $($debugger.ExitCode); see $vm/debugger.log and debugger.err.log."
            }
            if (-not $autoContinue) {
                Write-Host 'Debugger test finished; inspect debugger.log for assertions.'
                return
            }
            $debugger = $null
        }
        if ($hostProcess.HasExited -and (Get-Item (Join-Path $vm 'host.err.log')).Length) {
            throw (Get-Content (Join-Path $vm 'host.err.log') -Raw)
        }
        if ([DateTime]::UtcNow -gt $deadline) { throw '86Box test window expired; inspect the channel log.' }
        Start-Sleep -Milliseconds 200
    }
}
finally {
    $env:DESTEK_TEST_IMAGE = $previousImageEnvironment
    $env:DESTEK_MENU_KEY = $previousMenuKey
    foreach ($process in $debugger, $emulator, $hostProcess) {
        if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
    }
    if ((Test-Path -LiteralPath $log) -and [IO.File]::GetLastWriteTimeUtc($log) -ge $startedAt) {
        New-Item -ItemType Directory -Force -Path $captureDirectory | Out-Null
        $capture = Join-Path $captureDirectory $captureName
        $lines = [IO.File]::ReadAllLines($log)
        if ($lines.Length -and $lines[0] -match '^([^\t]+)\tComment') {
            $lines[0] = "$($Matches[1])`tComment `t$captureName.trace.log"
        }
        [IO.File]::WriteAllLines("$capture.trace.log", $lines)
        [IO.File]::WriteAllBytes("$capture.image.bin", $imageSnapshot)
        if ($debugger -and (Test-Path (Join-Path $vm 'debugger.log'))) {
            Copy-Item -LiteralPath (Join-Path $vm 'debugger.log') -Destination "$capture.debugger.log"
        }
        Write-Host "Preserved trace and image: $capture"
    }
}
