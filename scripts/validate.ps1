# Validates Tools++ addon pack structure and JSON.

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

$RequiredPaths = @(
    "behavior_packs\ToolsPlusPlus_BP\manifest.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby.json",
    "resource_packs\ToolsPlusPlus_RP\manifest.json",
    "resource_packs\ToolsPlusPlus_RP\textures\item_texture.json",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby.png",
    "resource_packs\ToolsPlusPlus_RP\texts\en_US.lang",
    "resource_packs\ToolsPlusPlus_RP\texts\languages.json"
)

function Test-JsonFile {
    param([string]$Path)
    Get-Content $Path -Raw | ConvertFrom-Json | Out-Null
}

function Test-ItemTextureJson {
    param([string]$Path)
    $json = Get-Content $Path -Raw | ConvertFrom-Json

    if ($json.texture_name -eq "atlas.terrain") {
        throw "item_texture.json must never use atlas.terrain"
    }

    if ($json.texture_name -and $json.texture_name -ne "atlas.items") {
        throw "item_texture.json texture_name must be atlas.items when present, not '$($json.texture_name)'"
    }

    if (-not $json.texture_data) {
        throw "item_texture.json must define texture_data"
    }

    if (-not $json.texture_data.'toolsplusplus:ruby') {
        throw "item_texture.json must define shortname 'toolsplusplus:ruby'"
    }
}

function Test-ResourcePackScope {
    $rpRoot = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"
    $forbidden = @(
        "textures\terrain_texture.json",
        "blocks.json",
        "textures\flipbook_textures.json"
    )

    foreach ($relativePath in $forbidden) {
        if (Test-Path (Join-Path $rpRoot $relativePath)) {
            throw "Resource pack must not include $relativePath for item-only phase 1 content"
        }
    }
}

function Test-ManifestPair {
    $bp = Get-Content (Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP\manifest.json") -Raw | ConvertFrom-Json
    $rp = Get-Content (Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP\manifest.json") -Raw | ConvertFrom-Json

    $bpDep = $bp.dependencies | Where-Object { $_.uuid -eq $rp.header.uuid }
    if (-not $bpDep) {
        throw "Behavior pack manifest must depend on the resource pack UUID"
    }

    if ($rp.dependencies) {
        throw "Resource pack manifest must not depend on the behavior pack; dependency belongs in the BP manifest"
    }
}

Write-Host "Checking required files..."
foreach ($relativePath in $RequiredPaths) {
    $fullPath = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path $fullPath)) {
        throw "Missing required file: $relativePath"
    }
}

Write-Host "Parsing JSON files..."
Get-ChildItem -Path $RepoRoot -Recurse -Filter *.json -File |
    Where-Object { $_.FullName -notmatch '\\\.git\\' } |
    ForEach-Object { Test-JsonFile $_.FullName }

Write-Host "Checking item_texture.json rules..."
Test-ItemTextureJson (Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP\textures\item_texture.json")

Write-Host "Checking resource pack scope..."
Test-ResourcePackScope

Write-Host "Checking manifest dependency direction..."
Test-ManifestPair

Write-Host "Checking item textures..."
& (Join-Path $PSScriptRoot "validate-textures.ps1")

Write-Host "Validation passed."
