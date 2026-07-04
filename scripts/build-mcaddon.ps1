# Builds a distributable Tools++ .mcaddon (BP + RP .mcpack files inside).

param(
    [string]$OutputDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "dist")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BpSource = Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP"
$RpSource = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"

function Write-BuildHeading {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Cyan
}

function Write-BuildItem {
    param(
        [string]$Label,
        [string]$Value,
        [ConsoleColor]$Color = 'Green'
    )
    Write-Host ("  {0,-10} {1}" -f "${Label}:", $Value) -ForegroundColor $Color
}

function Get-PackVersionLabel {
    param([string]$ManifestPath)

    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $version = $manifest.header.version
    if ($version -is [System.Array]) {
        return ($version -join ".")
    }

    return [string]$version
}

function New-PackZipArchive {
    param(
        [string]$SourceFolder,
        [string]$DestinationPath
    )

    if (-not (Test-Path $SourceFolder)) {
        throw "Pack folder not found: $SourceFolder"
    }

    $parent = Split-Path $DestinationPath -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $DestinationPath) {
        Remove-Item $DestinationPath -Force
    }

    $sourceFull = [System.IO.Path]::GetFullPath($SourceFolder)
    $archive = [System.IO.Compression.ZipFile]::Open(
        $DestinationPath,
        [System.IO.Compression.ZipArchiveMode]::Create
    )

    try {
        foreach ($file in Get-ChildItem $SourceFolder -Recurse -File) {
            $relative = $file.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
            $entryName = $relative -replace '\\', '/'
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $file.FullName,
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Copy-PackFolder {
    param(
        [string]$SourceFolder,
        [string]$DestinationFolder
    )

    if (Test-Path $DestinationFolder) {
        Remove-Item $DestinationFolder -Recurse -Force
    }

    $parent = Split-Path $DestinationFolder -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    robocopy $SourceFolder $DestinationFolder /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Failed to copy pack folder to $DestinationFolder"
    }
}

function New-AndroidManualZip {
    param(
        [string]$BehaviorPackFolder,
        [string]$ResourcePackFolder,
        [string]$DestinationPath
    )

    if (Test-Path $DestinationPath) {
        Remove-Item $DestinationPath -Force
    }

    $archive = [System.IO.Compression.ZipFile]::Open(
        $DestinationPath,
        [System.IO.Compression.ZipArchiveMode]::Create
    )

    try {
        foreach ($root in @(
                @{ Source = $BehaviorPackFolder; Prefix = "behavior_packs/ToolsPlusPlus_BP" }
                @{ Source = $ResourcePackFolder; Prefix = "resource_packs/ToolsPlusPlus_RP" }
            )) {
            $sourceFull = [System.IO.Path]::GetFullPath($root.Source)
            foreach ($file in Get-ChildItem $root.Source -Recurse -File) {
                $relative = $file.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
                $entryName = ($root.Prefix + "/" + ($relative -replace '\\', '/'))
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $archive,
                    $file.FullName,
                    $entryName,
                    [System.IO.Compression.CompressionLevel]::Optimal
                ) | Out-Null
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Write-AndroidInstallNotes {
    param([string]$ManualRoot)

    Write-Host ""
    Write-Host "Android manual install (when Minecraft is not in Open with):" -ForegroundColor White
    Write-Host "  1. Copy this folder to the phone over USB:" -ForegroundColor DarkGray
    Write-Host "     $ManualRoot" -ForegroundColor Gray
    Write-Host "  2. Install ZArchiver (Play Store). Open:" -ForegroundColor DarkGray
    Write-Host "     Android/data/com.mojang.minecraftpe/files/games/com.mojang" -ForegroundColor Gray
    Write-Host "  3. Copy android_manual\\behavior_packs\\ToolsPlusPlus_BP -> ...\\behavior_packs\\" -ForegroundColor DarkGray
    Write-Host "     Copy android_manual\\resource_packs\\ToolsPlusPlus_RP -> ...\\resource_packs\\" -ForegroundColor DarkGray
    Write-Host "  4. Or extract ToolsPlusPlus_android.zip directly into that com.mojang folder." -ForegroundColor DarkGray
    Write-Host "  5. Open Minecraft > Edit world > activate Tools++ Behavior Pack." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "If Android/data is blocked, use ZArchiver with Shizuku, or try /storage/emulated/0/games/com.mojang on older phones." -ForegroundColor DarkYellow
    Write-Host "Confirm the app is Minecraft from Play Store (not Java Edition)." -ForegroundColor DarkYellow
}

function New-Mcaddon {
    param(
        [string[]]$McpackPaths,
        [string]$DestinationPath
    )

    $parent = Split-Path $DestinationPath -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $DestinationPath) {
        Remove-Item $DestinationPath -Force
    }

    $archive = [System.IO.Compression.ZipFile]::Open(
        $DestinationPath,
        [System.IO.Compression.ZipArchiveMode]::Create
    )

    try {
        foreach ($mcpackPath in $McpackPaths) {
            $entryName = Split-Path $mcpackPath -Leaf
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $mcpackPath,
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
            Write-BuildItem -Label "Added" -Value $entryName -Color DarkCyan
        }
    }
    finally {
        $archive.Dispose()
    }
}

Write-Host ""
Write-BuildHeading "Validating Tools++ packs..."
& (Join-Path $PSScriptRoot "validate.ps1")

$version = Get-PackVersionLabel -ManifestPath (Join-Path $BpSource "manifest.json")
$buildRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("toolsplusplus-mcaddon-" + [guid]::NewGuid().ToString("N"))
$bpMcpack = Join-Path $buildRoot "ToolsPlusPlus_BP.mcpack"
$rpMcpack = Join-Path $buildRoot "ToolsPlusPlus_RP.mcpack"
$mcaddonName = "ToolsPlusPlus_v$version.mcaddon"
$mcaddonPath = Join-Path $OutputDir $mcaddonName

try {
    New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    Write-Host ""
    Write-BuildHeading "Building pack archives..."
    Write-BuildItem -Label "Version" -Value $version -Color Gray
    Write-BuildItem -Label "Output" -Value $OutputDir -Color Gray

    New-PackZipArchive -SourceFolder $BpSource -DestinationPath $bpMcpack
    Write-BuildItem -Label "Packed" -Value "ToolsPlusPlus_BP.mcpack"

    New-PackZipArchive -SourceFolder $RpSource -DestinationPath $rpMcpack
    Write-BuildItem -Label "Packed" -Value "ToolsPlusPlus_RP.mcpack"

    Write-Host ""
    Write-BuildHeading "Building .mcaddon..."
    New-Mcaddon -McpackPaths @($bpMcpack, $rpMcpack) -DestinationPath $mcaddonPath

    $distBpMcpack = Join-Path $OutputDir "ToolsPlusPlus_BP.mcpack"
    $distRpMcpack = Join-Path $OutputDir "ToolsPlusPlus_RP.mcpack"
    $distBpZip = Join-Path $OutputDir "ToolsPlusPlus_BP.zip"
    $distRpZip = Join-Path $OutputDir "ToolsPlusPlus_RP.zip"
    Copy-Item $bpMcpack $distBpMcpack -Force
    Copy-Item $rpMcpack $distRpMcpack -Force
    Copy-Item $bpMcpack $distBpZip -Force
    Copy-Item $rpMcpack $distRpZip -Force
    Write-BuildItem -Label "Copied" -Value "ToolsPlusPlus_BP.mcpack" -Color DarkCyan
    Write-BuildItem -Label "Copied" -Value "ToolsPlusPlus_RP.mcpack" -Color DarkCyan
    Write-BuildItem -Label "Copied" -Value "ToolsPlusPlus_BP.zip" -Color DarkCyan
    Write-BuildItem -Label "Copied" -Value "ToolsPlusPlus_RP.zip" -Color DarkCyan

    Write-Host ""
    Write-BuildHeading "Building Android manual bundle..."
    $androidRoot = Join-Path $OutputDir "android_manual"
    $androidBp = Join-Path $androidRoot "behavior_packs\ToolsPlusPlus_BP"
    $androidRp = Join-Path $androidRoot "resource_packs\ToolsPlusPlus_RP"
    Copy-PackFolder -SourceFolder $BpSource -DestinationFolder $androidBp
    Copy-PackFolder -SourceFolder $RpSource -DestinationFolder $androidRp
    Write-BuildItem -Label "Created" -Value "android_manual\behavior_packs\ToolsPlusPlus_BP"
    Write-BuildItem -Label "Created" -Value "android_manual\resource_packs\ToolsPlusPlus_RP"

    $androidZip = Join-Path $OutputDir "ToolsPlusPlus_android.zip"
    New-AndroidManualZip -BehaviorPackFolder $androidBp -ResourcePackFolder $androidRp -DestinationPath $androidZip
    Write-BuildItem -Label "Created" -Value "ToolsPlusPlus_android.zip" -Color Green

    $sizeKb = [math]::Round((Get-Item $mcaddonPath).Length / 1KB, 1)
    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
    Write-BuildItem -Label "Created" -Value $mcaddonPath -Color Green
    Write-BuildItem -Label "Size" -Value "$sizeKb KB" -Color Gray
    Write-Host ""
    Write-Host "Install:" -ForegroundColor White
    Write-Host "  Windows - double-click the .mcaddon, or Settings > Global Resources in Minecraft." -ForegroundColor DarkGray
    Write-AndroidInstallNotes -ManualRoot (Join-Path $OutputDir "android_manual")
    Write-Host ""
    Write-Host "Note: For local PC dev, prefer install.ps1 to avoid duplicate imported packs." -ForegroundColor DarkYellow
    Write-Host "      Before importing this .mcaddon, run clean-packs.ps1 with Minecraft closed." -ForegroundColor DarkYellow
}
finally {
    if (Test-Path $buildRoot) {
        Remove-Item $buildRoot -Recurse -Force
    }
}
