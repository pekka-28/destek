# Capture-Window.ps1

param([string]$Path = "$PSScriptRoot/screen.png")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class EmulatorWindow {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr h, int command);
    public delegate bool EnumWindowsProc(IntPtr h, IntPtr arg);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr arg);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr h, out uint processId);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern int GetClassName(IntPtr h, System.Text.StringBuilder name, int capacity);
    public static IntPtr FindWindow(uint processId) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((h, arg) => {
            uint owner;
            Rect r;
            GetWindowThreadProcessId(h, out owner);
            var name = new System.Text.StringBuilder(256);
            GetClassName(h, name, name.Capacity);
            if (owner == processId && name.ToString() == "SDL_app" && GetWindowRect(h, out r) &&
                r.Right-r.Left >= 320 && r.Bottom-r.Top >= 200) {
                found = h;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr h, out Rect r);
    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
}
'@
$process = @(Get-Process 86Box)
if ($process.Count -ne 1) { throw 'Expected exactly one running 86Box instance.' }
[void][EmulatorWindow]::SetProcessDPIAware()
$window = [EmulatorWindow]::FindWindow([uint32]$process[0].Id)
if ($window -eq [IntPtr]::Zero) { throw 'No emulator display window found.' }
# The requested screenshot needs a rendered SDL window. Show without taking focus.
[void][EmulatorWindow]::ShowWindow($window, 4)
Start-Sleep -Milliseconds 500
$rect = New-Object EmulatorWindow+Rect
[void][EmulatorWindow]::GetWindowRect($window, [ref]$rect)
$bitmap = New-Object Drawing.Bitmap ($rect.Right-$rect.Left), ($rect.Bottom-$rect.Top)
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$dc = $graphics.GetHdc()
try {
    if (-not [EmulatorWindow]::PrintWindow($window, $dc, 2)) { throw 'Emulator window capture failed.' }
}
finally { $graphics.ReleaseHdc($dc) }
$bitmap.Save([IO.Path]::GetFullPath($Path), [Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
