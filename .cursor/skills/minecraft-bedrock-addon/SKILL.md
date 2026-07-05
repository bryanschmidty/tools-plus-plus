---
name: minecraft-bedrock-addon
description: Defines Minecraft Bedrock behavior/resource pack JSON for Tools++ — manifests, custom items, recipes, and lang files. Use when editing manifest.json, items/*.json, recipes/*.json, or en_US.lang. Do not use for textures, install paths, or Script API (see minecraft-bedrock-scripts).
---

# Minecraft Bedrock Addon JSON (Tools++)

## Related skills

- **Custom blocks** (creative, placement, terrain textures) → **minecraft-bedrock-blocks**
- **Script API** (main.js, XP, tool durability) → **minecraft-bedrock-scripts**
- Textures and PNGs → **minecraft-bedrock-textures**
- Installing to Minecraft on Windows → **minecraft-bedrock-install**

## Project layout

```
behavior_packs/ToolsPlusPlus_BP/
  manifest.json
  items/
  blocks/
  recipes/
  loot_tables/blocks/
  features/
  feature_rules/
resource_packs/ToolsPlusPlus_RP/
  manifest.json
  blocks.json
  textures/item_texture.json
  textures/terrain_texture.json
  textures/toolsplusplus/items/*.png
  textures/toolsplusplus/blocks/*.png
  texts/en_US.lang
  texts/languages.json
scripts/validate.ps1
scripts/install.ps1
```

## Manifest rules

**Behavior pack depends on resource pack — never the reverse.**

- Header UUID and module UUID must differ
- Bump `version` together in BP header, BP module, RP header, RP module, and BP dependency when content changes
- RP manifest must **not** include a BP dependency

```json
// BP manifest only
"dependencies": [
  {
    "uuid": "eea31dcf-46f3-4013-808d-e457953cd5af",
    "version": [1, 1, 0]
  }
]
```

Fixed UUIDs for this project:
- BP header: `48c0a12f-2012-4b7d-be80-2ff0eef48154`
- RP header: `eea31dcf-46f3-4013-808d-e457953cd5af`

## Custom item (BP)

Path: `behavior_packs/ToolsPlusPlus_BP/items/<id>.json`

```json
{
  "format_version": "1.21.30",
  "minecraft:item": {
    "description": {
      "identifier": "toolsplusplus:ruby",
      "menu_category": {
        "category": "items"
      }
    },
    "components": {
      "minecraft:icon": "toolsplusplus:ruby",
      "minecraft:max_stack_size": 64
    }
  }
}
```

- Identifier: lowercase `namespace:id`
- `minecraft:icon` must match a key in `item_texture.json` (see textures skill)

## Recipe (BP)

Path: `behavior_packs/ToolsPlusPlus_BP/recipes/<id>.json`

- Recipe `description.identifier` must be unique (not the same as the item id)
- Use `"format_version": "1.20.10"` for shaped recipes; include `"unlock"` with the ingredient item (required since 1.20.30 recipe unlocking)
- Furnace: `minecraft:recipe_furnace` with `"tags": ["furnace", "blast_furnace"]`
- Stonecutter: `minecraft:recipe_shapeless` with `"tags": ["stonecutter"]`, plus `"unlock"` (ingredient item) and `"priority": 0` — required since 1.20.30 recipe unlocking

## Custom block (BP)

See **minecraft-bedrock-blocks** for the full block + block-placer item workflow. Every block requires matching `blocks/<id>.json` and `items/<id>.json` with `minecraft:block_placer`.

## Script API (BP)

See **minecraft-bedrock-scripts**. Scripts run without Beta APIs — never instruct the user to enable that experiment for XP, smelting, or tool durability.

## Ore world generation (BP)

Requires **Creation of Custom Biomes** experiment enabled in world settings (not Beta APIs).

```
behavior_packs/ToolsPlusPlus_BP/features/<name>_feature.json     # minecraft:ore_feature
behavior_packs/ToolsPlusPlus_BP/feature_rules/<name>_overworld.json  # minecraft:feature_rules
```

- Feature filename must match identifier suffix
- `placement_pass`: `underground_pass`
- `minecraft:biome_filter`: `has_biome_tag` == `overworld`
- Ore appears only in newly generated chunks

## Localization (RP)

`resource_packs/ToolsPlusPlus_RP/texts/en_US.lang`:

```
item.toolsplusplus:ruby=Ruby
tile.toolsplusplus:ruby_ore=Ruby Ore
```

`texts/languages.json` must list `en_US`.

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate.ps1
```

## Do not

- Put RP dependency on the BP in the RP manifest
- Copy vanilla JSON wholesale into pack files
- Edit textures or install paths here — use the other skills

## Templates

See [reference.md](reference.md)

## Checklist

```
- [ ] BP manifest depends on RP UUID with matching version
- [ ] RP manifest has no dependencies
- [ ] Item identifier matches icon shortname namespace
- [ ] Recipe identifier is unique
- [ ] validate.ps1 passes
- [ ] install.ps1 run (see install skill)
```
