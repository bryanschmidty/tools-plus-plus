---
name: minecraft-bedrock-textures
description: Validates and prepares Minecraft Bedrock item PNG textures and item_texture.json for Tools++. Use when adding item icons, fixing PNG alpha/format, item_texture.json, magenta inventory icons, or atlas corruption. Do not use for install paths or manifest JSON.
---

# Minecraft Bedrock Textures (Tools++)

## Related skills

- Pack JSON (manifests, items, recipes) → **minecraft-bedrock-addon**
- Installing packs into Minecraft → **minecraft-bedrock-install**

## Scope

Phase 1 adds **custom item icons only**. Do not add `terrain_texture.json`, `blocks.json`, or block textures unless explicitly requested.

## item_texture.json

Path: `resource_packs/ToolsPlusPlus_RP/textures/item_texture.json`

Use the **merge format** — only your entries under `texture_data`:

```json
{
  "texture_data": {
    "toolsplusplus:ruby": {
      "textures": "textures/toolsplusplus/items/ruby"
    }
  }
}
```

### Critical: never use atlas.terrain

```json
{
  "texture_name": "atlas.terrain",
  "texture_data": { ... }
}
```

`atlas.terrain` is the **block** atlas. Item entries there corrupt inventory icons and can break world rendering (magenta squares, wrong block textures).

### Allowed optional fields

- `resource_pack_name` — cosmetic
- `"texture_name": "atlas.items"` — optional; merge examples often omit it

### Never

- Copy the full vanilla `item_texture.json`
- Put `.png` in the `textures` path string

## PNG requirements

| Requirement | Value |
|-------------|-------|
| Format | PNG |
| Size | 16×16 pixels |
| Color depth | 32-bit RGBA |
| Background | Transparent outside the icon |
| File path | Lowercase, `textures/<namespace>/items/<id>.png` |

## Three-way link (must all match)

1. File: `textures/toolsplusplus/items/ruby.png`
2. `item_texture.json` key: `"toolsplusplus:ruby"`
3. BP item: `"minecraft:icon": "toolsplusplus:ruby"`

## Scripts

### Validate textures only

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-textures.ps1
```

Checks: PNG signature, 16×16, RGBA, file exists for each `texture_data` entry.

### Fix textures in place

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/fix-item-texture.ps1 -All
```

Fix one file in place:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/fix-item-texture.ps1 `
  -OutputPath ./resource_packs/ToolsPlusPlus_RP/textures/toolsplusplus/items/ruby.png
```

Import external art:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/fix-item-texture.ps1 `
  -InputPath ./my-art.png `
  -OutputPath ./resource_packs/ToolsPlusPlus_RP/textures/toolsplusplus/items/ruby.png `
  -RemoveWhiteBackground
```

The fix script **preserves alpha** from the source PNG. It does not force opaque pixels.

### Full validation

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate.ps1
```

Then install — see **minecraft-bedrock-install** skill.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Magenta/black inventory icons | `atlas.terrain` or bad merge | Use `texture_data` only; never `atlas.terrain` |
| World blocks show item icons | Severe atlas corruption | Fix JSON, reinstall, new world |
| Transparent pixels become black | Old fix script forced alpha=255 | Re-run current `fix-item-texture.ps1` |
| Custom item invisible | Shortname/path mismatch | Align PNG path, texture_data key, minecraft:icon |
| "No transparent pixels" note | Full-bleed 16×16 icon | Valid; optional `-RemoveWhiteBackground` for white backdrop art |

## New item texture checklist

```
- [ ] PNG 16×16 RGBA (or run fix-item-texture.ps1)
- [ ] Saved under textures/toolsplusplus/items/<id>.png
- [ ] Shortname added to item_texture.json
- [ ] minecraft:icon set in BP item JSON
- [ ] validate-textures.ps1 passes
- [ ] install.ps1 run (install skill)
```

## References

- [Bedrock Wiki: Custom Item](https://wiki.bedrock.dev/guide/custom-item)
- [Bedrock Wiki: Texture Atlases](https://wiki.bedrock.dev/concepts/texture-atlases)
- [Bedrock Wiki: Overwriting Assets](https://wiki.bedrock.dev/concepts/overwriting-assets)
