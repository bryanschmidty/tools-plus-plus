---
name: minecraft-bedrock-textures
description: Validates and prepares Minecraft Bedrock textures for Tools++ — item icons (item_texture.json), placeable block textures (terrain_texture.json, blocks.json), PNG rules, 3D vs 2D block inventory rendering, and atlas corruption fixes. Use when adding item icons, block textures, fixing invisible/magenta/flat block items, or atlas linking. Do not use for install paths or manifest JSON.
---

# Minecraft Bedrock Textures (Tools++)

## Related skills

- Block JSON, block_placer items, loot → **minecraft-bedrock-blocks**
- Pack JSON (manifests, recipes, lang) → **minecraft-bedrock-addon**
- Installing packs into Minecraft → **minecraft-bedrock-install**

## Scope

Custom **item icons** and **placeable block textures** for Tools++ (Bedrock only — not Java datapacks).

| Asset type | Atlas | JSON | PNG folder |
|------------|-------|------|------------|
| Items (ruby, chunks, shards) | **Item atlas** | `item_texture.json` | `textures/toolsplusplus/items/` |
| Blocks (ruby ore, etc.) | **Terrain atlas** | `terrain_texture.json` + `blocks.json` | `textures/toolsplusplus/blocks/` |

**Never cross the atlases:**

- Never use `atlas.terrain` in `item_texture.json`
- Never use `atlas.items` in `terrain_texture.json`
- Never register a cube block texture in `item_texture.json` unless you deliberately want a flat 2D inventory sprite

---

## Item icons (flat sprites)

### item_texture.json

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

### Item three-way link (must all match)

1. File: `textures/toolsplusplus/items/ruby.png`
2. `item_texture.json` key: `"toolsplusplus:ruby"` (colon namespace form)
3. BP item: `"minecraft:icon": "toolsplusplus:ruby"`

---

## Placeable blocks (3D cubes)

Placeable blocks use the **terrain atlas** for world rendering **and** for 3D inventory/hand rendering via `minecraft:item_visual` on the block. This is separate from item icons.

Full behavior-pack wiring (block JSON, block_placer item, loot) → **minecraft-bedrock-blocks**.

### What we learned (ruby ore)

1. **Two behavior files required** — a block alone does not reliably show in `/give` or creative. You need a matching `items/<id>.json` with `minecraft:block_placer` + `replace_block_item: true` (same identifier as the block).

2. **Do not use `minecraft:icon` on cube block items** — it forces a flat 2D sprite in hand/inventory/drops. Omit icon; let `block_placer` + `item_visual` render a 3D cube.

3. **Block PNGs live under `blocks/`, not `items/`** — ore textures belong in `textures/toolsplusplus/blocks/ruby_ore.png`, registered only in `terrain_texture.json`.

4. **Terrain shortname ≠ block identifier** — use an underscore shortname in atlases:
   - Block/item ID: `toolsplusplus:ruby_ore`
   - Terrain key: `toolsplusplus_ruby_ore` (referenced in BP `material_instances` and `item_visual`)

5. **`blocks.json` needs texture wiring** — not sound-only. Point `textures` and `carried_textures` at the terrain shortname for world + hand/inventory fallback:

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

Key = block identifier (`namespace:id`). Value = terrain shortname from `terrain_texture.json`.

6. **`minecraft:item_visual` on the block drives 3D inventory look** — it reads from the **terrain atlas**, not `item_texture.json`. Requires block `format_version` **at least `1.21.60`**; on current Bedrock clients (game **v26.x**), use **`1.26.30`** to match the engine.

7. **Bedrock version numbering** — game build **v26.32** is Bedrock, not Java. JSON `format_version` values like `1.26.30` map to that engine generation; old `1.21.x` formats may still load but can miss fixes (e.g. v26.30 fixed `material_instances` overriding `item_visual` when held).

8. **`menu_category` goes on the item file**, not the block, when using `replace_block_item`.

9. **Do not duplicate block textures into `item_texture.json`** for 3D cubes — that path is for flat icons only.

### terrain_texture.json (merge format only)

Path: `resource_packs/ToolsPlusPlus_RP/textures/terrain_texture.json`

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
- Never put `.png` in the path string
- The shortname must match BP `material_instances` / `item_visual` `"texture"` fields exactly

### Block four-way link (must all match)

1. Block + item identifier: `toolsplusplus:ruby_ore`
2. Terrain shortname: `toolsplusplus_ruby_ore`
3. PNG: `textures/toolsplusplus/blocks/ruby_ore.png`
4. `blocks.json` key: `toolsplusplus:ruby_ore` → `textures` / `carried_textures`: `toolsplusplus_ruby_ore`

BP block must wire the same shortname:

```json
"minecraft:material_instances": {
  "*": { "texture": "toolsplusplus_ruby_ore", "render_method": "opaque" }
},
"minecraft:item_visual": {
  "geometry": { "identifier": "minecraft:geometry.full_block" },
  "material_instances": {
    "*": { "texture": "toolsplusplus_ruby_ore", "render_method": "opaque" }
  }
}
```

### 3D vs 2D inventory appearance

| Approach | Inventory look | When to use |
|----------|----------------|-------------|
| No `minecraft:icon` + `block_placer` + `item_visual` | 3D rotatable cube | Ores, building blocks, cubes |
| `minecraft:icon` in `item_texture.json` | Flat 2D sprite | Flowers, cross models, custom item art |

