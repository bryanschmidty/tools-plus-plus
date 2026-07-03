---
name: minecraft-bedrock-addon
description: Defines Minecraft Bedrock behavior/resource pack JSON for Tools++ — manifests, custom items, recipes, and lang files. Use when editing manifest.json, items/*.json, recipes/*.json, or en_US.lang. Do not use for textures or install paths.
---

# Minecraft Bedrock Addon JSON (Tools++)

## Related skills

- Textures and PNGs → **minecraft-bedrock-textures**
- Installing to Minecraft on Windows → **minecraft-bedrock-install**

## Project layout

```
behavior_packs/ToolsPlusPlus_BP/
  manifest.json
  items/
  recipes/
resource_packs/ToolsPlusPlus_RP/
  manifest.json
  textures/item_texture.json
  textures/toolsplusplus/items/*.png
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
    "version": [1, 0, 4]
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
- Use `"format_version": "1.20.10"` for shaped recipes

## Localization (RP)

`resource_packs/ToolsPlusPlus_RP/texts/en_US.lang`:

```
item.toolsplusplus:ruby=Ruby
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
