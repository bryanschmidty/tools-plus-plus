# Converts a source image to Bedrock-ready pack_icon.png (256x256 square PNG).
# Writes the same icon to both Tools++ pack roots.

param(
    [string]$InputPath = (Join-Path $env:USERPROFILE "Downloads\pack_image.png"),
    [int]$Size = 256
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Targets = @(
    (Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP\pack_icon.png"),
    (Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP\pack_icon.png")
)

if (-not (Test-Path $InputPath)) {
    throw "Input image not found: $InputPath"
}

function Convert-PackIcon {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$TargetSize
    )

    $source = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $cropSize = [Math]::Min($source.Width, $source.Height)
        $cropX = [int](($source.Width - $cropSize) / 2)
        $cropY = [int](($source.Height - $cropSize) / 2)

        $cropped = New-Object System.Drawing.Bitmap $cropSize, $cropSize
        $cropGraphics = [System.Drawing.Graphics]::FromImage($cropped)
        try {
            $cropGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $cropGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $cropGraphics.DrawImage(
                $source,
                (New-Object System.Drawing.Rectangle 0, 0, $cropSize, $cropSize),
                (New-Object System.Drawing.Rectangle $cropX, $cropY, $cropSize, $cropSize),
                [System.Drawing.GraphicsUnit]::Pixel
            )
        }
        finally {
            $cropGraphics.Dispose()
        }

        $target = New-Object System.Drawing.Bitmap $TargetSize, $TargetSize
        $targetGraphics = [System.Drawing.Graphics]::FromImage($target)
        try {
            $targetGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $targetGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $targetGraphics.DrawImage($cropped, 0, 0, $TargetSize, $TargetSize)
        }
        finally {
            $targetGraphics.Dispose()
        }

        $cropped.Dispose()
        $target.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $target.Dispose()
    }
    finally {
        $source.Dispose()
    }
}

foreach ($targetPath in $Targets) {
    $targetDir = Split-Path $targetPath -Parent
    if (-not (Test-Path $targetDir)) {
        throw "Pack directory not found: $targetDir"
    }
    Convert-PackIcon -SourcePath $InputPath -DestinationPath $targetPath -TargetSize $Size
    Write-Host "OK: $targetPath (${Size}x${Size})"
}
