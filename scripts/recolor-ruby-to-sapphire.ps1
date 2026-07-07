# Recolors Tools++ ruby PNGs to sapphire blues.
# Maps red-dominant gem pixels to the unified sapphire palette by luminance rank.
# Preserves white glints, stone gray, wood brown, and other neutral pixels.

param(
    [string[]]$InputPaths,
    [switch]$All,
    [switch]$InPlace
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ResourcePackRoot = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"
$ItemsDir = Join-Path $ResourcePackRoot "textures\toolsplusplus\items"
$BlocksDir = Join-Path $ResourcePackRoot "textures\toolsplusplus\blocks"
$ArmorDir = Join-Path $ResourcePackRoot "textures\toolsplusplus\models\armor"
$SpearDir = Join-Path $ResourcePackRoot "textures\entity\spear"

$SapphirePaletteHex = @(
    "060646",
    "131959",
    "152075",
    "20409c",
    "69a0e7",
    "90c0ff"
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

    # Ruby gem pixels: red dominates green and blue.
    return ($Color.R -ge ($Color.G + 4)) -or ($Color.R -ge ($Color.B + 4))
}

function Get-ColorKey {
    param([System.Drawing.Color]$Color)
    return "{0},{1},{2},{3}" -f $Color.A, $Color.R, $Color.G, $Color.B
}

function Get-SapphirePalette {
    $palette = @()
    foreach ($hex in $SapphirePaletteHex) {
        $palette += Convert-HexToColor $hex
    }
    return $palette
}

function Build-ColorMap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [System.Drawing.Color[]]$SapphirePalette
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
        Write-Warning "No red-dominant pixels found; copying source unchanged."
        return @{}
    }

    $sorted = @($unique.Values | Sort-Object { Get-Luminance $_ })
    $map = @{}
    $lastIndex = $SapphirePalette.Length - 1

    for ($i = 0; $i -lt $sorted.Count; $i++) {
        $sapphireIndex = if ($sorted.Count -le 1) {
            $lastIndex
        }
        else {
            [int][Math]::Round(($i / ($sorted.Count - 1)) * $lastIndex)
        }
        $sapphireIndex = [Math]::Max(0, [Math]::Min($lastIndex, $sapphireIndex))
        $map[(Get-ColorKey -Color $sorted[$i])] = $SapphirePalette[$sapphireIndex]
    }

    return $map
}

function Convert-TextureFile {
    param(
        [Parameter(Mandatory = $true)][string]$InputPath,
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [System.Drawing.Color[]]$SapphirePalette
    )

    if (-not (Test-Path $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $InputPath))
    $target = $null

    try {
        $colorMap = Build-ColorMap -Bitmap $source -SapphirePalette $SapphirePalette
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

function Get-DefaultRubyToSapphirePairs {
    $pairs = @()

    $itemNames = @(
        "ruby",
        "raw_ruby_chunk",
        "ruby_chunk",
        "ruby_shard",
        "ruby_pickaxe",
        "ruby_axe",
        "ruby_shovel",
        "ruby_hoe",
        "ruby_sword",
        "ruby_spear",
        "ruby_helmet",
        "ruby_chestplate",
        "ruby_leggings",
        "ruby_boots"
    )

    foreach ($name in $itemNames) {
        $sapphireName = $name -replace "ruby", "sapphire"
        $pairs += [PSCustomObject]@{
            Input  = Join-Path $ItemsDir "$name.png"
            Output = Join-Path $ItemsDir "$sapphireName.png"
        }
    }

    foreach ($blockName in @("ruby_ore", "deepslate_ruby_ore", "ruby_block")) {
        $sapphireBlock = $blockName -replace "ruby", "sapphire"
        $pairs += [PSCustomObject]@{
            Input  = Join-Path $BlocksDir "$blockName.png"
            Output = Join-Path $BlocksDir "$sapphireBlock.png"
        }
    }

    foreach ($layer in @("ruby_1", "ruby_2")) {
        $sapphireLayer = $layer -replace "ruby", "sapphire"
        $pairs += [PSCustomObject]@{
            Input  = Join-Path $ArmorDir "$layer.png"
            Output = Join-Path $ArmorDir "$sapphireLayer.png"
        }
    }

    $pairs += [PSCustomObject]@{
        Input  = Join-Path $SpearDir "ruby_spear.png"
        Output = Join-Path $SpearDir "sapphire_spear.png"
    }

    return $pairs
}

$sapphirePalette = Get-SapphirePalette

if ($All) {
    $pairs = Get-DefaultRubyToSapphirePairs
    foreach ($pair in $pairs) {
        Convert-TextureFile -InputPath $pair.Input -OutputPath $pair.Output -SapphirePalette $sapphirePalette
    }
    exit 0
}

if (-not $InputPaths -or $InputPaths.Count -eq 0) {
    throw "Provide -InputPaths or use -All to recolor the full ruby set."
}

foreach ($inputPath in $InputPaths) {
    $leaf = Split-Path $inputPath -Leaf
    $sapphireLeaf = $leaf -replace "ruby", "sapphire"
    $outputPath = if ($InPlace) { $inputPath } else { Join-Path (Split-Path $inputPath -Parent) $sapphireLeaf }
    Convert-TextureFile -InputPath $inputPath -OutputPath $outputPath -SapphirePalette $sapphirePalette
}
