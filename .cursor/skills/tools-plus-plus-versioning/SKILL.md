---
name: tools-plus-plus-versioning
description: Tools++ release versioning — when to bump manifest/CHANGELOG vs amend the current version for bug fixes. Use when shipping features, fixing broken releases, updating CHANGELOG.md, or bumping manifest version fields.
---

# Tools++ Versioning

## Related skills

- Pack JSON and manifests → **minecraft-bedrock-addon**
- Install and test → **minecraft-bedrock-install**

## Version source of truth

Manifest header `version` in both packs must stay in sync. Also bump:

- BP data module, script module, and RP dependency UUID version
- RP resources module version

Current changelog: [`CHANGELOG.md`](../../CHANGELOG.md)

## Bump version (new release)

Do this when shipping **new content** — items, blocks, recipes, entities, features, textures, or other player-facing additions.

1. Add a new `## [x.y.z] — date` section at the top of `CHANGELOG.md` (Added / Changed / Fixed / Removed)
2. Bump **all** manifest `version` fields together (e.g. 1.1.21 → 1.1.22)
3. Run `scripts/validate.ps1` before commit

## Do NOT bump version

When fixing bugs in a version that **is not working yet** (broken feature, regression, wrong recipe, install issue in the same release):

1. Keep the same manifest version number
2. Add bullets under the **existing** changelog section (`### Fixed` or `### Changed`)
3. Re-run `install.ps1` and recommit — no new `[x.y.z]` heading

## Examples

| Situation | Version | CHANGELOG |
|-----------|---------|-----------|
| Ship ruby arrow | 1.1.21 → **1.1.22** | New `## [1.1.22]` Added section |
| Ruby arrow entity broken; fix JSON | Stay **1.1.22** | Add under `[1.1.22]` → Fixed |
| Add ruby crossbow later | **1.1.22 → 1.1.23** | New `## [1.1.23]` section |

## Checklist (version bump)

```
- [ ] CHANGELOG.md new section at top
- [ ] BP header + all BP modules + RP dependency version bumped
- [ ] RP header + module version bumped
- [ ] validate.ps1 passes
```