If a cube block is **invisible** (empty slot, stack count visible): terrain link or `item_visual` format is broken — not missing PNG art. Fix atlas wiring and block format before adding a 2D icon fallback.

### Diagnose texture vs item pipeline

| Test | Pass | Fail means |
|------|------|------------|
| Place block in world | Correct ore/stone texture | Fix `terrain_texture.json`, PNG path, or block JSON load error |
| Punch block (mining particles) | Correct colored particles | Terrain atlas not linked (`destruction_particles` uses same shortname) |
| Inventory / hotbar | 3D cube visible | `item_visual` or `blocks.json` carried textures; check block `format_version` |
| `/give` autocomplete | `toolsplusplus:ruby_ore` listed | Missing block_placer item file (blocks skill) — not a texture issue |

Check **content log** (Settings → Creator) for `ruby_ore`, `item_visual`, or terrain shortname errors after `/reload all`.

---

## PNG requirements

| Requirement | Items | Blocks |
|-------------|-------|--------|
| Format | PNG | PNG |
| Size | 16×16 | 16×16 (full cube face) |
| Color depth | 32-bit RGBA | 32-bit RGBA (opaque cube faces OK) |
| Background | Transparent outside icon | Opaque OK for cube faces |
| Path | `textures/toolsplusplus/items/<id>.png` | `textures/toolsplusplus/blocks/<id>.png` |

Block ore textures do not need transparent pixels. Item gems usually do.

---

## Scripts

### Validate textures only

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-textures.ps1
```

Checks item PNGs referenced by `item_texture.json`. Block PNGs are checked by full `validate.ps1`.

### Fix item textures in place

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/fix-item-texture.ps1 -All
```

Fix one item file:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/fix-item-texture.ps1 `
  -OutputPath ./resource_packs/ToolsPlusPlus_RP/textures/toolsplusplus/items/ruby.png
```

Remove gray export backgrounds:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/fix-item-texture.ps1 `
  -OutputPath ./resource_packs/ToolsPlusPlus_RP/textures/toolsplusplus/items/raw_ruby_chunk.png `
  -RemoveGrayBackground
```

The fix script **preserves alpha** from the source PNG. Use it for **item** icons; block cube faces are usually already opaque 16×16 art.

### Full validation

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate.ps1
```

Then install — see **minecraft-bedrock-install** skill.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Magenta/black **item** icons | `atlas.terrain` in item_texture or bad merge | Use `texture_data` only; never `atlas.terrain` |
| World blocks show item icons | Severe item atlas corruption | Fix JSON, reinstall, new world |
| Transparent item pixels become black | Old fix script forced alpha=255 | Re-run current `fix-item-texture.ps1` |
| Custom **item** invisible | Shortname/path/icon mismatch | Align PNG, item_texture key, `minecraft:icon` |
| Custom **block** invisible in inventory | Broken terrain link or low block format | Fix terrain shortname + `item_visual`; bump block to `1.26.30` on v26 clients |
| Block flat 2D in hand | `minecraft:icon` on block item | Remove icon; use 3D `item_visual` path |
| Block missing from `/give` | No block_placer item | Add `items/<id>.json` — see blocks skill |
| Magenta/black **block** in world | Bad terrain_texture or missing PNG | Fix terrain atlas + `textures/toolsplusplus/blocks/` PNG |
| "No transparent pixels" on items | Full-bleed 16×16 icon | Valid; optional `-RemoveWhiteBackground` |

---

## Checklists

### New item texture

```
- [ ] PNG 16×16 RGBA (or run fix-item-texture.ps1)
- [ ] Saved under textures/toolsplusplus/items/<id>.png
- [ ] Shortname added to item_texture.json (colon form: toolsplusplus:<id>)
- [ ] minecraft:icon set in BP item JSON
- [ ] validate-textures.ps1 passes
- [ ] install.ps1 run (install skill)
```

### New placeable block texture

```
- [ ] PNG 16×16 under textures/toolsplusplus/blocks/<id>.png
- [ ] terrain_texture.json entry (underscore shortname: toolsplusplus_<id>)
- [ ] blocks.json: textures + carried_textures → same shortname
- [ ] BP block material_instances + item_visual use same shortname
- [ ] BP items/<id>.json with block_placer (no minecraft:icon for cubes)
- [ ] en_US.lang: item.<id> and tile.<id>.name
- [ ] Block format_version 1.26.30 on Bedrock v26.x clients
- [ ] validate.ps1 + install.ps1
- [ ] Test: place in world, mining particles, 3D inventory icon, /give autocomplete
```

---

## References

- [Bedrock Wiki: Custom Item](https://wiki.bedrock.dev/guide/custom-item)
- [Bedrock Wiki: Blocks intro](https://wiki.bedrock.dev/blocks/blocks-intro)
- [Bedrock Wiki: Blocks as items](https://wiki.bedrock.dev/blocks/blocks-as-items)
- [Bedrock Wiki: Texture Atlases](https://wiki.bedrock.dev/concepts/texture-atlases)
- [Microsoft: item_visual](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/blockreference/examples/blockcomponents/minecraftblock_item_visual)
- [Microsoft: Customizing the item for a block](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/blockreference/examples/customizingitemforablock)
