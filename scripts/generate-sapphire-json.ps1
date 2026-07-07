# Generates sapphire behavior/resource JSON by cloning ruby files with identifier replacements.

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BpRoot = Join-Path $RepoRoot "behavior_packs\ToolsPlusPlus_BP"
$RpRoot = Join-Path $RepoRoot "resource_packs\ToolsPlusPlus_RP"

function Convert-RubyToSapphireContent {
    param([string]$Content)

    $Content = $Content.Replace("#993333", "#333399")
    $Content = $Content.Replace("#662626", "#262666")
    $Content = $Content.Replace("#CC2222", "#2222CC")

    $pairs = @(
        @("deepslate_ruby_ore", "deepslate_sapphire_ore"),
        @("raw_ruby_chunk", "raw_sapphire_chunk"),
        @("ruby_chunk", "sapphire_chunk"),
        @("ruby_shard", "sapphire_shard"),
        @("ruby_block", "sapphire_block"),
        @("ruby_ore", "sapphire_ore"),
        @("toolsplusplus_ruby", "toolsplusplus_sapphire"),
        @("toolsplusplus:ruby_tier", "toolsplusplus:sapphire_tier"),
        @("toolsplusplus:ruby", "toolsplusplus:sapphire"),
        @("ruby_tier", "sapphire_tier"),
        @("from_rubies", "from_sapphires"),
        @("ruby_spear", "sapphire_spear"),
        @("ruby_sword", "sapphire_sword"),
        @("ruby_pickaxe", "sapphire_pickaxe"),
        @("ruby_shovel", "sapphire_shovel"),
        @("ruby_chestplate", "sapphire_chestplate"),
        @("ruby_leggings", "sapphire_leggings"),
        @("ruby_helmet", "sapphire_helmet"),
        @("ruby_boots", "sapphire_boots"),
        @("ruby_hoe", "sapphire_hoe"),
        @("ruby_axe", "sapphire_axe")
    )

    foreach ($pair in $pairs) {
        $Content = $Content.Replace($pair[0], $pair[1])
    }

    return $Content
}

$bpFiles = @(
    "blocks\ruby_ore.json",
    "blocks\deepslate_ruby_ore.json",
    "blocks\ruby_block.json",
    "items\ruby_ore.json",
    "items\deepslate_ruby_ore.json",
    "items\ruby_block.json",
    "items\raw_ruby_chunk.json",
    "items\ruby_chunk.json",
    "items\ruby.json",
    "items\ruby_shard.json",
    "items\ruby_pickaxe.json",
    "items\ruby_axe.json",
    "items\ruby_shovel.json",
    "items\ruby_hoe.json",
    "items\ruby_sword.json",
    "items\ruby_spear.json",
    "items\ruby_helmet.json",
    "items\ruby_chestplate.json",
    "items\ruby_leggings.json",
    "items\ruby_boots.json",
    "loot_tables\blocks\ruby_ore.json",
    "loot_tables\blocks\deepslate_ruby_ore.json",
    "loot_tables\blocks\ruby_block.json",
    "recipes\ruby_chunk_from_smelting.json",
    "recipes\ruby_from_ruby_chunk_stonecutting.json",
    "recipes\ruby_shard_from_ruby_stonecutting.json",
    "recipes\ruby_block_from_ruby_chunks.json",
    "recipes\ruby_chunks_from_ruby_block.json",
    "recipes\ruby_pickaxe_from_rubies.json",
    "recipes\ruby_axe_from_rubies.json",
    "recipes\ruby_shovel_from_rubies.json",
    "recipes\ruby_hoe_from_rubies.json",
    "recipes\ruby_sword_from_rubies.json",
    "recipes\ruby_spear_from_rubies.json",
    "recipes\ruby_helmet_from_rubies.json",
    "recipes\ruby_chestplate_from_rubies.json",
    "recipes\ruby_leggings_from_rubies.json",
    "recipes\ruby_boots_from_rubies.json",
    "features\ruby_ore_feature.json",
    "feature_rules\ruby_ore_overworld.json"
)

foreach ($rel in $bpFiles) {
    $src = Join-Path $BpRoot $rel
    $destRel = $rel -replace "ruby", "sapphire"
    $dest = Join-Path $BpRoot $destRel
    $content = Convert-RubyToSapphireContent (Get-Content -Raw -LiteralPath $src)
    [System.IO.File]::WriteAllText($dest, $content)
    Write-Host "Created $destRel"
}

$attachables = @("ruby_helmet", "ruby_chestplate", "ruby_leggings", "ruby_boots", "ruby_spear")
foreach ($name in $attachables) {
    $src = Join-Path $RpRoot "attachables\$name.json"
    $destName = $name -replace "ruby", "sapphire"
    $dest = Join-Path $RpRoot "attachables\$destName.json"
    $content = Convert-RubyToSapphireContent (Get-Content -Raw -LiteralPath $src)
    $content = $content.Replace("models/armor/ruby_1", "models/armor/sapphire_1")
    $content = $content.Replace("models/armor/ruby_2", "models/armor/sapphire_2")
    $content = $content.Replace("entity/spear/ruby_spear", "entity/spear/sapphire_spear")
    [System.IO.File]::WriteAllText($dest, $content)
    Write-Host "Created attachables\$destName.json"
}

$rulePath = Join-Path $BpRoot "feature_rules\sapphire_ore_overworld.json"
$ruleContent = Get-Content -Raw -LiteralPath $rulePath
$ruleContent = $ruleContent -replace '"extent":\s*\[\s*0,\s*62\s*\]', '"extent": [32, 96]'
[System.IO.File]::WriteAllText($rulePath, $ruleContent)
Write-Host "Updated sapphire_ore_overworld Y extent to 32-96"
