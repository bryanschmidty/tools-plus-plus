---
name: minecraft-bedrock-install
description: Installs Tools++ Minecraft Bedrock packs on Windows — GDK vs UWP paths, stale mcpack cleanup, install.ps1 workflow, and world refresh. Use when packs do not update in-game, wrong texture shows, or installing/testing the addon on Windows.
---

# Minecraft Bedrock Install (Tools++)

## Related skills

- Pack JSON → **minecraft-bedrock-addon**
- Script API → **minecraft-bedrock-scripts**
- Textures and PNGs → **minecraft-bedrock-textures**

## Critical: two Windows paths exist

Modern Bedrock (1.21.120+) reads from **GDK**:

```
%APPDATA%\Minecraft Bedrock\users\shared\games\com.mojang\
```

Legacy UWP path (often **not** the active one):

```
%LOCALAPPDATA%\Packages\Microsoft.MinecraftUWP_8wekyb3d8bbwe\LocalState\games\com.mojang\
```

**Never install only to the UWP path on modern Bedrock.** The game will keep using stale packs from the GDK path.

## Stale .mcpack folder names

Importing `.mcpack` files may create folders unlike the repo names:

| Stale name | Replace with |
|------------|--------------|
| `Tools++Res` | `ToolsPlusPlus_RP` |
| `Tools++Beh` | `ToolsPlusPlus_BP` |

`install.ps1` removes these by UUID and known folder names before copying.

## What install.ps1 does

1. Runs `validate.ps1`
2. Cleans old Tools++ copies from **both** GDK and UWP roots
3. Copies packs to `development_*` and regular pack folders in each root
4. Verifies `ruby.png` SHA256 hash matches the repo

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/install.ps1
```

If Minecraft is running, the script **waits up to 60 seconds** (polling every 3s) for it to close, then continues or exits with a warning.

## Install targets (per root)

```
development_behavior_packs/ToolsPlusPlus_BP/
development_resource_packs/ToolsPlusPlus_RP/
behavior_packs/ToolsPlusPlus_BP/
resource_packs/ToolsPlusPlus_RP/
```

Use `development_*` for day-to-day edits — Bedrock reloads them when you re-enter a world.

## After installing

1. Open Minecraft
2. **Edit world** → remove any old Tools++ packs still listed
3. Activate **Tools++ Behavior Pack** (development or My Packs)
4. RP auto-applies via BP dependency
5. Re-enter world, or run **`/reload all`** in-game

**Beta APIs are not required** for Tools++ scripts (XP, smelting, tool durability). Do not tell the user to enable that experiment.

If textures still look old, create a **new test world** — worlds can cache pack content.

## Edit → test loop

| Change type | Action |
|-------------|--------|
| BP JSON (items, recipes) | `install.ps1` → `/reload` in-game |
| BP scripts (`main.js`) | `install.ps1` → re-enter world or `/reload all` |
| RP texture or lang | `install.ps1` → re-enter world |
| Manifest version bump | Remove/re-add pack on world |

## Do not

- Use directory junctions (symlinks) — use `install.ps1` file copies
- Import `.mcpack` for local dev — causes duplicate UUID copies
- Edit files directly in `com.mojang` — edit repo, then run `install.ps1`
- Assume UWP path is active — always run `install.ps1` (handles both roots)

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Repo updated but game shows old texture | Installing to wrong path | Run `install.ps1`; check GDK path |
| Old ruby after fix script | Stale `Tools++Res` in GDK path | Run `install.ps1` with Minecraft closed |
| "Close Minecraft" error | Game still running | Fully quit Minecraft |
| Pack already exists | Duplicate UUID folders | Run `install.ps1` (cleans old copies) |
| Icons broken after fix | World cached old RP | New world or remove/re-add packs |

## Verify install manually

Compare hash of repo vs installed file:

```powershell
Get-FileHash .\resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby.png
Get-FileHash "$env:APPDATA\Minecraft Bedrock\users\shared\games\com.mojang\resource_packs\ToolsPlusPlus_RP\textures\toolsplusplus\items\ruby.png"
```

Hashes must match after `install.ps1`.

## Checklist

```
- [ ] validate.ps1 passes
- [ ] Minecraft fully closed
- [ ] install.ps1 succeeds (both roots listed)
- [ ] Old Tools++Res / Tools++Beh removed
- [ ] Texture hash verified in GDK path
- [ ] World packs removed and re-added
- [ ] Tested in world (or new world)
```

## References

- [Bedrock Wiki: Project Setup](https://wiki.bedrock.dev/guide/project-setup)
- [Bedrock Wiki: Troubleshooting](https://wiki.bedrock.dev/guide/troubleshooting)
- [Microsoft: GDK folder migration](https://github.com/MicrosoftDocs/minecraft-creator/blob/main/creator/Documents/GDKPCProjectFolder.md)
