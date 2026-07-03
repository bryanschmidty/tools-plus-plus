# Validates Bedrock item PNG textures referenced by item_texture.json.

param(
    [string]$ResourcePackRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "resource_packs\ToolsPlusPlus_RP")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Test-PngSignature {
    param([string]$Path)
    $bytes = Get-Content -Path $Path -Encoding Byte -TotalCount 8
    $signature = [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
    for ($i = 0; $i -lt 8; $i++) {
        if ($bytes[$i] -ne $signature[$i]) {
            throw "Not a PNG file: $Path"
        }
    }
}

function Test-ItemTexturePath {
    param([string]$RelativeTexturePath)

    if ($RelativeTexturePath -cmatch '[A-Z]') {
        throw "Texture path must be lowercase: $RelativeTexturePath"
    }

    if ($RelativeTexturePath -match '\\') {
        throw "Texture path must use forward slashes: $RelativeTexturePath"
    }

    $pngPath = Join-Path $ResourcePackRoot ($RelativeTexturePath + ".png")
    if (-not (Test-Path $pngPath)) {
        throw "Missing texture file: $pngPath"
    }

    Test-PngSignature $pngPath

    $img = [System.Drawing.Image]::FromFile($pngPath)
    try {
        if ($img.Width -ne 16 -or $img.Height -ne 16) {
            throw "Texture must be 16x16 pixels: $pngPath ($($img.Width)x$($img.Height))"
        }

        $allowedFormats = @(
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb,
            [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb
        )
        if ($img.PixelFormat -notin $allowedFormats) {
            throw "Texture must be 32-bit RGBA PNG: $pngPath ($($img.PixelFormat)). Run scripts/fix-item-texture.ps1 to convert it."
        }

        $bitmap = New-Object System.Drawing.Bitmap $img
        $transparentPixels = 0
        for ($x = 0; $x -lt 16; $x++) {
            for ($y = 0; $y -lt 16; $y++) {
                if ($bitmap.GetPixel($x, $y).A -lt 16) {
                    $transparentPixels++
                }
            }
        }
        $bitmap.Dispose()

        if ($transparentPixels -eq 0) {
            Write-Host "NOTE: $pngPath has no transparent pixels. Full-bleed 16x16 icons are valid; transparent corners usually look cleaner in inventory."
        }
        else {
            Write-Host "OK: $pngPath (16x16 RGBA, $transparentPixels transparent pixels)"
        }
    }
    finally {
        $img.Dispose()
    }
}

$itemTexturePath = Join-Path $ResourcePackRoot "textures\item_texture.json"
if (-not (Test-Path $itemTexturePath)) {
    throw "Missing item_texture.json: $itemTexturePath"
}

$json = Get-Content $itemTexturePath -Raw | ConvertFrom-Json

if ($json.texture_name -eq "atlas.terrain") {
    throw "item_texture.json uses atlas.terrain. This corrupts item and inventory textures. Use texture_data only."
}

if (-not $json.texture_data) {
    throw "item_texture.json must define texture_data"
}

$entries = @($json.texture_data.PSObject.Properties)
if ($entries.Count -eq 0) {
    throw "item_texture.json texture_data is empty"
}

foreach ($entry in $entries) {
    $texturePath = $entry.Value.textures
    if (-not $texturePath) {
        throw "Texture entry '$($entry.Name)' is missing a textures path"
    }
    Test-ItemTexturePath $texturePath
}

Write-Host "Texture validation passed."
