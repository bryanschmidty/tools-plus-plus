# Recolors diamond-style armor layer PNGs (64x32) from blue/cyan to ruby reds.
# Maps each unique source color to the Tools++ ruby palette by luminance rank.

param(
    [string[]]$InputPaths,
    [string]$OutputDirectory,
    [switch]$InPlace
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ResourcePackRoot = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"
$DefaultArmorDir = Join-Path $ResourcePackRoot "textures\toolsplusplus\models\armor"
$DefaultDownloads = Join-Path $env:USERPROFILE "Downloads"

$RubyPaletteHex = @(
    "460606",
    "591313",
    "751515",
    "9c2020",
    "e76969",
    "ff9090"
)

function Convert-HexToColor {
    param([string]$Hex)
    $Hex = $Hex.Trim().TrimStart("#")
    if ($Hex.Length -ne 6) {
        throw "Invalid hex color: $Hex"
    }
    return [System.Drawing.Color]::FromArgb(
        255,
        [Convert]::ToInt32($Hex.Substring(0, 2), 16),
        [Convert]::ToInt32($Hex.Substring(2, 2), 16),
        [Convert]::ToInt32($Hex.Substring(4, 2), 16)
    )
}

function Get-Luminance {
    param([System.Drawing.Color]$Color)
    return (0.299 * $Color.R) + (0.587 * $Color.G) + (0.114 * $Color.B)
}

function Test-RecolorCandidate {
    param([System.Drawing.Color]$Color)

    if ($Color.A -le 16) {
        return $false
    }

    $maxChannel = [Math]::Max($Color.R, [Math]::Max($Color.G, $Color.B))
    $minChannel = [Math]::Min($Color.R, [Math]::Min($Color.G, $Color.B))
    $spread = $maxChannel - $minChannel

    if ($spread -lt 8) {
        return $false
    }

    # Diamond armor layers are cyan/teal: green and blue dominate red.
    return ($Color.B -ge ($Color.R + 4)) -or ($Color.G -ge ($Color.R + 8))
}

function Get-ColorKey {
    param([System.Drawing.Color]$Color)
    return "{0},{1},{2},{3}" -f $Color.A, $Color.R, $Color.G, $Color.B
}

function Get-RubyPalette {
    $palette = @()
    foreach ($hex in $RubyPaletteHex) {
        $palette += Convert-HexToColor $hex
    }
    return $palette
}

function Build-ColorMap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [System.Drawing.Color[]]$RubyPalette
    )

    $unique = @{}
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $color = $Bitmap.GetPixel($x, $y)
            if (-not (Test-RecolorCandidate -Color $color)) {
                continue
            }
            $unique[(Get-ColorKey -Color $color)] = $color
        }
    }

    if ($unique.Count -eq 0) {
        throw "No blue/cyan armor pixels found to recolor."
    }

    $sorted = @($unique.Values | Sort-Object { Get-Luminance $_ })
    $map = @{}
    $lastIndex = $RubyPalette.Length - 1

    for ($i = 0; $i -lt $sorted.Count; $i++) {
        $rubyIndex = if ($sorted.Count -le 1) {
            $lastIndex
        }
        else {
            [int][Math]::Round(($i / ($sorted.Count - 1)) * $lastIndex)
        }
        $rubyIndex = [Math]::Max(0, [Math]::Min($lastIndex, $rubyIndex))
        $map[(Get-ColorKey -Color $sorted[$i])] = $RubyPalette[$rubyIndex]
    }

    return $map
}

function Convert-ArmorLayerFile {
    param(
        [Parameter(Mandatory = $true)][string]$InputPath,
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [System.Drawing.Color[]]$RubyPalette
    )

    if (-not (Test-Path $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $InputPath))
    $target = $null

    try {
        if ($source.Width -ne 64 -or $source.Height -ne 32) {
            Write-Warning "Expected 64x32 armor layer, got $($source.Width)x$($source.Height): $InputPath"
        }

        $colorMap = Build-ColorMap -Bitmap $source -RubyPalette $RubyPalette
        $target = New-Object System.Drawing.Bitmap $source.Width, $source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

        for ($x = 0; $x -lt $source.Width; $x++) {
            for ($y = 0; $y -lt $source.Height; $y++) {
                $color = $source.GetPixel($x, $y)
                $key = Get-ColorKey -Color $color

                if ($colorMap.ContainsKey($key)) {
                    $mapped = $colorMap[$key]
                    $target.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($color.A, $mapped.R, $mapped.G, $mapped.B))
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

        $tempPath = Join-Path $outputDir ([System.IO.Path]::GetFileName($outputFullPath) + ".recolor-tmp.png")
        if (Test-Path $tempPath) { Remove-Item $tempPath -Force }

        $target.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        if (Test-Path $outputFullPath) { Remove-Item $outputFullPath -Force }
        Move-Item -Path $tempPath -Destination $outputFullPath -Force

        Write-Host "Wrote: $outputFullPath ($($colorMap.Count) source colors mapped)"
    }
    finally {
        if ($source) { $source.Dispose() }
        if ($target) { $target.Dispose() }
    }
}

$rubyPalette = Get-RubyPalette

if (-not $InputPaths -or $InputPaths.Count -eq 0) {
    $InputPaths = @(
        (Join-Path $DefaultDownloads "ruby_1.png"),
        (Join-Path $DefaultDownloads "ruby_2.png")
    )
}

if (-not $OutputDirectory) {
    $OutputDirectory = $DefaultArmorDir
}

foreach ($inputPath in $InputPaths) {
    if ($InPlace) {
        $outputPath = $inputPath
    }
    else {
        $outputPath = Join-Path $OutputDirectory (Split-Path $inputPath -Leaf)
    }

    Convert-ArmorLayerFile -InputPath $inputPath -OutputPath $outputPath -RubyPalette $rubyPalette
}
