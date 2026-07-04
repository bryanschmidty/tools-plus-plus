# Removes all Tools++ pack copies from every Minecraft Bedrock data root.
# Use before importing a .mcaddon to avoid duplicate UUID errors.

param(
    [switch]$ListOnly
)

$ErrorActionPreference = "Stop"

$PackUuids = @{
    Behavior = "48c0a12f-2012-4b7d-be80-2ff0eef48154"
    Resource = "eea31dcf-46f3-4013-808d-e457953cd5af"
}

$KnownFolderNames = @(
    "ToolsPlusPlus_BP",
    "ToolsPlusPlus_RP",
    "Tools++Beh",
    "Tools++Res"
)

function Write-CleanHeading {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Cyan
}

function Write-CleanItem {
    param(
        [string]$Label,
        [string]$Value,
        [ConsoleColor]$Color = 'Green'
    )
    Write-Host ("  {0,-10} {1}" -f "${Label}:", $Value) -ForegroundColor $Color
}

function Get-MinecraftRoots {
    $candidates = @(
        (Join-Path $env:APPDATA "Minecraft Bedrock\users\shared\games\com.mojang")
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.MinecraftUWP_8wekyb3d8bbwe\LocalState\games\com.mojang")
    )

    $roots = @()
    foreach ($candidate in $candidates) {
        if (Test-Path (Split-Path $candidate -Parent)) {
            $roots += $candidate
        }
    }

    if ($roots.Count -eq 0) {
        throw "No Minecraft Bedrock data folder found."
    }

    return ($roots | Select-Object -Unique)
}

function Test-MinecraftRunning {
    return $null -ne (Get-Process -Name "Minecraft.Windows" -ErrorAction SilentlyContinue)
}

function Get-RelativePackPath {
    param(
        [string]$MinecraftRoot,
        [string]$FullPath
    )

    $root = [System.IO.Path]::GetFullPath($MinecraftRoot).TrimEnd('\')
    $full = [System.IO.Path]::GetFullPath($FullPath)
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart('\')
    }

    return (Split-Path $FullPath -Leaf)
}

function Get-ToolsPlusPlusInstalls {
    param([string]$MinecraftRoot)

    $found = @()

    foreach ($rootName in @(
            "behavior_packs",
            "resource_packs",
            "development_behavior_packs",
            "development_resource_packs"
        )) {
        $root = Join-Path $MinecraftRoot $rootName
        if (-not (Test-Path $root)) {
            continue
        }

        foreach ($entry in Get-ChildItem $root -Directory -Force -ErrorAction SilentlyContinue) {
            $manifestPath = Join-Path $entry.FullName "manifest.json"
            $match = $entry.Name -in $KnownFolderNames
            $uuid = $null

            if (-not $match -and (Test-Path $manifestPath)) {
                try {
                    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                    $uuid = [string]$manifest.header.uuid
                    if ($uuid -in $PackUuids.Values) {
                        $match = $true
                    }
                }
                catch {
                    continue
                }
            }
            elseif (Test-Path $manifestPath) {
                try {
                    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                    $uuid = [string]$manifest.header.uuid
                }
                catch {
                }
            }

            if ($match) {
                $found += [pscustomobject]@{
                    Root         = $MinecraftRoot
                    RelativePath = Get-RelativePackPath -MinecraftRoot $MinecraftRoot -FullPath $entry.FullName
                    FullPath     = $entry.FullName
                    Uuid         = $uuid
                }
            }
        }
    }

    return $found
}

function Remove-ToolsPlusPlusInstalls {
    param([string]$MinecraftRoot)

    foreach ($install in Get-ToolsPlusPlusInstalls -MinecraftRoot $MinecraftRoot) {
        Remove-Item $install.FullPath -Recurse -Force
        Write-CleanItem -Label "Removed" -Value $install.RelativePath -Color DarkYellow
    }
}

if (-not $ListOnly -and (Test-MinecraftRunning)) {
    Write-Warning "Close Minecraft completely, then run this script again."
    exit 1
}

$roots = Get-MinecraftRoots
$allInstalls = @()
foreach ($root in $roots) {
    $allInstalls += Get-ToolsPlusPlusInstalls -MinecraftRoot $root
}

Write-Host ""
Write-CleanHeading "Minecraft data roots:"
foreach ($root in $roots) {
    Write-Host "  $root" -ForegroundColor Gray
}

Write-Host ""
if ($allInstalls.Count -eq 0) {
    Write-Host "No Tools++ pack copies found." -ForegroundColor Green
    Write-Host ""
    Write-Host "You can import the .mcaddon now." -ForegroundColor White
    exit 0
}

Write-CleanHeading "Tools++ copies found:"
foreach ($install in $allInstalls) {
    $label = if ($install.Uuid) { "$($install.RelativePath) [$($install.Uuid)]" } else { $install.RelativePath }
    Write-CleanItem -Label "Found" -Value $label -Color Yellow
}

if ($ListOnly) {
    Write-Host ""
    Write-Host "List-only mode. Re-run without -ListOnly to remove these copies." -ForegroundColor DarkGray
    exit 0
}

Write-Host ""
Write-CleanHeading "Removing Tools++ copies..."
foreach ($root in $roots) {
    Write-Host "  $root" -ForegroundColor Gray
    Remove-ToolsPlusPlusInstalls -MinecraftRoot $root
}

$remaining = @()
foreach ($root in $roots) {
    $remaining += Get-ToolsPlusPlusInstalls -MinecraftRoot $root
}

Write-Host ""
if ($remaining.Count -eq 0) {
    Write-Host "Done. All Tools++ copies removed." -ForegroundColor Green
}
else {
    Write-Warning "Some copies could not be removed:"
    foreach ($install in $remaining) {
        Write-CleanItem -Label "Remaining" -Value $install.RelativePath -Color Red
    }
    exit 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Open Minecraft." -ForegroundColor DarkGray
Write-Host "  2. Edit worlds that used Tools++ and remove the packs from each world." -ForegroundColor DarkGray
Write-Host "  3. Import dist\\ToolsPlusPlus_v*.mcaddon, or run install.ps1 for local dev." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Important: Modern Bedrock uses the GDK path, not only UWP:" -ForegroundColor DarkYellow
Write-Host "  $env:APPDATA\Minecraft Bedrock\users\shared\games\com.mojang" -ForegroundColor DarkGray
