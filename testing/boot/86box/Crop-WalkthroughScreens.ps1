# Crop the reference captures to the 720 x 350 MDA viewport without resampling.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$backup = Join-Path $root 'testing/boot/walkthrough/uncropped'
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($name in '02-rom-loading.png','03-download-complete.png','04-hello.png','05-menu.png','06-staged-hello.png') {
    $file = Join-Path $root "docs/screenshots/$name"
    $source = [Drawing.Bitmap]::FromFile($file)
    try {
        if ($source.Width -eq 720 -and $source.Height -eq 350) { continue }
        if ($source.Width -ne 1089 -or $source.Height -ne 569) {
            throw "Inspect the viewport before cropping a new capture size: $name"
        }
        $saved = Join-Path $backup $name
        if (-not (Test-Path -LiteralPath $saved)) { Copy-Item -LiteralPath $file -Destination $saved }
        $viewport = New-Object Drawing.Rectangle 4,26,720,350
        $cropped = $source.Clone($viewport, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            # Assert exact pixel preservation, including the absence of transparent padding.
            for ($y = 0; $y -lt 350; $y++) {
                for ($x = 0; $x -lt 720; $x++) {
                    $pixel = $cropped.GetPixel($x,$y)
                    if ($pixel.A -ne 255 -or $pixel.ToArgb() -ne $source.GetPixel($x+4,$y+26).ToArgb()) {
                        throw "Pixel mismatch in $name at $x,$y"
                    }
                }
            }
            $source.Dispose()
            $source = $null
            $cropped.Save($file, [Drawing.Imaging.ImageFormat]::Png)
        } finally { $cropped.Dispose() }
        Write-Host "Cropped $name to the MDA viewport; pixels verified."
    } finally { if ($source) { $source.Dispose() } }
}
