---
name: minecraft-bedrock-scripts
description: Tools++ Bedrock Script API — main.js, custom block/item components, XP rewards, tool durability, manifest script module. Use when editing behavior_packs/ToolsPlusPlus_BP/scripts/, @minecraft/server code, or explaining world experiment requirements for scripts.
---

# Minecraft Bedrock Scripts (Tools++)

## Related skills

- Pack JSON and items → **minecraft-bedrock-addon**
- Installing and testing → **minecraft-bedrock-install**

## Script module

```
behavior_packs/ToolsPlusPlus_BP/
  manifest.json          # script module + @minecraft/server dependency
  scripts/main.js        # entry point
```

Manifest includes a `type: "script"` module with `"entry": "scripts/main.js"` and:

```json
{
  "module_name": "@minecraft/server",
  "version": "2.7.0"
}
```

## Beta APIs — not required

**Do not tell the user to enable Beta APIs or any experimental script toggle for Tools++ scripts.**

XP rewards, furnace smelt tracking, and digger tool durability all work with the behavior pack activated on a normal world. No Beta APIs experiment is needed for `@minecraft/server` in this project.

## World experiments (separate from scripts)

These are unrelated to the script module. Only mention them when relevant:

| Experiment | Needed for |
|------------|------------|
| **Creation of Custom Biomes** | Ruby ore world generation (`features/`, `feature_rules/`) |
| **Upcoming Creator Features** | Optional 3D `item_visual` block inventory icons (see **minecraft-bedrock-blocks**) |

Never conflate “enable Custom Biomes for ore” with “enable Beta APIs for scripts.”

## What main.js implements

| Component | Type | Purpose |
|-----------|------|---------|
| `toolsplusplus:experience_reward` | Block custom component | Mining XP orbs on ruby ore / deepslate ruby ore |
| `toolsplusplus:digging_durability` | Item custom component | Block-break durability for pickaxe, axe, hoe, shovel (`onMineBlock`) |

Register both in `system.beforeEvents.startup` via `blockComponentRegistry` / `itemComponentRegistry`.

Items bind the item component in JSON:

```json
"toolsplusplus:digging_durability": {}
```

Digger tools no longer auto-lose durability from `minecraft:digger` alone (removed in format 1.20.20+). The custom component handles wear. Swords use `minecraft:damage` for combat durability without scripts.

## Edit → test loop

1. Edit `scripts/main.js` or item/block JSON
2. Run `validate.ps1`, then `install.ps1`
3. Re-enter the world or run `/reload all`

## Do not

- Ask the user to turn on **Beta APIs** for script features
- Use deprecated `on_dig` in digger JSON expecting durability to work
- Put script logic in the resource pack
