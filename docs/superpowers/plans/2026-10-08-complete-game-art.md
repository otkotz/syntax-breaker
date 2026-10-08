# Complete Enemy and Passive Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure every production enemy, passive, skill, support, mastery, and shop upgrade has readable artwork in source and Android exports.

**Architecture:** Resource files remain the source of truth for item icons. Enemy scenes expose their production texture through the existing sprite setup, while exhaustive catalog tests enumerate resources/scenes rather than maintaining a partial allowlist. Existing uncommitted artwork is preserved and audited before generating only missing assets.

**Tech Stack:** Godot 4.6.2, GDScript, PNG pixel art, ImageGen for missing raster assets, native headless tests, Android export.

**Spec:** `docs/superpowers/specs/2026-10-08-stage-finale-art-shop-design.md`

## Global Constraints

- Every spawnable enemy role and regional boss has a distinct non-null production texture.
- Every non-mastery passive, including legendary passives, has a non-null icon.
- Masteries may reuse their matching support icon only with a visible `MASTERY` badge in every renderer.
- Existing uncommitted icon work must be preserved and completed, not overwritten wholesale.
- Artwork stays legible on a phone and visual scaling cannot change collision geometry.

## Review Focus

- A valid PNG with a broken `.import` reference must fail export validation; Task 3 checks source and imported resources.
- A passive outside the current unlock list must still have art; Task 1 enumerates resource files directly.
- A pooled enemy must retain its texture after reset/reinitialize; Task 2 exercises reuse.
- Mastery art must not leak undiscovered support identity in Codex; Task 3 preserves discovery privacy tests.
- Oversized source art must not expand card layout or enemy hitboxes; Tasks 2 and 3 assert rendered bounds.

---

### Task 1: Exhaustive art inventory and failing catalog contract

**Files:**
- Modify: `tests/item_art_native.gd`
- Modify: `scripts/util/resource_listing.gd` only if enumeration omits production resources.
- Create: `docs/art-audit-2026-10-08.md`

**Interfaces:**
- Produces: `art-audit-2026-10-08.md` containing exact missing/bound/reused lists.
- Consumes: `ResourceListing.get_resource_files(path) -> PackedStringArray`.

- [ ] **Step 1: Write exhaustive failing resource tests**

Replace hand-selected passive/icon checks with loops:

```gdscript
for file_name in ResourceListing.get_resource_files("res://resources/passives/"):
	var passive := load("res://resources/passives/" + file_name) as PassiveResource
	check(passive != null, "Passive loads: " + file_name)
	check(passive.icon != null, "Passive has artwork: " + file_name)
	if file_name.ends_with("_mastery.tres"):
		check(_mastery_mapping_is_valid(passive, file_name), "Mastery maps to support art: " + file_name)
```

Add equivalent loops for skills/supports and explicit checks for all three stat-upgrade icon IDs.

- [ ] **Step 2: Run RED and capture exact missing list**

Run `item_art_native.tscn`; expected failures name every currently missing asset. Record the results and whether each dirty working-tree asset is already bound in `docs/art-audit-2026-10-08.md`.

- [ ] **Step 3: Commit only the audit and failing test**

```powershell
git add tests/item_art_native.gd docs/art-audit-2026-10-08.md
git commit -m "test: require complete item artwork"
```

### Task 2: Complete production enemy artwork

**Files:**
- Create/modify: `assets/sprites/enemies/*.png`
- Modify: `scripts/enemies/enemy_base.gd`
- Modify: role scripts under `scripts/enemies/` where sprite builders are incomplete.
- Modify: enemy scenes under `scenes/enemies/` only for explicit texture bindings/visual scale.
- Modify: `tests/combat_readability_native.gd`

**Interfaces:**
- Produces: `EnemyBase.get_visual_texture() -> Texture2D`
- Consumes: existing `PixelSprite`, `BreakerSprite`, `GremlinSprite`, or dedicated PNG texture builders.

- [ ] **Step 1: Write failing exhaustive enemy-scene test**

Enumerate this exact scene set: basic melee/ranged, tank, swarm, charger, denial caster, shield support, splitter, split fragment, miniboss, burning boss, storm boss, toxic boss. For each:

```gdscript
var enemy := load(scene_path).instantiate() as EnemyBase
add_child(enemy)
enemy.set_process(false)
enemy.set_physics_process(false)
var texture := enemy.get_visual_texture()
check(texture != null and texture.get_size().x >= min_width and texture.get_size().y >= min_height,
	"Production enemy has readable art: " + scene_path)
var collision_scale := enemy.get_node("CollisionShape2D").scale
enemy.reset()
enemy.initialize(null)
check(enemy.get_visual_texture() != null and enemy.get_node("CollisionShape2D").scale == collision_scale,
	"Pool reuse preserves art without changing hitbox: " + scene_path)
```

