---
name: minecraft-bedrock-blocks
description: Creates Minecraft Bedrock custom blocks for Tools++ — block JSON, block-placer items, terrain_texture.json, blocks.json, loot tables, and creative inventory placement. Use when adding blocks, fixing blocks not in creative, /give failures, flat 2D block icons, or placement issues. Do not use for item-only icons or install paths.
---

# Minecraft Bedrock Blocks (Tools++)

## Related skills

- Item icons and PNGs → **minecraft-bedrock-textures**
- Recipes, manifests, lang → **minecraft-bedrock-addon**
- Installing packs → **minecraft-bedrock-install**

## Block registration: block + block-placer item

Custom blocks need **two behavior files** for `/give`, creative inventory, and placement:

| File | Purpose |
|------|---------|
| `blocks/<id>.json` | World block (`geometry`, `material_instances`, `item_visual`, loot) |
| `items/<id>.json` | Same identifier + `block_placer` + `replace_block_item: true` + `menu_category` |

Block-only registration (menu on block, no item file) does **not** reliably appear in `/give` autocomplete.

**Do not** put `menu_category` on both block and item — put it on the **item** when using `replace_block_item`.

### Inventory icon: 3D block, not flat sprite

- **Do not** add `minecraft:icon` on cube block items — that forces a flat 2D sprite
- Block JSON must include `minecraft:item_visual` + `terrain_texture.json` entry (`toolsplusplus_ruby_ore`)
- Use string geometry: `"minecraft:geometry": "minecraft:geometry.full_block"` (format **1.21.80+**)
- `blocks.json` in RP should be **sound only** — do not duplicate textures there; BP `material_instances` owns the look

## File checklist (full cube block)

```
behavior_packs/ToolsPlusPlus_BP/
  blocks/<id>.json              # minecraft:block + item_visual
  items/<id>.json               # block_placer item (same ID, menu_category here)
  loot_tables/blocks/<id>.json

resource_packs/ToolsPlusPlus_RP/
  textures/terrain_texture.json # texture_data shortname → block PNG path
  textures/toolsplusplus/blocks/<id>.png
  blocks.json                   # sound only; key = namespace:id
  texts/en_US.lang              # tile + item names
```

## Block JSON template (BP)

Path: `behavior_packs/ToolsPlusPlus_BP/blocks/ruby_ore.json`

```json
{
  "format_version": "1.21.80",
  "minecraft:block": {
    "description": {
      "identifier": "toolsplusplus:ruby_ore",
      "menu_category": {
        "category": "nature",
        "group": "minecraft:itemGroup.name.ore",
        "is_hidden_in_commands": false
      }
    },
    "components": {
      "minecraft:geometry": "minecraft:geometry.full_block",
      "minecraft:material_instances": {
        "*": {
          "texture": "toolsplusplus_ruby_ore",
          "render_method": "opaque"
        }
      },
      "minecraft:item_visual": {
        "geometry": "minecraft:geometry.full_block",
        "material_instances": {
          "*": {
            "texture": "toolsplusplus_ruby_ore",
            "render_method": "opaque"
          }
        }
      },
      "minecraft:collision_box": true,
      "minecraft:selection_box": true,
      "minecraft:destructible_by_mining": { "seconds_to_destroy": 3.0 },
      "minecraft:loot": "loot_tables/blocks/ruby_ore.json"
    }
  }
}
```

- Put **creative menu** on the **item** file (not the block) when using `replace_block_item`
- `blocks.json` needs `textures` + `carried_textures` pointing at the terrain shortname for inventory/hand fallback
- Enable **Upcoming Creator Features** in world experiments for 3D `item_visual` block icons (Settings → Experiments)

## Block-placer item template (required for /give)

Path: `behavior_packs/ToolsPlusPlus_BP/items/ruby_ore.json`

```json
{
  "format_version": "1.21.60",
  "minecraft:item": {
    "description": {
      "identifier": "toolsplusplus:ruby_ore",
      "menu_category": {
        "category": "nature",
        "group": "minecraft:itemGroup.name.ore",
        "is_hidden_in_commands": false
      }
    },
    "components": {
      "minecraft:max_stack_size": 64,
      "minecraft:block_placer": {
        "block": "toolsplusplus:ruby_ore",
        "replace_block_item": true,
        "aligned_placement": true
      }
    }
  }
}
```

- **No `minecraft:icon`** — block_placer renders the 3D cube
- Item `format_version` must be **1.21.50+**

## Resource pack wiring (RP)

### terrain_texture.json (merge format only)

```json
{
  "texture_data": {
    "toolsplusplus_ruby_ore": {
      "textures": "textures/toolsplusplus/blocks/ruby_ore"
    }
  }
}
```

- Never use `atlas.items` here
- Texture shortname in `material_instances` must match this key

### blocks.json (sound only)

```json
{
  "format_version": "1.19.30",
  "toolsplusplus:ruby_ore": {
    "sound": "stone",
    "textures": "toolsplusplus_ruby_ore",
    "carried_textures": "toolsplusplus_ruby_ore"
  }
}
```

- Key is the **block identifier** (`namespace:id`), not the texture shortname

### Localization

```
item.toolsplusplus:ruby_ore=Ruby Ore
tile.toolsplusplus:ruby_ore.name=Ruby Ore
```

## Three-way link (must all match)

1. Block identifier: `toolsplusplus:ruby_ore`
2. Item identifier: `toolsplusplus:ruby_ore` (same)
3. Terrain texture key: `toolsplusplus_ruby_ore` (underscore — used in `material_instances` and `item_visual`)
4. PNG: `textures/toolsplusplus/blocks/ruby_ore.png`

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Not in creative or `/give` | Missing `items/<id>.json` with `block_placer` | Add block-placer item file |
| Flat 2D sprite in hand/inventory | `minecraft:icon` on block item | Remove icon; use block_placer 3D at format 1.21.50+ |
| Completely invisible in inventory | Broken terrain link | Fix `toolsplusplus_ruby_ore` in terrain_texture + item_visual on block |
| Magenta/black block in world | Bad `terrain_texture.json` or missing PNG | Fix terrain atlas entry + PNG path |
| Dirt block with `?` | Block JSON failed to load | Check content log; validate JSON |
| Can't place | Missing or broken `block_placer` | Fix item JSON; verify block loads |
| Wrong creative tab | `menu_category` on block only | Move `menu_category` to item file |

## Validation and install

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/install.ps1
```

Close Minecraft before install. Re-activate packs and `/reload all` in-world.

## Test commands

```
/give @s toolsplusplus:ruby_ore
/place feature toolsplusplus:ruby_ore_feature ~ ~ ~
```

## References

- [Bedrock Wiki: Blocks intro](https://wiki.bedrock.dev/blocks/blocks-intro)
- [Bedrock Wiki: Blocks as items](https://wiki.bedrock.dev/blocks/blocks-as-items)
- [Microsoft: Customizing the item for a block](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/blockreference/examples/customizingitemforablock)
