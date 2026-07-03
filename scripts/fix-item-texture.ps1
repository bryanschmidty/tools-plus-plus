# Converts item PNGs to Bedrock-ready 16x16 RGBA format.
# Fix one texture in place, or fix every texture listed in item_texture.json.

param(
    [string]$InputPath,
    [string]$OutputPath,
    [switch]$All,
    [switch]$RemoveWhiteBackground
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ResourcePackRoot = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"

function Convert-ItemTextureFile {
    param(
        [Parameter(Mandatory = $true)][string]$InputPath,
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [switch]$RemoveWhiteBackground
    )

    if (-not (Test-Path $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $InputPath))
    $target = $null
    $normalized = $null

    try {
        # Normalize to 32bpp ARGB so alpha reads correctly from PNG sources.
        $normalized = New-Object System.Drawing.Bitmap $source.Width, $source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($normalized)
        $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        $graphics.DrawImage($source, 0, 0, $source.Width, $source.Height)
        $graphics.Dispose()
        $source.Dispose()
        $source = $null

        $target = New-Object System.Drawing.Bitmap 16, 16, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $sameSize = ($normalized.Width -eq 16 -and $normalized.Height -eq 16)

        for ($x = 0; $x -lt 16; $x++) {
            for ($y = 0; $y -lt 16; $y++) {
                if ($sameSize) {
                    $srcX = $x
                    $srcY = $y
                }
                else {
                    $srcX = [int][Math]::Floor($x * $normalized.Width / 16.0)
                    $srcY = [int][Math]::Floor($y * $normalized.Height / 16.0)
                    if ($srcX -ge $normalized.Width) { $srcX = $normalized.Width - 1 }
                    if ($srcY -ge $normalized.Height) { $srcY = $normalized.Height - 1 }
                }

                $color = $normalized.GetPixel($srcX, $srcY)

                if ($RemoveWhiteBackground -and $color.A -gt 16 -and $color.R -gt 230 -and $color.G -gt 230 -and $color.B -gt 230) {
                    $target.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                }
                else {
                    $target.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($color.A, $color.R, $color.G, $color.B))
                }
            }
        }

        $outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
        $outputDir = Split-Path $outputFullPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $tempPath = Join-Path $outputDir ([System.IO.Path]::GetFileName($outputFullPath) + ".convert-tmp.png")
        if (Test-Path $tempPath) { Remove-Item $tempPath -Force }

        $target.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $target.Dispose()
        $target = $null
        $normalized.Dispose()
        $normalized = $null

        if (Test-Path $outputFullPath) { Remove-Item $outputFullPath -Force }
        Move-Item -Path $tempPath -Destination $outputFullPath -Force

        Write-Host "Wrote: $outputFullPath"
    }
    finally {
        if ($source) { $source.Dispose() }
        if ($normalized) { $normalized.Dispose() }
        if ($target) { $target.Dispose() }
    }
}

function Get-ItemTexturePaths {
    $itemTexturePath = Join-Path $ResourcePackRoot "textures\item_texture.json"
    if (-not (Test-Path $itemTexturePath)) {
        throw "Missing item_texture.json: $itemTexturePath"
    }

    $json = Get-Content $itemTexturePath -Raw | ConvertFrom-Json
    $paths = @()

    foreach ($entry in $json.texture_data.PSObject.Properties) {
        $relativePath = $entry.Value.textures
        if (-not $relativePath) {
            throw "Texture entry '$($entry.Name)' is missing a textures path"
        }
        $paths += Join-Path $ResourcePackRoot ($relativePath + ".png")
    }

    return $paths
}

if ($All) {
    $texturePaths = Get-ItemTexturePaths
    if ($texturePaths.Count -eq 0) {
        throw "No textures found in item_texture.json"
    }

    foreach ($path in $texturePaths) {
        Convert-ItemTextureFile -InputPath $path -OutputPath $path -RemoveWhiteBackground:$RemoveWhiteBackground
    }
}
elseif ($OutputPath -or $InputPath) {
    if (-not $OutputPath) { $OutputPath = $InputPath }
    if (-not $InputPath) { $InputPath = $OutputPath }
    Convert-ItemTextureFile -InputPath $InputPath -OutputPath $OutputPath -RemoveWhiteBackground:$RemoveWhiteBackground
}
else {
    throw @"
Specify one of:
  -All                          Fix every texture in item_texture.json in place
  -OutputPath <path>             Fix one texture in place
  -InputPath <path> -OutputPath <path>   Convert external art into the pack
"@
}

& (Join-Path $PSScriptRoot "validate-textures.ps1")
