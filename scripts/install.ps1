# Copies Tools++ packs into Minecraft Bedrock and removes stale duplicates.

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BpSource = Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP"
$RpSource = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"

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

function Remove-ToolsPlusPlusInstalls {
    param([string]$MinecraftRoot)

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
            $remove = $entry.Name -in $KnownFolderNames

            if (-not $remove -and (Test-Path $manifestPath)) {
                try {
                    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                    if ($manifest.header.uuid -in $PackUuids.Values) {
                        $remove = $true
                    }
                }
                catch {
                    continue
                }
            }

            if ($remove) {
                Remove-Item $entry.FullName -Recurse -Force
                Write-Host "Removed: $($entry.FullName)"
            }
        }
    }
}

function Copy-Pack {
    param(
        [string]$Source,
        [string]$Target
    )

    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $Target) {
        Remove-Item $Target -Recurse -Force
    }

    robocopy $Source $Target /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Failed to copy pack to $Target"
    }

    Write-Host "Installed: $Target"
}

function Test-InstalledTexture {
    param(
        [string]$MinecraftRoot,
        [string]$RepoTexturePath
    )

    $relative = "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby.png"
    $installedPath = Join-Path $MinecraftRoot $relative
    if (-not (Test-Path $installedPath)) {
        throw "Installed texture missing: $installedPath"
    }

    $repoHash = (Get-FileHash $RepoTexturePath -Algorithm SHA256).Hash
    $installedHash = (Get-FileHash $installedPath -Algorithm SHA256).Hash
    if ($repoHash -ne $installedHash) {
        throw "Installed texture does not match repo: $installedPath"
    }

    Write-Host "Verified texture hash in: $installedPath"
}

if (Test-MinecraftRunning) {
    Write-Warning "Close Minecraft completely, then run this script again."
    exit 1
}

& (Join-Path $PSScriptRoot "validate.ps1")

$repoRuby = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby.png"
$roots = Get-MinecraftRoots

Write-Host ""
Write-Host "Minecraft data roots:"
foreach ($root in $roots) {
    Write-Host "  $root"
}

Write-Host ""
Write-Host "Cleaning old Tools++ installs..."
foreach ($root in $roots) {
    Remove-ToolsPlusPlusInstalls -MinecraftRoot $root
}

foreach ($root in $roots) {
    Write-Host ""
    Write-Host "Installing into: $root"

    $devBpTarget = Join-Path $root "development_behavior_packs\ToolsPlusPlus_BP"
    $devRpTarget = Join-Path $root "development_resource_packs\ToolsPlusPlus_RP"
    $bpTarget = Join-Path $root "behavior_packs\ToolsPlusPlus_BP"
    $rpTarget = Join-Path $root "resource_packs\ToolsPlusPlus_RP"

    Copy-Pack -Source $BpSource -Target $devBpTarget
    Copy-Pack -Source $RpSource -Target $devRpTarget
    Copy-Pack -Source $BpSource -Target $bpTarget
    Copy-Pack -Source $RpSource -Target $rpTarget

    Test-InstalledTexture -MinecraftRoot $root -RepoTexturePath $repoRuby
}

Write-Host ""
Write-Host "Done."
Write-Host "1. Open Minecraft."
Write-Host "2. Edit your world and REMOVE old Tools++ packs if still listed."
Write-Host "3. Activate Tools++ Behavior Pack (development or My Packs)."
Write-Host "4. Re-enter the world, or run /reload all in-game."
Write-Host ""
Write-Host "Note: Modern Bedrock uses:"
Write-Host "  $env:APPDATA\Minecraft Bedrock\users\shared\games\com.mojang"
