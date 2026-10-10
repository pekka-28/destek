# Build-Debugger.ps1

[CmdletBinding()]
param(
    [string]$Mingw = 'C:/msys64/mingw64',
    [string]$CMake
)
$ErrorActionPreference = 'Stop'
$env:PATH = "$Mingw/bin;$env:PATH"
$source = Join-Path $PSScriptRoot 'source'
$build = Join-Path $PSScriptRoot 'debug-build'
foreach ($patchName in 'LocalFixes.patch', 'SerialReceiveTiming.patch') {
    $patch = Join-Path $PSScriptRoot $patchName
    $ErrorActionPreference = 'Continue'
    & git -C $source apply --reverse --check --ignore-space-change $patch 2>&1 | Out-Null
    $alreadyApplied = $LASTEXITCODE -eq 0
    $ErrorActionPreference = 'Stop'
    if (-not $alreadyApplied) {
        & git -C $source apply --check --ignore-space-change $patch
        if ($LASTEXITCODE) { throw 'Local 86Box fixes do not apply cleanly.' }
        & git -C $source apply --ignore-space-change $patch
        if ($LASTEXITCODE) { throw 'Failed to apply local 86Box fixes.' }
    }
}
if (-not $CMake) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    if (Test-Path -LiteralPath $vswhere) {
        $CMake = @(& $vswhere -latest -products '*' -find '**/CMake/bin/cmake.exe' | Select-Object -First 1)[0]
    }
    if (-not $CMake) {
        $command = Get-Command cmake.exe -ErrorAction SilentlyContinue
        if ($command) { $CMake = $command.Source }
    }
    if (-not $CMake) { throw 'Install CMake or provide its executable with -CMake.' }
}
& $cmake -S $source -B $build -G Ninja `
    "-DCMAKE_C_COMPILER=$Mingw/bin/gcc.exe" "-DCMAKE_CXX_COMPILER=$Mingw/bin/g++.exe" `
    "-DCMAKE_PREFIX_PATH=$Mingw" `
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DSTATIC_BUILD=OFF -DGDBSTUB=ON `
    -DDYNAREC=OFF -DQT=OFF -DOPENAL=OFF -DRTMIDI=OFF `
    -DFLUIDSYNTH=OFF -DMUNT=OFF -DSOUNDCANVAS=OFF -DDISCORD=OFF
if ($LASTEXITCODE) { throw '86Box debugger configuration failed.' }
& $cmake --build $build --parallel 4
if ($LASTEXITCODE) { throw '86Box debugger build failed.' }
