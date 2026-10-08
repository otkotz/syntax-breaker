# Mobile Shop Cards and Upgrade Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every shop offer a full-card touch target and give each stat upgrade a dedicated icon without breaking scrolling or purchase safety.

**Architecture:** `Shop` builds a single semantic `Button` per offer, with passive child visuals that never intercept input. A small upgrade-icon registry supplies the three stat-upgrade textures. Purchase validation remains centralized in `_on_buy` so a card can trigger at most one transaction.

**Tech Stack:** Godot 4.6.2, GDScript Control nodes, PNG pixel art, native touch simulation tests, Android debug export.

**Spec:** `docs/superpowers/specs/2026-10-08-stage-finale-art-shop-design.md`

## Global Constraints

- Touching icon, title, description, price region, or padding purchases the offer exactly once.
- Dragging beyond the touch threshold scrolls without purchasing.
- Cards remain at least 130 px tall and show disabled/insufficient-gold state.
- Stat upgrades have dedicated damage, haste, and critical-chance artwork.
- Existing shop prices and economy are unchanged.

## Review Focus

- A card removed by another refresh cannot be purchased by a stale release event; Task 1 checks offer identity at release.
- A pointer press followed by a drag outside the card cannot purchase; Task 1 simulates the full gesture.
- Double-tap cannot spend twice after the first refresh; Task 1 checks gold and telemetry count.
- Insufficient-gold cards remain scrollable but never invoke purchase; Task 1 tests disabled state and unchanged gold.
- Nested icon/label controls cannot intercept input on Android; Task 1 checks `mouse_filter` recursively.

---

### Task 1: Full-card shop interaction

**Files:**
- Modify: `scripts/ui/shop.gd`
- Create: `tests/shop_touch_native.gd`
- Create: `tests/shop_touch_native.tscn`
- Modify: `tests/economy_simulation.gd` only if card representation leaks into offer data.

**Interfaces:**
- Produces: `Shop._create_card(offering: Dictionary) -> Button`
- Produces: `Shop._set_card_affordability(card: Button, offering: Dictionary) -> void`
- Consumes: existing `_on_buy(offering)` validation and `RunManager.spend_gold`.

- [ ] **Step 1: Write failing touch tests using real shop cards**

Build one offer of each type and dispatch press/release events at the icon, title, description, price label, and padding. Assert exactly one purchase. Add drag and stale-card cases:

```gdscript
var card := shop._create_card(offering) as Button
check(card != null and card.custom_minimum_size.y >= 130.0, "Offer is one large button")
check(_all_visual_children_ignore_input(card), "Card children cannot steal touch")
var gold_before := RunManager.gold
drag(card.get_global_rect().get_center(), Vector2(0, -120))
check(RunManager.gold == gold_before and offering in shop._offerings,
	"Scrolling does not buy the card")
tap(card.get_global_rect().get_center())
check(RunManager.gold == gold_before - offering.cost and offering not in shop._offerings,
	"Tapping anywhere buys exactly once")
tap(card.get_global_rect().get_center())
check(RunManager.gold == gold_before - offering.cost, "Stale double tap cannot spend twice")
```

- [ ] **Step 2: Run RED**

Expected: `_create_card` returns `PanelContainer`, child regions do not trigger purchase, and drag/tap semantics are not centralized.

- [ ] **Step 3: Replace panel plus buy button with one card button**

Create a `Button`, set `flat = true`, add the styled content as children with `mouse_filter = MOUSE_FILTER_IGNORE`, and connect one `pressed` signal:

```gdscript
var card := Button.new()
card.custom_minimum_size.y = 130.0
card.focus_mode = Control.FOCUS_NONE
card.pressed.connect(func():
	if offering in _offerings:
		_on_buy(offering)
)
```

Render price as a `Label`, not a nested button. Set `card.disabled = RunManager.gold < int(offering.cost)` during every refresh. Use the engine Button/ScrollContainer gesture arbitration; if native tests show `pressed` fires after a drag, track press position and cancel activation past the configured threshold.

