# Validates Tools++ addon pack structure and JSON.

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

$RequiredPaths = @(
    "behavior_packs\ToolsPlusPlus_BP\manifest.json",
    "behavior_packs\ToolsPlusPlus_BP\scripts\main.js",
    "behavior_packs\ToolsPlusPlus_BP\pack_icon.png",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby.json",
    "behavior_packs\ToolsPlusPlus_BP\items\raw_ruby_chunk.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_chunk.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_shard.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_ore.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_block.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_pickaxe.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_sword.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_spear.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_axe.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_hoe.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_shovel.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_helmet.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_chestplate.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_leggings.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_boots.json",
    "behavior_packs\ToolsPlusPlus_BP\items\ruby_arrow.json",
    "behavior_packs\ToolsPlusPlus_BP\items\deepslate_ruby_ore.json",
    "behavior_packs\ToolsPlusPlus_BP\entities\ruby_arrow.json",
    "behavior_packs\ToolsPlusPlus_BP\blocks\ruby_ore.json",
    "behavior_packs\ToolsPlusPlus_BP\blocks\deepslate_ruby_ore.json",
    "behavior_packs\ToolsPlusPlus_BP\blocks\ruby_block.json",
    "behavior_packs\ToolsPlusPlus_BP\loot_tables\blocks\ruby_ore.json",
    "behavior_packs\ToolsPlusPlus_BP\loot_tables\blocks\deepslate_ruby_ore.json",
    "behavior_packs\ToolsPlusPlus_BP\loot_tables\blocks\ruby_block.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_chunk_from_smelting.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_from_ruby_chunk_stonecutting.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_shard_from_ruby_stonecutting.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_block_from_ruby_chunks.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_chunks_from_ruby_block.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_pickaxe_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_sword_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_spear_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_axe_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_hoe_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_shovel_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_helmet_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_chestplate_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_leggings_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_boots_from_rubies.json",
    "behavior_packs\ToolsPlusPlus_BP\recipes\ruby_arrow_from_ruby_shard.json",
    "behavior_packs\ToolsPlusPlus_BP\features\ruby_ore_feature.json",
    "behavior_packs\ToolsPlusPlus_BP\feature_rules\ruby_ore_overworld.json",
    "resource_packs\ToolsPlusPlus_RP\manifest.json",
    "resource_packs\ToolsPlusPlus_RP\pack_icon.png",
    "resource_packs\ToolsPlusPlus_RP\textures\item_texture.json",
    "resource_packs\ToolsPlusPlus_RP\textures\terrain_texture.json",
    "resource_packs\ToolsPlusPlus_RP\blocks.json",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\raw_ruby_chunk.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_chunk.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_shard.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_pickaxe.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_sword.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_spear.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_axe.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_hoe.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_shovel.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_helmet.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_chestplate.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_leggings.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_boots.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby_arrow.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\models\armor\ruby_1.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\models\armor\ruby_2.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\blocks\ruby_ore.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\blocks\deepslate_ruby_ore.png",
    "resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\blocks\ruby_block.png",
    "resource_packs\ToolsPlusPlus_RP\textures\entity\spear\ruby_spear.png",
    "resource_packs\ToolsPlusPlus_RP\textures\entity\arrow\ruby_arrow.png",
    "resource_packs\ToolsPlusPlus_RP\entity\ruby_arrow.entity.json",
    "resource_packs\ToolsPlusPlus_RP\attachables\ruby_spear.json",
    "resource_packs\ToolsPlusPlus_RP\attachables\ruby_helmet.json",
    "resource_packs\ToolsPlusPlus_RP\attachables\ruby_chestplate.json",
    "resource_packs\ToolsPlusPlus_RP\attachables\ruby_leggings.json",
    "resource_packs\ToolsPlusPlus_RP\attachables\ruby_boots.json",
    "resource_packs\ToolsPlusPlus_RP\models\entity\spear.geo.json",
    "resource_packs\ToolsPlusPlus_RP\models\entity\ruby_arrow.geo.json",
    "resource_packs\ToolsPlusPlus_RP\animations\spear.animation.json",
    "resource_packs\ToolsPlusPlus_RP\animations\ruby_arrow.animation.json",
    "resource_packs\ToolsPlusPlus_RP\render_controllers\ruby_arrow.render_controllers.json",
    "resource_packs\ToolsPlusPlus_RP\animation_controllers\spear.animation_controllers.json",
    "resource_packs\ToolsPlusPlus_RP\texts\en_US.lang",
    "resource_packs\ToolsPlusPlus_RP\texts\languages.json"
)

$RequiredItemTextureShortnames = @(
    "toolsplusplus:ruby",
    "toolsplusplus:raw_ruby_chunk",
    "toolsplusplus:ruby_chunk",
    "toolsplusplus:ruby_shard",
    "toolsplusplus:ruby_pickaxe",
    "toolsplusplus:ruby_sword",
    "toolsplusplus:ruby_spear",
    "toolsplusplus:ruby_axe",
    "toolsplusplus:ruby_hoe",
    "toolsplusplus:ruby_shovel",
    "toolsplusplus:ruby_helmet",
    "toolsplusplus:ruby_chestplate",
    "toolsplusplus:ruby_leggings",
    "toolsplusplus:ruby_boots",
    "toolsplusplus:ruby_arrow"
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

    foreach ($shortname in $RequiredItemTextureShortnames) {
        if (-not $json.texture_data.$shortname) {
            throw "item_texture.json must define shortname '$shortname'"
        }
    }
}

