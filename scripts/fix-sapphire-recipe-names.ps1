$recipeDir = "C:\Users\Bryan Schmidt\tools-plus-plus\behavior_packs\ToolsPlusPlus_BP\recipes"
Get-ChildItem -Path $recipeDir -Filter "sapphire_*_from_rubies.json" | ForEach-Object {
    $newName = $_.Name -replace "_from_rubies", "_from_sapphires"
    Rename-Item -LiteralPath $_.FullName -NewName $newName
    Write-Host "Renamed to $newName"
}

$deepslateSrc = "C:\Users\Bryan Schmidt\tools-plus-plus\resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\blocks\deepslate_ruby_ore.png"
$deepslateDest = "C:\Users\Bryan Schmidt\tools-plus-plus\resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\blocks\deepslate_sapphire_ore.png"
if (-not (Test-Path $deepslateDest)) {
    & "C:\Users\Bryan Schmidt\tools-plus-plus\scripts\recolor-ruby-to-sapphire.ps1" -InputPaths $deepslateSrc
}