- [ ] **Step 4: Run touch and economy tests GREEN**

Run `shop_touch_native.tscn`, `shop_affinity_native.tscn`, `item_art_native.tscn`, and the economy simulation. Expected: purchases and prices unchanged; all touch-path assertions pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/ui/shop.gd tests/shop_touch_native.gd tests/shop_touch_native.tscn tests/economy_simulation.gd
git commit -m "fix: make entire shop card touchable"
```

### Task 2: Dedicated stat-upgrade artwork

**Files:**
- Create: `assets/icons/upgrades/damage-v1.png`
- Create: `assets/icons/upgrades/haste-v1.png`
- Create: `assets/icons/upgrades/critical-v1.png`
- Create: `scripts/ui/shop_upgrade_icons.gd`
- Modify: `scripts/ui/shop.gd`
- Modify: `tests/item_art_native.gd`
- Modify: `tests/shop_touch_native.gd`

**Interfaces:**
- Produces: `ShopUpgradeIcons.get_icon(key: String) -> Texture2D`
- Consumes: stat-upgrade keys `damage`, `cooldown`, and `crit_chance`.

- [ ] **Step 1: Write failing icon-registry tests**

```gdscript
for key in ["damage", "cooldown", "crit_chance"]:
	var icon := ShopUpgradeIcons.get_icon(key)
	check(icon != null and icon.get_size().x >= 64 and icon.get_size().y >= 64,
		"Stat upgrade has readable art: " + key)
var card := shop._create_card(shop._make_stat_upgrade(Shop.STAT_UPGRADES[0]))
check(has_texture(card, ShopUpgradeIcons.get_icon("damage")), "Upgrade card renders its dedicated icon")
```

- [ ] **Step 2: Run RED**

Expected: registry class and PNG assets are absent; upgrade cards render no thumbnail.

- [ ] **Step 3: Generate the three icons**

Use the `imagegen` skill. Match existing item art: transparent background, single bold relic/symbol, thick dark contour, limited colors, no text. Use distinct silhouettes: blade/power core for damage, clock/lightning loop for haste, and targeting eye/reticle for critical chance.

- [ ] **Step 4: Implement registry and render through the common thumbnail layout**

```gdscript
class_name ShopUpgradeIcons
extends RefCounted

const ICONS := {
	"damage": preload("res://assets/icons/upgrades/damage-v1.png"),
	"cooldown": preload("res://assets/icons/upgrades/haste-v1.png"),
	"crit_chance": preload("res://assets/icons/upgrades/critical-v1.png"),
}

static func get_icon(key: String) -> Texture2D:
	return ICONS.get(key)
```

Use the same 80–96 px bounded thumbnail region as resources. Keep all thumbnail children input-transparent.

- [ ] **Step 5: Run item-art and shop-touch tests GREEN, then commit**

```powershell
git add assets/icons/upgrades scripts/ui/shop_upgrade_icons.gd scripts/ui/shop.gd tests/item_art_native.gd tests/shop_touch_native.gd
git commit -m "feat: add artwork for shop stat upgrades"
```

### Task 3: Full UI and Android verification

**Files:**
- Modify: `docs/progress-2026-10-08.md`

**Interfaces:** None.

- [ ] **Step 1: Run full native regression suite and scan logs**

Expected: every scene exits 0; no script/runtime errors; catalog and economy invariants remain valid.

- [ ] **Step 2: Export and install Android build without clearing data**

Run the Android debug export, `adb install -r`, and launch the package.

- [ ] **Step 3: Device smoke test**

Open a shop, scroll through offers, tap card padding to purchase, verify a drag does not purchase, and inspect the three upgrade icons at phone scale. Record the result in the progress document.

- [ ] **Step 4: Commit verification evidence**

```powershell
git add docs/progress-2026-10-08.md
git commit -m "docs: verify mobile shop interactions"
```
