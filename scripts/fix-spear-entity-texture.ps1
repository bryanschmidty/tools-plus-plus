# Builds a 32x32 spear entity texture from the 16x16 item icon,
# oriented like vanilla entity/spear/*.png (mirrored vs inventory icon).

param(
    [string]$ItemIconPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_spear.png"),
    [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "resource_packs\ToolsPlusPlus_RP\textures\entity\spear\ruby_spear.png")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $ItemIconPath)) {
    throw "Item icon not found: $ItemIconPath"
}

$source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $ItemIconPath))
try {
    # Inventory icons run bottom-left -> top-right; entity spear textures are mirrored.
    $source.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)

    $target = New-Object System.Drawing.Bitmap 32, 32, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $graphics.DrawImage($source, 0, 0, 32, 32)
    $graphics.Dispose()

    $outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDir = Split-Path $outputFullPath -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    $tempPath = Join-Path $outputDir ([System.IO.Path]::GetFileName($outputFullPath) + ".convert-tmp.png")
    if (Test-Path $tempPath) { Remove-Item $tempPath -Force }
    $target.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $target.Dispose()

    if (Test-Path $outputFullPath) { Remove-Item $outputFullPath -Force }
    Move-Item -Path $tempPath -Destination $outputFullPath -Force

    Write-Host "Wrote entity spear texture: $outputFullPath"
}
finally {
    $source.Dispose()
}