function Test-TerrainTextureJson {
    param([string]$Path)
    $json = Get-Content $Path -Raw | ConvertFrom-Json

    if ($json.texture_name -eq "atlas.items") {
        throw "terrain_texture.json must never use atlas.items"
    }

    if (-not $json.texture_data) {
        throw "terrain_texture.json must define texture_data"
    }

    if (-not $json.texture_data.toolsplusplus_ruby_ore) {
        throw "terrain_texture.json must define toolsplusplus_ruby_ore"
    }

    if (-not $json.texture_data.toolsplusplus_ruby_block) {
        throw "terrain_texture.json must define toolsplusplus_ruby_block"
    }

    if (-not $json.texture_data.toolsplusplus_deepslate_ruby_ore) {
        throw "terrain_texture.json must define toolsplusplus_deepslate_ruby_ore"
    }
}

function Test-ResourcePackScope {
    $rpRoot = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"
    $required = @(
        "textures\terrain_texture.json",
        "blocks.json"
    )

    foreach ($relativePath in $required) {
        if (-not (Test-Path (Join-Path $rpRoot $relativePath))) {
            throw "Resource pack must include $relativePath for block content"
        }
    }
}

function Test-BlockRegistration {
    $bpRoot = Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP"
    $blockFiles = Get-ChildItem -Path (Join-Path $bpRoot "blocks") -Filter *.json -File -ErrorAction SilentlyContinue

    foreach ($blockFile in $blockFiles) {
        $blockJson = Get-Content $blockFile.FullName -Raw | ConvertFrom-Json
        $block = $blockJson.'minecraft:block'
        $blockId = $block.description.identifier
        if (-not $blockId) {
            throw "Block file missing identifier: $($blockFile.Name)"
        }

        $itemPath = Join-Path $bpRoot "items\$($blockFile.BaseName).json"
        $hasItem = Test-Path $itemPath
        $hasMenu = [bool]$block.description.menu_category
        $hasItemVisual = [bool]$block.components.'minecraft:item_visual'
        $hasGeometry = [bool]$block.components.'minecraft:geometry'
        $hasMaterials = [bool]$block.components.'minecraft:material_instances'

        if (-not $hasGeometry -or -not $hasMaterials) {
            throw "Block '$blockId' must define minecraft:geometry and minecraft:material_instances"
        }

        if (-not $hasItemVisual) {
            throw "Block '$blockId' must define minecraft:item_visual for 3D inventory rendering"
        }

        if ($blockId -match '_ore$' -and -not $block.components.'toolsplusplus:experience_reward') {
            throw "Ore block '$blockId' must define toolsplusplus:experience_reward for mining XP"
        }

        if ($hasItem) {
            $itemJson = Get-Content $itemPath -Raw | ConvertFrom-Json
            $itemId = $itemJson.'minecraft:item'.description.identifier
            if ($itemId -ne $blockId) {
                throw "Item identifier '$itemId' must match block identifier '$blockId'"
            }

            $placer = $itemJson.'minecraft:item'.components.'minecraft:block_placer'
            if (-not $placer) {
                throw "items/$($blockFile.BaseName).json must include minecraft:block_placer"
            }
            if ($placer.block -ne $blockId) {
                throw "block_placer.block must be '$blockId' in items/$($blockFile.BaseName).json"
            }
            if (-not $placer.replace_block_item) {
                throw "block_placer.replace_block_item must be true in items/$($blockFile.BaseName).json"
            }
            if ($itemJson.'minecraft:item'.components.'minecraft:icon') {
                throw "items/$($blockFile.BaseName).json must not use minecraft:icon on cube blocks"
            }
            if ($itemJson.format_version -lt "1.21.50") {
                throw "items/$($blockFile.BaseName).json format_version must be 1.21.50+ for 3D block_placer icons"
            }
        }
        elseif (-not $hasMenu) {
            throw "Block '$blockId' needs menu_category on the block or a matching block_placer item with menu_category"
        }
    }
}

function Test-PackIcons {
    Add-Type -AssemblyName System.Drawing

    $iconPaths = @(
        (Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP\pack_icon.png"),
        (Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP\pack_icon.png")
    )

    foreach ($iconPath in $iconPaths) {
        if (-not (Test-Path $iconPath)) {
            throw "Missing pack icon: $iconPath"
        }

        $bytes = Get-Content -Path $iconPath -Encoding Byte -TotalCount 8
        $signature = [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
        for ($i = 0; $i -lt 8; $i++) {
            if ($bytes[$i] -ne $signature[$i]) {
                throw "Pack icon is not a valid PNG: $iconPath"
            }
        }

        $image = [System.Drawing.Image]::FromFile($iconPath)
        try {
            if ($image.Width -ne $image.Height) {
                Write-Warning "Pack icon should be square: $iconPath ($($image.Width)x$($image.Height))"
            }
            if ($image.Width -ne 256 -or $image.Height -ne 256) {
                Write-Warning "Pack icon should be 256x256 for best display: $iconPath ($($image.Width)x$($image.Height))"
            }
            else {
                Write-Host "OK: $iconPath (256x256 PNG)"
            }
        }
        finally {
            $image.Dispose()
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

Write-Host "Checking terrain_texture.json rules..."
Test-TerrainTextureJson (Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP\textures\terrain_texture.json")

Write-Host "Checking resource pack scope..."
Test-ResourcePackScope

Write-Host "Checking block registration..."
Test-BlockRegistration

Write-Host "Checking pack icons..."
Test-PackIcons

Write-Host "Checking manifest dependency direction..."
Test-ManifestPair

Write-Host "Checking item textures..."
& (Join-Path $PSScriptRoot "validate-textures.ps1")

Write-Host "Validation passed."
