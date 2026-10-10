# Send-FunctionKey.ps1

param([ValidateRange(1,8)][int]$Key = 3)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class MenuKeyboard {
    [DllImport("user32.dll", SetLastError=true)]
    static extern bool PostMessage(IntPtr window, uint message, IntPtr key, IntPtr flags);
    public static void Send(IntPtr window, int key) {
        int scan = 0x3a + key;
        int flags = 1 | (scan << 16);
        if (!PostMessage(window, 0x100, (IntPtr)(0x6f + key), (IntPtr)flags) ||
            !PostMessage(window, 0x101, (IntPtr)(0x6f + key), (IntPtr)(flags | unchecked((int)0xc0000000))))
            throw new System.ComponentModel.Win32Exception();
    }
}
'@
$process = @(Get-Process 86Box)
if ($process.Count -ne 1 -or $process[0].MainWindowHandle -eq 0) { throw 'Expected one 86Box window.' }
[MenuKeyboard]::Send($process[0].MainWindowHandle, $Key)
Write-Host "Posted F$Key make and break to the 86Box window."