- [ ] **Step 2: Run RED and classify missing versus non-distinct art**

Expected: failures identify scenes with null, undersized, or shared placeholder silhouettes.

- [ ] **Step 3: Generate only missing raster assets**

Use the `imagegen` skill for each missing enemy family. Request transparent, square pixel-art sprites with a readable full-body silhouette and region/role cues; save under `assets/sprites/enemies/`. Inspect each output at original resolution before binding it. Do not regenerate existing approved user art.

- [ ] **Step 4: Bind textures and expose the stable accessor**

Add:

```gdscript
func get_visual_texture() -> Texture2D:
	return _sprite.texture if is_instance_valid(_sprite) else null
```

Bind the generated or existing art in the role-specific setup path. Keep collision nodes at their authored scale and use sprite scale/offset for visual sizing.

- [ ] **Step 5: Run enemy readability tests GREEN and commit**

Run combat readability, encounter, splitter, and boss native tests. Then commit only enemy-art assets/bindings/tests:

```powershell
git add assets/sprites/enemies scripts/enemies scenes/enemies tests/combat_readability_native.gd
git commit -m "feat: complete production enemy artwork"
```

### Task 3: Complete passive/mastery artwork and renderer coverage

**Files:**
- Create/modify: `assets/icons/passives/*.png`
- Modify: `resources/passives/*.tres`
- Modify: `scripts/ui/reward_picker.gd`
- Modify: `scripts/ui/shop.gd`
- Modify: `scripts/ui/skill_manager.gd`
- Modify: `scripts/ui/codex.gd`
- Modify: `scripts/ui/unlock_tree.gd`
- Modify: `scripts/ui/legendary_picker.gd`
- Modify: `scripts/ui/ui_theme.gd`
- Modify: `tests/item_art_native.gd`

**Interfaces:**
- Produces: complete `PassiveResource.icon` bindings.
- Produces: `UITheme.add_mastery_badge(host: Control) -> Label` shared by all renderers.

- [ ] **Step 1: Preserve and inspect current uncommitted art**

Compare every dirty/untracked passive PNG and `.tres` binding against the audit. Keep unique valid art. Do not stage unrelated files until its owning asset is visually inspected and its resource path loads.

- [ ] **Step 2: Generate remaining passive icons**

Use the `imagegen` skill with the established icon style: transparent background, single readable relic/symbol, thick dark contour, limited palette, no text. Save one unique icon per non-mastery passive under `assets/icons/passives/`.

- [ ] **Step 3: Bind every passive and centralize mastery badges**

Each non-mastery `.tres` receives `icon = ExtResource(...)`. Each mastery binds the matching support icon. Replace renderer-local badges with:

```gdscript
static func add_mastery_badge(host: Control) -> Label:
	var badge := Label.new()
	badge.text = "MASTERY"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size", 16)
	host.add_child(badge)
	return badge
```

Call it in reward, shop, manager, Codex, unlock, and legendary renderers whenever the resource is a mastery.

- [ ] **Step 4: Run exhaustive item-art tests GREEN**

Expected: every enumerated resource loads with art; masteries map correctly; undiscovered Codex entries do not expose art; all source images stay within renderer bounds.

- [ ] **Step 5: Commit passive art as a self-contained set**

```powershell
git add assets/icons/passives resources/passives scripts/ui tests/item_art_native.gd docs/art-audit-2026-10-08.md
git commit -m "feat: complete passive artwork across the UI"
```

### Task 4: Android asset inclusion verification

**Files:**
- Modify: `tests/catalog_native.gd`
- Modify: `docs/progress-2026-10-08.md`

**Interfaces:** None.

- [ ] **Step 1: Add source/load validation for every bound icon and texture**

For every resource and enemy scene, assert `ResourceLoader.exists(path)` for external assets and load the final texture through the production resource/scene.

- [ ] **Step 2: Import once and run full native suite**

Expected: zero missing resources, parse errors, or runtime errors.

- [ ] **Step 3: Export Android and inspect/install**

Export the Android preset, verify successful signing and package installation, then inspect the item catalog and representative enemies on the phone. Record any visual-size corrections before declaring the task complete.

- [ ] **Step 4: Commit verification evidence**

```powershell
git add tests/catalog_native.gd docs/progress-2026-10-08.md
git commit -m "test: verify complete art in Android build"
```
