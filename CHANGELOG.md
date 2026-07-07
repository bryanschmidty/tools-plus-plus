# Changelog

All notable changes to **Tools++** are documented here. Version numbers match the behavior and resource pack manifest headers unless noted otherwise.

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.21] — 2026-07-04

### Added
- **Script API tool durability** — `toolsplusplus:digging_durability` custom item component on ruby pickaxe, axe, hoe, and shovel; `onMineBlock` handler in `scripts/main.js` applies wear with Unbreaking support (Bedrock removed automatic digger durability in format 1.20.20+).
- **`minecraft:damage: 7`** on ruby axe for combat durability (matches sword tier).
- **Cursor project docs** — `minecraft-bedrock-scripts` skill and `scripts-no-beta-apis` rule clarifying that Script API features do not require Beta APIs experimental mode.
- **`scripts/recolor-armor-blue-to-ruby.ps1`** — maps diamond armor layer blues to the ruby palette for worn armor textures.

### Changed
- **`scripts/install.ps1`** — when Minecraft is running, waits up to 60 seconds (poll every 3s) for the game to close instead of exiting immediately.
- Updated **minecraft-bedrock-addon** and **minecraft-bedrock-install** skills with script cross-links and corrected experiment guidance.
- Added **tools-plus-plus-versioning** skill; cross-linked from addon and install skills (when to bump versions vs amend the current release).

### Fixed
- Ruby hoe, shovel, and axe no longer stay at full durability when breaking blocks.

---

## [1.1.20] — 2026-07-04

### Added
- **Ruby armor set** — helmet, chestplate, leggings, boots with diamond-tier protection and durability stats.
- Shaped crafting recipes (rubies: 5 / 8 / 7 / 4).
- Resource pack item icons, `attachables` for worn armor, `item_texture.json` entries, and `en_US.lang` names.
- Worn armor layer textures (`ruby_1.png`, `ruby_2.png`) recolored from diamond layers.

---

## [1.1.19] — 2026-07-04

### Fixed
- **Furnace smelt XP** — smelting ruby chunks now awards experience. Previous approach using container open/close events lacked a player reference; fixed via `playerInteractWithBlock`, container open/close entity sources, and `playerInventoryItemChange` during an active smelt session (~0.7 XP per output, vanilla-like).

---

## [1.1.18] — 2026-07-04

### Added
- **Script API module** in behavior pack manifest (`scripts/main.js`, `@minecraft/server` 2.7.0).
- **Mining XP** — `toolsplusplus:experience_reward` block custom component on ruby ore and deepslate ruby ore (0–2 XP orbs, pickaxe + no Silk Touch checks).
- **Smelt XP tracking** — furnace/blast furnace session tracking for ruby chunk output.

---

## [1.1.17] — 2026-07-04

### Added
- **Deepslate ruby ore** — block, item, loot table, texture; hardness 4.5; deepslate/tuff worldgen via split `replace_rules` in `ruby_ore_feature`.
- **Ruby axe, hoe, shovel** — 875 durability, dig speed 7, `toolsplusplus:ruby_tier` tag, crafting recipes, item textures, lang entries.

### Changed
- Refreshed ruby pickaxe and sword item textures.
- Extended `validate.ps1` required paths for new assets.

---

## [1.1.16] — 2026-07-03

### Added
- **Ruby pickaxe, sword, and spear** — shaped recipes; stats between iron and diamond.
- **Spear attachable** — vanilla geometry/animations, first-person thrust, entity texture.
- **Dev scripts** — `build-mcaddon.ps1` and `clean-packs.ps1` for packaging and pack cleanup.

### Changed
- Ruby ore loot accepts ruby-tier pickaxe.
- Spear recipe layout and tool icon halo cleanup.
- **`install.ps1`** — colored, less repetitive output.

---

## [1.1.12] — 2026-07-03

### Added
- **Pack icons** — `scripts/fix-pack-icon.ps1`; 256×256 `pack_icon.png` in both packs.
- **Block of Ruby** — placeable 3D block, terrain atlas, loot table, lang entries.
- Shaped recipes: 9 ruby chunks ↔ 1 block (with `unlock` arrays for Bedrock 1.20.30+ recipe unlocking).

### Changed
- Documented shaped-recipe `unlock` requirement in minecraft-bedrock-addon skill.

---

## [1.1.10] — 2026-07-03

### Added
- **Ruby ore processing chain** — mine ore → raw ruby chunk → smelt → ruby chunk → stonecutter → ruby / ruby shard.
- **Ruby ore block** — format 1.26.30, `item_visual`, block-placer item, loot table, pickaxe tags.
- **Overworld ore generation** — `ore_feature` + `feature_rules` (y 0–62; requires **Creation of Custom Biomes** experiment).
- Items: `raw_ruby_chunk`, `ruby_chunk`, `ruby_shard`.
- Furnace smelt and stonecutter recipes.
- Resource pack terrain atlas, block textures, lang entries.
- **`minecraft-bedrock-blocks`** Cursor skill; expanded texture and addon skills.
- **`validate.ps1`** extensions for blocks, terrain atlas, and block-placer rules.
- **`-RemoveGrayBackground`** option on `fix-item-texture.ps1`.

### Removed
- Legacy shaped ruby crafting recipe (replaced by ore processing chain).

### Changed
- Bump `min_engine_version` to **[1, 26, 0]**.

---

## [1.0.4] — 2026-07-03

### Fixed
- **`item_texture.json`** — use merge-only `texture_data` (never `atlas.terrain`), which had been corrupting item and world textures.
- Move `ruby.png` to namespaced path; preserve PNG alpha in `fix-item-texture.ps1`.

### Added
- Behavior pack manifest dependency on resource pack UUID.
- **`validate.ps1`**, **`validate-textures.ps1`**, **`fix-item-texture.ps1`**, **`install.ps1`** — GDK + legacy UWP `com.mojang` roots, stale `.mcpack` folder cleanup (`Tools++Res` / `Tools++Beh`).
- GitHub Actions CI validation.
- Cursor skills: **minecraft-bedrock-addon**, **minecraft-bedrock-textures**, **minecraft-bedrock-install**.

---

## [1.0.0] — 2026-07-02

### Added
- Initial **Tools++** behavior and resource packs.
- Custom **ruby** item, shaped crafting recipe, item texture, and `en_US.lang` entry.
