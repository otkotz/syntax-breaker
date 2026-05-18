# Syntax Breaker MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable vertical-slice roguelite run (5 stages + final boss) with a tag-based skill/support system in Godot 4 for mobile (portrait).

**Architecture:** Resource-driven — skills, supports, and passives are `.tres` data files. Scenes handle visuals/physics. At runtime, `SkillInstance` composes a resource + linked supports into computed stats and behaviors. Autoload singletons (`GameBus`, `RunManager`, `InputManager`, `BehaviorRegistry`, `MetaProgression`) manage global state. All projectiles/enemies use object pooling.

**Tech Stack:** Godot 4.4+, GDScript, GUT (Godot Unit Testing) for logic tests, portrait 1080×1920, mobile-first touch input.

**Spec:** `docs/superpowers/specs/2026-05-19-syntax-breaker-mvp-design.md`

---

## File Map

### Scripts — Autoloads
| File | Responsibility |
|------|---------------|
| `scripts/autoloads/game_bus.gd` | Global signal bus for decoupled communication |
| `scripts/autoloads/run_manager.gd` | Run state: current stage, gold, inventory, run stats |
| `scripts/autoloads/input_manager.gd` | Abstracts touch/keyboard into movement vector |
| `scripts/autoloads/behavior_registry.gd` | Maps behavior_key strings to behavior scripts |
| `scripts/autoloads/meta_progression.gd` | Unlock tracking, save/load to JSON |

### Scripts — Resources
| File | Responsibility |
|------|---------------|
| `scripts/resources/skill_resource.gd` | Data definition for a skill (tags, stats, scene path) |
| `scripts/resources/support_resource.gd` | Data definition for a support modifier |
| `scripts/resources/passive_resource.gd` | Data definition for a passive buff |
| `scripts/resources/unlock_condition_resource.gd` | Data definition for an unlock condition |

### Scripts — Skills Runtime
| File | Responsibility |
|------|---------------|
| `scripts/skills/skill_instance.gd` | Composes skill + supports → computed stats + behaviors |
| `scripts/skills/skill_caster.gd` | Node on player that manages auto-fire loop for all skills |
| `scripts/skills/targeting.gd` | Static utility: find nearest enemy, priority targeting |

### Scripts — Behaviors
| File | Responsibility |
|------|---------------|
| `scripts/behaviors/behavior_base.gd` | Interface: modify_spawn, on_hit, on_kill, modify_stats |
| `scripts/behaviors/chain_behavior.gd` | Projectile bounces to nearby enemies |
| `scripts/behaviors/split_behavior.gd` | Fires extra projectiles at angles |
| `scripts/behaviors/pierce_behavior.gd` | Projectile passes through enemies |
| `scripts/behaviors/increased_area_behavior.gd` | Expands AoE radius |
| `scripts/behaviors/crit_explosion_behavior.gd` | Crits spawn AoE explosion |
| `scripts/behaviors/poison_on_hit_behavior.gd` | Adds poison DoT on hit |
| `scripts/behaviors/elemental_proliferation_behavior.gd` | Spreads debuff to nearby on kill |
| `scripts/behaviors/faster_casting_behavior.gd` | Stat-only (no behavior script needed, but registered for consistency) |

### Scripts — Enemies
| File | Responsibility |
|------|---------------|
| `scripts/enemies/enemy_base.gd` | Health, damage, death, drops — base for all enemies |
| `scripts/enemies/spawner.gd` | Wave spawning: reads stage config, spawns enemies |

### Scripts — Utilities
| File | Responsibility |
|------|---------------|
| `scripts/util/stat_calculator.gd` | Pure function: base stats + supports + passives → final stats |
| `scripts/util/object_pool.gd` | Generic pool: pre-instantiate, get, release |
| `scripts/util/tag_matcher.gd` | Pure functions: can_link_support, get_matching_passives |

### Scenes
| File | Responsibility |
|------|---------------|
| `scenes/main/main.tscn` | Root scene, manages screen transitions |
| `scenes/main/game_manager.tscn` | Stage flow: combat → shop → next stage → boss |
| `scenes/player/player.tscn` | CharacterBody2D with collision, SkillCaster child |
| `scenes/skills/fireball.tscn` | Projectile: Area2D, Sprite2D, collision |
| `scenes/skills/lightning_bolt.tscn` | Fast projectile, AoE on hit |
| `scenes/skills/poison_dart.tscn` | Slow projectile, DoT on hit |
| `scenes/skills/flame_wave.tscn` | Cone AoE from player |
| `scenes/skills/static_field.tscn` | Radial pulse AoE |
| `scenes/skills/blade_spin.tscn` | Orbiting hitbox around player |
| `scenes/enemies/base_enemy.tscn` | CharacterBody2D, health bar, drops |
| `scenes/enemies/basic_melee.tscn` | Inherits base, chase AI |
| `scenes/enemies/basic_ranged.tscn` | Inherits base, keep-distance + shoot |
| `scenes/enemies/mini_boss.tscn` | Large enemy, telegraph attacks |
| `scenes/stages/arena.tscn` | Walled arena, spawn points, portrait layout |
| `scenes/stages/boss_arena.tscn` | Boss fight arena |
| `scenes/ui/hud.tscn` | HP bar, gold, skill cooldowns |
| `scenes/ui/shop.tscn` | Scrollable card list, buy/reroll |
| `scenes/ui/skill_manager.tscn` | Drag-drop support linking |
| `scenes/ui/virtual_joystick.tscn` | Touch joystick control |
| `scenes/ui/run_summary.tscn` | End-of-run unlocks/stats |
| `scenes/ui/main_menu.tscn` | Title screen, start button |

### Tests
| File | Responsibility |
|------|---------------|
| `tests/test_tag_matcher.gd` | Tag matching rules |
| `tests/test_stat_calculator.gd` | Stat computation pipeline |
| `tests/test_skill_instance.gd` | SkillInstance composition |
| `tests/test_object_pool.gd` | Pool get/release lifecycle |
| `tests/test_behavior_registry.gd` | Behavior lookup |
| `tests/test_meta_progression.gd` | Unlock condition checking |

---

## Task 1: Project Scaffold & Godot Configuration

**Files:**
- Create: `project.godot`
- Create: `CLAUDE.md`
- Create: `scripts/autoloads/game_bus.gd` (stub)
- Create: `scripts/autoloads/run_manager.gd` (stub)
- Create: `scripts/autoloads/input_manager.gd` (stub)
- Create: `scripts/autoloads/behavior_registry.gd` (stub)
- Create: `scripts/autoloads/meta_progression.gd` (stub)

- [ ] **Step 1: Create folder structure**

```bash
cd D:/syntax-breaker
mkdir -p scenes/main scenes/player scenes/skills scenes/enemies scenes/stages scenes/ui
mkdir -p scripts/autoloads scripts/resources scripts/skills scripts/behaviors scripts/enemies scripts/util
mkdir -p resources/skills resources/supports resources/passives resources/enemies resources/stages
mkdir -p assets/sprites assets/audio assets/fonts
mkdir -p tests
```

- [ ] **Step 2: Create project.godot**

Create `project.godot`:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be manually edited.

config_version=5

[application]

config/name="Syntax Breaker"
run/main_scene="res://scenes/main/main.tscn"
config/features=PackedStringArray("4.4", "Mobile")

[autoload]

GameBus="*res://scripts/autoloads/game_bus.gd"
InputManager="*res://scripts/autoloads/input_manager.gd"
BehaviorRegistry="*res://scripts/autoloads/behavior_registry.gd"
RunManager="*res://scripts/autoloads/run_manager.gd"
MetaProgression="*res://scripts/autoloads/meta_progression.gd"

[display]

window/size/viewport_width=1080
window/size/viewport_height=1920
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/handheld/orientation=1

[input_devices]

pointing/emulate_touch_from_mouse=true

[rendering]

renderer/rendering_method="mobile"
```

- [ ] **Step 3: Create autoload stubs**

Create `scripts/autoloads/game_bus.gd`:

```gdscript
extends Node

signal enemy_killed(enemy: Node2D, killer_skill: Resource)
signal enemy_hit(enemy: Node2D, damage: float, skill: Resource)
signal stage_cleared
signal wave_cleared(wave_number: int)
signal gold_changed(new_amount: int)
signal player_died
signal run_ended(victory: bool)
signal skill_acquired(skill: Resource)
signal support_acquired(support: Resource)
signal passive_acquired(passive: Resource)
```

Create `scripts/autoloads/input_manager.gd`:

```gdscript
extends Node

var movement_vector: Vector2 = Vector2.ZERO
var input_source: String = "touch"

signal movement_changed(direction: Vector2)

func set_movement(direction: Vector2) -> void:
	movement_vector = direction.normalized() if direction.length() > 0.1 else Vector2.ZERO
	movement_changed.emit(movement_vector)
```

Create `scripts/autoloads/behavior_registry.gd`:

```gdscript
extends Node

var _behaviors: Dictionary = {}

func register(key: String, behavior_script: GDScript) -> void:
	_behaviors[key] = behavior_script

func get_behavior(key: String) -> RefCounted:
	if _behaviors.has(key):
		return _behaviors[key].new()
	push_warning("BehaviorRegistry: unknown key '%s'" % key)
	return null

func has_behavior(key: String) -> bool:
	return _behaviors.has(key)
```

Create `scripts/autoloads/run_manager.gd`:

```gdscript
extends Node

var current_stage: int = 0
var gold: int = 0
var skill_slots_unlocked: int = 1
var equipped_skills: Array = []
var owned_supports: Array = []
var owned_passives: Array = []
var run_stats: Dictionary = {}

func start_run() -> void:
	current_stage = 0
	gold = 0
	skill_slots_unlocked = 1
	equipped_skills = []
	owned_supports = []
	owned_passives = []
	run_stats = {
		"enemies_killed": 0,
		"damage_by_tag": {},
		"stages_reached": 0,
		"projectiles_fired": 0,
		"crits_landed": 0,
		"poison_applied": 0,
		"skills_used": [],
		"mini_bosses_killed": 0,
		"max_aoe_kill": 0,
		"max_dot_spread_kill": 0,
	}

func add_gold(amount: int) -> void:
	gold += amount
	GameBus.gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		GameBus.gold_changed.emit(gold)
		return true
	return false

func advance_stage() -> void:
	current_stage += 1
	run_stats["stages_reached"] = current_stage
	if current_stage == 2 or current_stage == 4:
		skill_slots_unlocked = mini(skill_slots_unlocked + 1, 4)

func record_stat(stat_key: String, value: Variant) -> void:
	match typeof(run_stats.get(stat_key)):
		TYPE_INT:
			run_stats[stat_key] += value if value is int else 1
		TYPE_ARRAY:
			if not run_stats[stat_key].has(value):
				run_stats[stat_key].append(value)
		TYPE_DICTIONARY:
			for tag_key in value:
				if run_stats[stat_key].has(tag_key):
					run_stats[stat_key][tag_key] += value[tag_key]
				else:
					run_stats[stat_key][tag_key] = value[tag_key]
```

Create `scripts/autoloads/meta_progression.gd`:

```gdscript
extends Node

const SAVE_PATH := "user://meta_progression.json"

var unlocked_items: Dictionary = {
	"skills": ["fireball", "lightning_bolt", "blade_spin"],
	"supports": ["pierce", "faster_casting", "poison_on_hit"],
	"passives": ["thick_skin"],
}

func _ready() -> void:
	load_progress()

func is_unlocked(item_type: String, item_id: String) -> bool:
	return unlocked_items.get(item_type, []).has(item_id)

func unlock_item(item_type: String, item_id: String) -> bool:
	if is_unlocked(item_type, item_id):
		return false
	if not unlocked_items.has(item_type):
		unlocked_items[item_type] = []
	unlocked_items[item_type].append(item_id)
	save_progress()
	return true

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(unlocked_items))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			unlocked_items = json.data
```

- [ ] **Step 4: Create CLAUDE.md**

Create `CLAUDE.md`:

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Syntax Breaker — 2D top-down roguelite built in Godot 4.4+ / GDScript. Mobile-first (portrait 1080×1920), auto-aim combat, tag-based skill/support system inspired by Path of Exile.

## Architecture

Resource-driven: skills, supports, and passives are .tres data files (scripts in scripts/resources/). Scenes in scenes/ handle visuals/physics. At runtime, SkillInstance (scripts/skills/skill_instance.gd) composes a skill resource + linked supports into computed stats and behaviors.

Five autoload singletons: GameBus (signals), RunManager (run state), InputManager (touch abstraction), BehaviorRegistry (support behaviors), MetaProgression (unlocks/save).

Support behaviors implement the interface in scripts/behaviors/behavior_base.gd: modify_spawn(), on_hit(), on_kill(), modify_stats().

## Adding Content

- New skill: create 1 .tres in resources/skills/ + 1 .tscn in scenes/skills/
- New support (stat-only): create 1 .tres in resources/supports/
- New support (with behavior): create 1 .tres + 1 .gd in scripts/behaviors/, register key in behavior_registry.gd

## Commands

- Run tests: open Godot editor → GUT panel → Run All
- Run single test: GUT panel → select test script → Run
- Run project: F5 in Godot editor, or `godot --path . scenes/main/main.tscn`

## Design Spec

docs/superpowers/specs/2026-05-19-syntax-breaker-mvp-design.md
```

- [ ] **Step 5: Create placeholder main scene**

Create `scenes/main/main.tscn`:

```
[gd_scene format=3 uid="uid://main_scene"]

[node name="Main" type="Node2D"]
```

- [ ] **Step 6: Commit**

```bash
cd D:/syntax-breaker
git add -A
git commit -m "feat: scaffold project structure, autoloads, and CLAUDE.md"
```

---

## Task 2: Resource Scripts

**Files:**
- Create: `scripts/resources/skill_resource.gd`
- Create: `scripts/resources/support_resource.gd`
- Create: `scripts/resources/passive_resource.gd`
- Create: `scripts/resources/unlock_condition_resource.gd`

- [ ] **Step 1: Create SkillResource**

Create `scripts/resources/skill_resource.gd`:

```gdscript
class_name SkillResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var tags: Array[String] = []
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_speed: float = 300.0
@export var base_range: float = 400.0
@export var base_pierce: int = 0
@export var max_supports: int = 2
@export var scene_path: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export_multiline var description: String = ""

func has_tag(tag: String) -> bool:
	return tags.has(tag)

func has_any_tag(check_tags: Array[String]) -> bool:
	for tag in check_tags:
		if tags.has(tag):
			return true
	return false
```

- [ ] **Step 2: Create SupportResource**

Create `scripts/resources/support_resource.gd`:

```gdscript
class_name SupportResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var required_tags: Array[String] = []
@export var excluded_tags: Array[String] = []
@export var stat_modifiers: Dictionary = {}
@export var added_tags: Array[String] = []
@export var behavior_key: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export_multiline var description: String = ""

func is_universal() -> bool:
	return required_tags.is_empty()
```

- [ ] **Step 3: Create PassiveResource**

Create `scripts/resources/passive_resource.gd`:

```gdscript
class_name PassiveResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var affected_tags: Array[String] = []
@export var stat_modifiers: Dictionary = {}
@export var rarity: String = "common"
@export_multiline var description: String = ""

func is_global() -> bool:
	return affected_tags.is_empty()
```

- [ ] **Step 4: Create UnlockConditionResource**

Create `scripts/resources/unlock_condition_resource.gd`:

```gdscript
class_name UnlockConditionResource
extends Resource

@export var id: String = ""
@export var item_type: String = ""
@export var item_id: String = ""
@export var condition_type: String = ""
@export var condition_params: Dictionary = {}
@export_multiline var description: String = ""

func check(run_stats: Dictionary) -> bool:
	match condition_type:
		"complete_run":
			return run_stats.get("run_completed", false)
		"reach_stage":
			return run_stats.get("stages_reached", 0) >= condition_params.get("stage", 999)
		"kill_count":
			return run_stats.get("enemies_killed", 0) >= condition_params.get("count", 999)
		"kill_mini_boss":
			return run_stats.get("mini_bosses_killed", 0) >= 1
		"skills_used_count":
			var tag_filter: String = condition_params.get("tag", "")
			var needed: int = condition_params.get("count", 999)
			if tag_filter.is_empty():
				return run_stats.get("skills_used", []).size() >= needed
			var matching := 0
			for skill_id in run_stats.get("skills_used", []):
				matching += 1
			return matching >= needed
		"stat_threshold":
			var stat_key: String = condition_params.get("stat", "")
			var threshold: float = condition_params.get("threshold", 999999.0)
			if stat_key.begins_with("damage_by_tag."):
				var tag := stat_key.split(".")[1]
				return run_stats.get("damage_by_tag", {}).get(tag, 0.0) >= threshold
			return run_stats.get(stat_key, 0.0) >= threshold
		"max_event":
			var event_key: String = condition_params.get("event", "")
			var threshold: int = condition_params.get("count", 999)
			return run_stats.get(event_key, 0) >= threshold
	return false
```

- [ ] **Step 5: Commit**

```bash
cd D:/syntax-breaker
git add scripts/resources/
git commit -m "feat: add resource scripts for skills, supports, passives, unlocks"
```

---

## Task 3: Tag Matcher & Stat Calculator

**Files:**
- Create: `scripts/util/tag_matcher.gd`
- Create: `scripts/util/stat_calculator.gd`
- Create: `tests/test_tag_matcher.gd`
- Create: `tests/test_stat_calculator.gd`

- [ ] **Step 1: Install GUT test framework**

Download GUT for Godot 4 from the AssetLib in the Godot editor, or clone into `addons/gut/`. Then enable in Project → Project Settings → Plugins → GUT → Enable.

Create `.gutconfig.json` in project root:

```json
{
  "dirs": ["res://tests/"],
  "prefix": "test_",
  "suffix": ".gd",
  "should_maximize": false,
  "log_level": 1
}
```

- [ ] **Step 2: Create TagMatcher**

Create `scripts/util/tag_matcher.gd`:

```gdscript
class_name TagMatcher
extends RefCounted

static func can_link_support(skill: SkillResource, support: SupportResource) -> bool:
	if not support.excluded_tags.is_empty():
		for tag in support.excluded_tags:
			if skill.has_tag(tag):
				return false
	if support.is_universal():
		return true
	return skill.has_any_tag(support.required_tags)

static func get_matching_passives(skill: SkillResource, passives: Array) -> Array:
	var matching: Array = []
	for passive in passives:
		if passive is PassiveResource:
			if passive.is_global() or skill.has_any_tag(passive.affected_tags):
				matching.append(passive)
	return matching

static func get_linkable_supports(skill: SkillResource, supports: Array) -> Array:
	var linkable: Array = []
	for support in supports:
		if support is SupportResource and can_link_support(skill, support):
			linkable.append(support)
	return linkable
```

- [ ] **Step 3: Write failing tests for TagMatcher**

Create `tests/test_tag_matcher.gd`:

```gdscript
extends GutTest

var _fireball: SkillResource
var _chain: SupportResource
var _faster_casting: SupportResource
var _beam_only: SupportResource
var _fire_mastery: PassiveResource
var _thick_skin: PassiveResource

func before_each() -> void:
	_fireball = SkillResource.new()
	_fireball.id = "fireball"
	_fireball.tags = ["projectile", "fire"]

	_chain = SupportResource.new()
	_chain.id = "chain"
	_chain.required_tags = ["projectile"]
	_chain.excluded_tags = ["beam"]

	_faster_casting = SupportResource.new()
	_faster_casting.id = "faster_casting"
	_faster_casting.required_tags = []

	_beam_only = SupportResource.new()
	_beam_only.id = "beam_focus"
	_beam_only.required_tags = ["beam"]

	_fire_mastery = PassiveResource.new()
	_fire_mastery.id = "fire_mastery"
	_fire_mastery.affected_tags = ["fire"]

	_thick_skin = PassiveResource.new()
	_thick_skin.id = "thick_skin"
	_thick_skin.affected_tags = []

func test_can_link_matching_tag() -> void:
	assert_true(TagMatcher.can_link_support(_fireball, _chain))

func test_cannot_link_missing_tag() -> void:
	assert_false(TagMatcher.can_link_support(_fireball, _beam_only))

func test_universal_support_links_to_any() -> void:
	assert_true(TagMatcher.can_link_support(_fireball, _faster_casting))

func test_excluded_tag_blocks_link() -> void:
	var beam_skill := SkillResource.new()
	beam_skill.tags = ["projectile", "beam"]
	assert_false(TagMatcher.can_link_support(beam_skill, _chain))

func test_matching_passives_by_tag() -> void:
	var passives: Array = [_fire_mastery, _thick_skin]
	var result := TagMatcher.get_matching_passives(_fireball, passives)
	assert_eq(result.size(), 2)

func test_matching_passives_excludes_unrelated() -> void:
	var lightning_passive := PassiveResource.new()
	lightning_passive.affected_tags = ["lightning"]
	var passives: Array = [lightning_passive]
	var result := TagMatcher.get_matching_passives(_fireball, passives)
	assert_eq(result.size(), 0)

func test_get_linkable_supports() -> void:
	var supports: Array = [_chain, _faster_casting, _beam_only]
	var result := TagMatcher.get_linkable_supports(_fireball, supports)
	assert_eq(result.size(), 2)
	assert_has(result, _chain)
	assert_has(result, _faster_casting)
```

- [ ] **Step 4: Run tests — verify they pass**

Run: Godot editor → GUT panel → Run `tests/test_tag_matcher.gd`
Expected: All 7 tests PASS.

- [ ] **Step 5: Create StatCalculator**

Create `scripts/util/stat_calculator.gd`:

```gdscript
class_name StatCalculator
extends RefCounted

const STAT_MINS := {
	"damage": 1.0,
	"cooldown": 0.1,
	"speed": 50.0,
	"range": 50.0,
	"pierce": 0,
	"area_mult": 0.1,
}

const STAT_MAXS := {
	"cooldown": 10.0,
	"pierce": 20,
	"area_mult": 5.0,
}

static func compute(skill: SkillResource, supports: Array, passives: Array) -> Dictionary:
	var stats := {
		"damage": skill.base_damage,
		"cooldown": skill.base_cooldown,
		"speed": skill.base_speed,
		"range": skill.base_range,
		"pierce": skill.base_pierce,
		"area_mult": 1.0,
		"chain_count": 0,
		"split_count": 0,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
	}

	for support in supports:
		if support is SupportResource:
			_apply_modifiers(stats, support.stat_modifiers)

	var matching_passives := TagMatcher.get_matching_passives(skill, passives)
	for passive in matching_passives:
		if passive is PassiveResource:
			_apply_modifiers(stats, passive.stat_modifiers)

	_clamp_stats(stats)
	return stats

static func _apply_modifiers(stats: Dictionary, modifiers: Dictionary) -> void:
	for key in modifiers:
		if key.ends_with("_mult"):
			var base_key := key.trim_suffix("_mult")
			if stats.has(base_key):
				stats[base_key] *= modifiers[key]
		elif key.ends_with("_add"):
			var base_key := key.trim_suffix("_add")
			if stats.has(base_key):
				stats[base_key] += modifiers[key]
		elif stats.has(key):
			stats[key] += modifiers[key]

static func _clamp_stats(stats: Dictionary) -> void:
	for key in STAT_MINS:
		if stats.has(key):
			stats[key] = max(stats[key], STAT_MINS[key])
	for key in STAT_MAXS:
		if stats.has(key):
			stats[key] = min(stats[key], STAT_MAXS[key])
```

- [ ] **Step 6: Write tests for StatCalculator**

Create `tests/test_stat_calculator.gd`:

```gdscript
extends GutTest

var _fireball: SkillResource
var _chain: SupportResource
var _fire_mastery: PassiveResource

func before_each() -> void:
	_fireball = SkillResource.new()
	_fireball.id = "fireball"
	_fireball.tags = ["projectile", "fire"]
	_fireball.base_damage = 10.0
	_fireball.base_cooldown = 0.8
	_fireball.base_speed = 300.0
	_fireball.base_range = 400.0
	_fireball.base_pierce = 0

	_chain = SupportResource.new()
	_chain.id = "chain"
	_chain.required_tags = ["projectile"]
	_chain.stat_modifiers = {"damage_mult": 0.8, "chain_count": 3}

	_fire_mastery = PassiveResource.new()
	_fire_mastery.id = "fire_mastery"
	_fire_mastery.affected_tags = ["fire"]
	_fire_mastery.stat_modifiers = {"damage_mult": 1.2, "cooldown_mult": 0.9}

func test_base_stats_no_modifiers() -> void:
	var stats := StatCalculator.compute(_fireball, [], [])
	assert_eq(stats["damage"], 10.0)
	assert_eq(stats["cooldown"], 0.8)

func test_support_multiplier() -> void:
	var stats := StatCalculator.compute(_fireball, [_chain], [])
	assert_almost_eq(stats["damage"], 8.0, 0.01)
	assert_eq(stats["chain_count"], 3)

func test_passive_multiplier() -> void:
	var stats := StatCalculator.compute(_fireball, [], [_fire_mastery])
	assert_almost_eq(stats["damage"], 12.0, 0.01)
	assert_almost_eq(stats["cooldown"], 0.72, 0.01)

func test_support_and_passive_stack() -> void:
	var stats := StatCalculator.compute(_fireball, [_chain], [_fire_mastery])
	# damage: 10 * 0.8 (chain) * 1.2 (fire mastery) = 9.6
	assert_almost_eq(stats["damage"], 9.6, 0.01)

func test_unrelated_passive_ignored() -> void:
	var lightning_passive := PassiveResource.new()
	lightning_passive.affected_tags = ["lightning"]
	lightning_passive.stat_modifiers = {"damage_mult": 1.5}
	var stats := StatCalculator.compute(_fireball, [], [lightning_passive])
	assert_eq(stats["damage"], 10.0)

func test_clamp_minimum_damage() -> void:
	var nuke_nerf := SupportResource.new()
	nuke_nerf.required_tags = []
	nuke_nerf.stat_modifiers = {"damage_mult": 0.001}
	var stats := StatCalculator.compute(_fireball, [nuke_nerf], [])
	assert_eq(stats["damage"], 1.0)

func test_additive_modifier() -> void:
	var pierce_support := SupportResource.new()
	pierce_support.required_tags = ["projectile"]
	pierce_support.stat_modifiers = {"pierce": 2}
	var stats := StatCalculator.compute(_fireball, [pierce_support], [])
	assert_eq(stats["pierce"], 2)
```

- [ ] **Step 7: Run tests — verify they pass**

Run: Godot editor → GUT panel → Run `tests/test_stat_calculator.gd`
Expected: All 7 tests PASS.

- [ ] **Step 8: Commit**

```bash
cd D:/syntax-breaker
git add scripts/util/ tests/
git commit -m "feat: add TagMatcher and StatCalculator with tests"
```

---

## Task 4: Behavior System

**Files:**
- Create: `scripts/behaviors/behavior_base.gd`
- Create: `scripts/behaviors/pierce_behavior.gd`
- Create: `tests/test_behavior_registry.gd`

- [ ] **Step 1: Create BehaviorBase interface**

Create `scripts/behaviors/behavior_base.gd`:

```gdscript
class_name BehaviorBase
extends RefCounted

func modify_spawn(_skill_instance, _projectile: Node2D) -> void:
	pass

func on_hit(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func on_kill(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func modify_stats(stats: Dictionary) -> Dictionary:
	return stats
```

- [ ] **Step 2: Create PierceBehavior as first concrete behavior**

Create `scripts/behaviors/pierce_behavior.gd`:

```gdscript
class_name PierceBehavior
extends BehaviorBase

func modify_spawn(skill_instance, projectile: Node2D) -> void:
	if projectile.has_method("set_pierce_count"):
		projectile.set_pierce_count(skill_instance.computed_stats.get("pierce", 0))
```

- [ ] **Step 3: Register PierceBehavior in BehaviorRegistry**

Edit `scripts/autoloads/behavior_registry.gd` — add to `_ready()`:

```gdscript
extends Node

var _behaviors: Dictionary = {}

func _ready() -> void:
	register("pierce", preload("res://scripts/behaviors/pierce_behavior.gd"))

func register(key: String, behavior_script: GDScript) -> void:
	_behaviors[key] = behavior_script

func get_behavior(key: String) -> BehaviorBase:
	if _behaviors.has(key):
		return _behaviors[key].new()
	push_warning("BehaviorRegistry: unknown key '%s'" % key)
	return null

func has_behavior(key: String) -> bool:
	return _behaviors.has(key)
```

- [ ] **Step 4: Write test for BehaviorRegistry**

Create `tests/test_behavior_registry.gd`:

```gdscript
extends GutTest

var _registry: Node

func before_each() -> void:
	_registry = preload("res://scripts/autoloads/behavior_registry.gd").new()
	_registry._ready()

func after_each() -> void:
	_registry.free()

func test_registered_behavior_exists() -> void:
	assert_true(_registry.has_behavior("pierce"))

func test_get_returns_behavior_instance() -> void:
	var b := _registry.get_behavior("pierce")
	assert_not_null(b)
	assert_is(b, BehaviorBase)

func test_unknown_key_returns_null() -> void:
	var b := _registry.get_behavior("nonexistent")
	assert_null(b)
```

- [ ] **Step 5: Run test — verify it passes**

Run: GUT panel → Run `tests/test_behavior_registry.gd`
Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
cd D:/syntax-breaker
git add scripts/behaviors/ tests/test_behavior_registry.gd
git commit -m "feat: add behavior system with base interface and pierce behavior"
```

---

## Task 5: Object Pool

**Files:**
- Create: `scripts/util/object_pool.gd`
- Create: `tests/test_object_pool.gd`

- [ ] **Step 1: Create ObjectPool**

Create `scripts/util/object_pool.gd`:

```gdscript
class_name ObjectPool
extends Node

var _scene: PackedScene
var _pool: Array[Node] = []
var _active: Array[Node] = []
var _parent: Node

func _init(scene: PackedScene, initial_size: int, parent: Node) -> void:
	_scene = scene
	_parent = parent
	for i in initial_size:
		var instance := _scene.instantiate()
		instance.set_process(false)
		instance.set_physics_process(false)
		instance.hide()
		_parent.add_child(instance)
		_pool.append(instance)

func get_instance() -> Node:
	var instance: Node
	if _pool.size() > 0:
		instance = _pool.pop_back()
	else:
		instance = _scene.instantiate()
		_parent.add_child(instance)
	instance.set_process(true)
	instance.set_physics_process(true)
	instance.show()
	_active.append(instance)
	return instance

func release(instance: Node) -> void:
	if not _active.has(instance):
		return
	_active.erase(instance)
	instance.set_process(false)
	instance.set_physics_process(false)
	instance.hide()
	if instance.has_method("reset"):
		instance.reset()
	_pool.append(instance)

func release_all() -> void:
	for instance in _active.duplicate():
		release(instance)

func active_count() -> int:
	return _active.size()

func pool_count() -> int:
	return _pool.size()
```

- [ ] **Step 2: Write tests for ObjectPool**

Create `tests/test_object_pool.gd`:

```gdscript
extends GutTest

var _pool: ObjectPool
var _parent: Node2D

func before_each() -> void:
	_parent = Node2D.new()
	add_child_autofree(_parent)
	var scene := PackedScene.new()
	var node := Sprite2D.new()
	scene.pack(node)
	node.free()
	_pool = ObjectPool.new(scene, 3, _parent)

func test_initial_pool_size() -> void:
	assert_eq(_pool.pool_count(), 3)
	assert_eq(_pool.active_count(), 0)

func test_get_instance_moves_to_active() -> void:
	var inst := _pool.get_instance()
	assert_not_null(inst)
	assert_eq(_pool.active_count(), 1)
	assert_eq(_pool.pool_count(), 2)
	assert_true(inst.visible)

func test_release_returns_to_pool() -> void:
	var inst := _pool.get_instance()
	_pool.release(inst)
	assert_eq(_pool.active_count(), 0)
	assert_eq(_pool.pool_count(), 3)
	assert_false(inst.visible)

func test_get_beyond_pool_creates_new() -> void:
	for i in 4:
		_pool.get_instance()
	assert_eq(_pool.active_count(), 4)
	assert_eq(_pool.pool_count(), 0)

func test_release_all() -> void:
	for i in 3:
		_pool.get_instance()
	_pool.release_all()
	assert_eq(_pool.active_count(), 0)
	assert_eq(_pool.pool_count(), 3)
```

- [ ] **Step 3: Run tests — verify they pass**

Run: GUT panel → Run `tests/test_object_pool.gd`
Expected: All 5 tests PASS.

- [ ] **Step 4: Commit**

```bash
cd D:/syntax-breaker
git add scripts/util/object_pool.gd tests/test_object_pool.gd
git commit -m "feat: add generic ObjectPool for projectile/enemy recycling"
```

---

## Task 6: Input System & Virtual Joystick

**Files:**
- Create: `scenes/ui/virtual_joystick.tscn`
- Create: `scripts/ui/virtual_joystick.gd`

- [ ] **Step 1: Create VirtualJoystick script**

Create `scripts/ui/virtual_joystick.gd`:

```gdscript
class_name VirtualJoystick
extends Control

@export var dead_zone: float = 0.1
@export var clamp_zone: float = 75.0

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	base.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1:
			return
		if event.position.x > get_viewport_rect().size.x * 0.5:
			return
		_touch_index = event.index
		_center = event.position
		base.global_position = _center - base.size * 0.5
		knob.position = base.size * 0.5 - knob.size * 0.5
		base.show()
	else:
		if event.index != _touch_index:
			return
		_touch_index = -1
		base.hide()
		InputManager.set_movement(Vector2.ZERO)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var diff := event.position - _center
	var dist := diff.length()
	var direction := diff.normalized()
	var clamped_dist := min(dist, clamp_zone)

	knob.position = base.size * 0.5 - knob.size * 0.5 + direction * clamped_dist

	if dist / clamp_zone > dead_zone:
		InputManager.set_movement(direction * (clamped_dist / clamp_zone))
	else:
		InputManager.set_movement(Vector2.ZERO)
```

- [ ] **Step 2: Create VirtualJoystick scene**

Create `scenes/ui/virtual_joystick.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://joystick_scene"]

[ext_resource type="Script" path="res://scripts/ui/virtual_joystick.gd" id="1"]

[node name="VirtualJoystick" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
script = ExtResource("1")

[node name="Base" type="TextureRect" parent="."]
custom_minimum_size = Vector2(150, 150)
layout_mode = 0
position = Vector2(0, 0)
size = Vector2(150, 150)
mouse_filter = 2

[node name="Knob" type="TextureRect" parent="Base"]
custom_minimum_size = Vector2(60, 60)
layout_mode = 0
position = Vector2(45, 45)
size = Vector2(60, 60)
mouse_filter = 2
```

Note: Placeholder textures. In Godot editor, assign simple circle textures to Base and Knob (or use ColorRect children as placeholders — a dark circle for the base, a light circle for the knob).

- [ ] **Step 3: Test manually — run scene, touch/click in left half**

Open `scenes/ui/virtual_joystick.tscn` in Godot, add it to a temporary test scene with a Label showing `InputManager.movement_vector`. Run. Click-drag in left half of screen. Verify joystick appears and the vector updates.

- [ ] **Step 4: Commit**

```bash
cd D:/syntax-breaker
git add scripts/ui/ scenes/ui/virtual_joystick.*
git commit -m "feat: add floating virtual joystick for mobile input"
```

---

## Task 7: Player Character

**Files:**
- Create: `scenes/player/player.tscn`
- Create: `scripts/player/player.gd`

- [ ] **Step 1: Create Player script**

Create `scripts/player/player.gd`:

```gdscript
class_name Player
extends CharacterBody2D

@export var move_speed: float = 250.0
@export var max_hp: float = 100.0

var current_hp: float

signal hp_changed(current: float, maximum: float)
signal died

func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

func _physics_process(_delta: float) -> void:
	velocity = InputManager.movement_vector * move_speed
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp = max(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		died.emit()
		GameBus.player_died.emit()

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func set_max_hp(value: float) -> void:
	max_hp = value
	current_hp = min(current_hp, max_hp)
	hp_changed.emit(current_hp, max_hp)
```

- [ ] **Step 2: Create Player scene**

Create `scenes/player/player.tscn`:

```
[gd_scene load_steps=3 format=3 uid="uid://player_scene"]

[ext_resource type="Script" path="res://scripts/player/player.gd" id="1"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 16.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 2
script = ExtResource("1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_body")

[node name="Sprite2D" type="Sprite2D" parent="."]

[node name="SkillCaster" type="Node2D" parent="."]
```

Note: Sprite2D needs a placeholder texture assigned in the editor (a simple colored circle, ~32×32 px).

- [ ] **Step 3: Test manually — create temp scene with Player + VirtualJoystick**

Create a temporary test scene with Player + VirtualJoystick + Camera2D. Run. Verify player moves with joystick. Check that movement feels responsive and stops when joystick is released.

- [ ] **Step 4: Commit**

```bash
cd D:/syntax-breaker
git add scripts/player/ scenes/player/
git commit -m "feat: add player character with movement and health"
```

---

## Task 8: Skill Runtime — SkillInstance, SkillCaster, Targeting

**Files:**
- Create: `scripts/skills/skill_instance.gd`
- Create: `scripts/skills/skill_caster.gd`
- Create: `scripts/skills/targeting.gd`
- Create: `tests/test_skill_instance.gd`

- [ ] **Step 1: Create SkillInstance**

Create `scripts/skills/skill_instance.gd`:

```gdscript
class_name SkillInstance
extends RefCounted

var base: SkillResource
var linked_supports: Array[SupportResource] = []
var computed_stats: Dictionary = {}
var behaviors: Array[BehaviorBase] = []

func _init(skill_resource: SkillResource) -> void:
	base = skill_resource
	recompute()

func link_support(support: SupportResource) -> bool:
	if linked_supports.size() >= base.max_supports:
		return false
	if not TagMatcher.can_link_support(base, support):
		return false
	linked_supports.append(support)
	recompute()
	return true

func unlink_support(support: SupportResource) -> void:
	linked_supports.erase(support)
	recompute()

func clear_supports() -> void:
	linked_supports.clear()
	recompute()

func recompute(passives: Array = []) -> void:
	computed_stats = StatCalculator.compute(base, linked_supports, passives)
	_rebuild_behaviors()

func get_all_tags() -> Array[String]:
	var tags: Array[String] = base.tags.duplicate()
	for support in linked_supports:
		for tag in support.added_tags:
			if not tags.has(tag):
				tags.append(tag)
	return tags

func _rebuild_behaviors() -> void:
	behaviors.clear()
	for support in linked_supports:
		if not support.behavior_key.is_empty():
			var behavior := BehaviorRegistry.get_behavior(support.behavior_key)
			if behavior:
				behaviors.append(behavior)

func notify_spawn(projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.modify_spawn(self, projectile)

func notify_hit(target: Node2D, projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.on_hit(self, target, projectile)

func notify_kill(target: Node2D, projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.on_kill(self, target, projectile)
```

- [ ] **Step 2: Write tests for SkillInstance**

Create `tests/test_skill_instance.gd`:

```gdscript
extends GutTest

var _fireball: SkillResource
var _chain: SupportResource
var _beam_only: SupportResource

func before_each() -> void:
	_fireball = SkillResource.new()
	_fireball.id = "fireball"
	_fireball.tags = ["projectile", "fire"]
	_fireball.base_damage = 10.0
	_fireball.base_cooldown = 0.8
	_fireball.base_speed = 300.0
	_fireball.base_range = 400.0
	_fireball.base_pierce = 0
	_fireball.max_supports = 2

	_chain = SupportResource.new()
	_chain.id = "chain"
	_chain.required_tags = ["projectile"]
	_chain.stat_modifiers = {"damage_mult": 0.8, "chain_count": 3}
	_chain.added_tags = ["chain"]
	_chain.behavior_key = ""

	_beam_only = SupportResource.new()
	_beam_only.id = "beam_focus"
	_beam_only.required_tags = ["beam"]

func test_link_matching_support() -> void:
	var si := SkillInstance.new(_fireball)
	assert_true(si.link_support(_chain))
	assert_eq(si.linked_supports.size(), 1)

func test_reject_non_matching_support() -> void:
	var si := SkillInstance.new(_fireball)
	assert_false(si.link_support(_beam_only))
	assert_eq(si.linked_supports.size(), 0)

func test_max_supports_enforced() -> void:
	var si := SkillInstance.new(_fireball)
	var s1 := SupportResource.new()
	s1.required_tags = []
	var s2 := SupportResource.new()
	s2.required_tags = []
	var s3 := SupportResource.new()
	s3.required_tags = []
	assert_true(si.link_support(s1))
	assert_true(si.link_support(s2))
	assert_false(si.link_support(s3))

func test_computed_stats_update_on_link() -> void:
	var si := SkillInstance.new(_fireball)
	si.link_support(_chain)
	assert_almost_eq(si.computed_stats["damage"], 8.0, 0.01)
	assert_eq(si.computed_stats["chain_count"], 3)

func test_added_tags() -> void:
	var si := SkillInstance.new(_fireball)
	si.link_support(_chain)
	var tags := si.get_all_tags()
	assert_has(tags, "chain")
	assert_has(tags, "projectile")
	assert_has(tags, "fire")

func test_unlink_support() -> void:
	var si := SkillInstance.new(_fireball)
	si.link_support(_chain)
	si.unlink_support(_chain)
	assert_eq(si.linked_supports.size(), 0)
	assert_eq(si.computed_stats["damage"], 10.0)
```

- [ ] **Step 3: Run tests — verify they pass**

Run: GUT panel → Run `tests/test_skill_instance.gd`
Expected: All 6 tests PASS.

- [ ] **Step 4: Create Targeting utility**

Create `scripts/skills/targeting.gd`:

```gdscript
class_name Targeting
extends RefCounted

static func find_nearest_enemy(from: Vector2, max_range: float, enemies_group: String = "enemies") -> Node2D:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var enemies := tree.get_nodes_in_group(enemies_group)
	var nearest: Node2D = null
	var nearest_dist := max_range * max_range

	for enemy in enemies:
		if enemy is Node2D and enemy.is_inside_tree() and not enemy.is_queued_for_deletion():
			if enemy.has_method("is_alive") and not enemy.is_alive():
				continue
			var dist_sq := from.distance_squared_to(enemy.global_position)
			if dist_sq < nearest_dist:
				nearest_dist = dist_sq
				nearest = enemy

	return nearest

static func find_enemies_in_range(from: Vector2, max_range: float, max_count: int = 10, enemies_group: String = "enemies") -> Array[Node2D]:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return []
	var enemies := tree.get_nodes_in_group(enemies_group)
	var in_range: Array[Dictionary] = []
	var range_sq := max_range * max_range

	for enemy in enemies:
		if enemy is Node2D and enemy.is_inside_tree() and not enemy.is_queued_for_deletion():
			if enemy.has_method("is_alive") and not enemy.is_alive():
				continue
			var dist_sq := from.distance_squared_to(enemy.global_position)
			if dist_sq < range_sq:
				in_range.append({"node": enemy, "dist": dist_sq})

	in_range.sort_custom(func(a, b): return a["dist"] < b["dist"])

	var result: Array[Node2D] = []
	for i in mini(in_range.size(), max_count):
		result.append(in_range[i]["node"])
	return result
```

- [ ] **Step 5: Create SkillCaster**

Create `scripts/skills/skill_caster.gd`:

```gdscript
class_name SkillCaster
extends Node2D

var skill_instances: Array[SkillInstance] = []
var _cooldown_timers: Array[float] = []
var _pools: Dictionary = {}

func set_skills(instances: Array[SkillInstance]) -> void:
	skill_instances = instances
	_cooldown_timers.resize(instances.size())
	_cooldown_timers.fill(0.0)
	_setup_pools()

func _setup_pools() -> void:
	for si in skill_instances:
		if si.base.scene_path.is_empty():
			continue
		if _pools.has(si.base.scene_path):
			continue
		var scene := load(si.base.scene_path) as PackedScene
		if scene:
			_pools[si.base.scene_path] = ObjectPool.new(scene, 10, self)

func _physics_process(delta: float) -> void:
	for i in skill_instances.size():
		_cooldown_timers[i] -= delta
		if _cooldown_timers[i] <= 0.0:
			if _try_cast(skill_instances[i]):
				_cooldown_timers[i] = skill_instances[i].computed_stats.get("cooldown", 1.0)

func _try_cast(si: SkillInstance) -> bool:
	var target := Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
	if target == null:
		return false

	var direction := global_position.direction_to(target.global_position)
	_spawn_skill(si, direction, target)
	RunManager.record_stat("projectiles_fired", 1)
	return true

func _spawn_skill(si: SkillInstance, direction: Vector2, _target: Node2D) -> void:
	if si.base.scene_path.is_empty():
		return
	var pool: ObjectPool = _pools.get(si.base.scene_path)
	if pool == null:
		return

	var projectile := pool.get_instance()
	projectile.global_position = global_position
	if projectile.has_method("initialize"):
		projectile.initialize(si, direction, pool)

	si.notify_spawn(projectile)
```

- [ ] **Step 6: Commit**

```bash
cd D:/syntax-breaker
git add scripts/skills/ tests/test_skill_instance.gd
git commit -m "feat: add SkillInstance, SkillCaster, and Targeting system"
```

---

## Task 9: Fireball — First Complete Skill

**Files:**
- Create: `scenes/skills/fireball.tscn`
- Create: `scripts/skills/projectile_base.gd`
- Create: `resources/skills/fireball.tres`

- [ ] **Step 1: Create ProjectileBase script**

Create `scripts/skills/projectile_base.gd`:

```gdscript
class_name ProjectileBase
extends Area2D

var skill_instance: SkillInstance
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 10.0
var pierce_remaining: int = 0
var pool_ref: ObjectPool
var _distance_traveled: float = 0.0
var _max_range: float = 400.0
var _hit_targets: Array[Node2D] = []

func initialize(si: SkillInstance, dir: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	direction = dir.normalized()
	speed = si.computed_stats.get("speed", 300.0)
	damage = si.computed_stats.get("damage", 10.0)
	pierce_remaining = si.computed_stats.get("pierce", 0)
	_max_range = si.computed_stats.get("range", 400.0)
	pool_ref = pool
	_distance_traveled = 0.0
	_hit_targets.clear()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var move_dist := speed * delta
	position += direction * move_dist
	_distance_traveled += move_dist
	if _distance_traveled >= _max_range:
		_return_to_pool()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if _hit_targets.has(body):
		return
	_hit_targets.append(body)

	if body.has_method("take_damage"):
		body.take_damage(damage)
		GameBus.enemy_hit.emit(body, damage, skill_instance.base if skill_instance else null)

	if skill_instance:
		skill_instance.notify_hit(body, self)
		if body.has_method("is_alive") and not body.is_alive():
			skill_instance.notify_kill(body, self)

	if pierce_remaining <= 0:
		_return_to_pool()
	else:
		pierce_remaining -= 1

func set_pierce_count(count: int) -> void:
	pierce_remaining = count

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_hit_targets.clear()
	_distance_traveled = 0.0

func _return_to_pool() -> void:
	if pool_ref:
		pool_ref.release(self)
```

- [ ] **Step 2: Create Fireball scene**

Create `scenes/skills/fireball.tscn`:

```
[gd_scene load_steps=3 format=3 uid="uid://fireball_scene"]

[ext_resource type="Script" path="res://scripts/skills/projectile_base.gd" id="1"]

[sub_resource type="CircleShape2D" id="CircleShape2D_hit"]
radius = 8.0

[node name="Fireball" type="Area2D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_hit")

[node name="Sprite2D" type="Sprite2D" parent="."]

[connection signal="body_entered" from="." to="." method="_on_body_entered"]
```

Note: Assign a small placeholder sprite (orange circle, ~16×16) to the Sprite2D in the editor.

- [ ] **Step 3: Create Fireball resource data**

Create `resources/skills/fireball.tres` — in the Godot editor, create a new SkillResource:
- id: `"fireball"`
- name: `"Fireball"`
- tags: `["projectile", "fire"]`
- base_damage: `10.0`
- base_cooldown: `0.8`
- base_speed: `350.0`
- base_range: `500.0`
- base_pierce: `0`
- max_supports: `2`
- scene_path: `"res://scenes/skills/fireball.tscn"`
- rarity: `"common"`
- description: `"Launches a fireball at the nearest enemy"`

Alternatively, create the file directly:

```
[gd_resource type="Resource" script_class="SkillResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/skill_resource.gd" id="1"]

[resource]
script = ExtResource("1")
id = "fireball"
name = "Fireball"
tags = Array[String](["projectile", "fire"])
base_damage = 10.0
base_cooldown = 0.8
base_speed = 350.0
base_range = 500.0
base_pierce = 0
max_supports = 2
scene_path = "res://scenes/skills/fireball.tscn"
rarity = "common"
description = "Launches a fireball at the nearest enemy"
```

- [ ] **Step 4: Test manually — integration test**

Create a temporary test scene:
1. Add Player (with SkillCaster)
2. Add VirtualJoystick
3. Add a StaticBody2D in "enemies" group with a script that has `take_damage(amount)` and `is_alive() -> bool`
4. In a test script on the scene root, load the fireball resource, create a SkillInstance, and call `skill_caster.set_skills([si])`
5. Run. Verify fireball fires at the enemy, hits it, returns to pool, re-fires on cooldown.

- [ ] **Step 5: Commit**

```bash
cd D:/syntax-breaker
git add scripts/skills/projectile_base.gd scenes/skills/fireball.tscn resources/skills/
git commit -m "feat: add fireball skill — first complete skill pipeline"
```

---

## Task 10: Base Enemy & Wave Spawner

**Files:**
- Create: `scripts/enemies/enemy_base.gd`
- Create: `scripts/enemies/spawner.gd`
- Create: `scenes/enemies/base_enemy.tscn`
- Create: `scenes/enemies/basic_melee.tscn`

- [ ] **Step 1: Create EnemyBase script**

Create `scripts/enemies/enemy_base.gd`:

```gdscript
class_name EnemyBase
extends CharacterBody2D

@export var max_hp: float = 20.0
@export var move_speed: float = 80.0
@export var contact_damage: float = 10.0
@export var gold_value: int = 1

var current_hp: float
var _target: Node2D

signal died(enemy: EnemyBase)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

func initialize(target: Node2D) -> void:
	_target = target
	current_hp = max_hp
	show()
	set_process(true)
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _target and is_instance_valid(_target):
		var dir := global_position.direction_to(_target.global_position)
		velocity = dir * move_speed
		move_and_slide()

func take_damage(amount: float) -> void:
	current_hp -= amount
	_flash_hit()
	if current_hp <= 0.0:
		_die()

func is_alive() -> bool:
	return current_hp > 0.0

func _die() -> void:
	RunManager.add_gold(gold_value)
	RunManager.record_stat("enemies_killed", 1)
	GameBus.enemy_killed.emit(self, null)
	died.emit(self)
	set_process(false)
	set_physics_process(false)
	hide()

func _flash_hit() -> void:
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func reset() -> void:
	current_hp = max_hp
	modulate = Color.WHITE
	velocity = Vector2.ZERO
	_target = null
```

- [ ] **Step 2: Create base_enemy scene**

Create `scenes/enemies/base_enemy.tscn`:

```
[gd_scene load_steps=3 format=3 uid="uid://base_enemy_scene"]

[ext_resource type="Script" path="res://scripts/enemies/enemy_base.gd" id="1"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 12.0

[node name="BaseEnemy" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 5
script = ExtResource("1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_body")

[node name="Sprite2D" type="Sprite2D" parent="."]
```

- [ ] **Step 3: Create basic_melee scene (inherits base)**

Create `scenes/enemies/basic_melee.tscn`:

```
[gd_scene load_steps=3 format=3 uid="uid://basic_melee_scene"]

[ext_resource type="Script" path="res://scripts/enemies/enemy_base.gd" id="1"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 12.0

[node name="BasicMelee" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 5
script = ExtResource("1")
max_hp = 20.0
move_speed = 80.0
contact_damage = 10.0
gold_value = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_body")

[node name="Sprite2D" type="Sprite2D" parent="."]
```

- [ ] **Step 4: Create Spawner**

Create `scripts/enemies/spawner.gd`:

```gdscript
class_name Spawner
extends Node2D

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_margin: float = 50.0

var _current_wave: int = 0
var _total_waves: int = 3
var _enemies_alive: int = 0
var _player: Node2D
var _arena_rect: Rect2

func setup(player: Node2D, arena_rect: Rect2, total_waves: int) -> void:
	_player = player
	_arena_rect = arena_rect
	_total_waves = total_waves
	_current_wave = 0

func start_next_wave() -> void:
	_current_wave += 1
	if _current_wave > _total_waves:
		all_waves_cleared.emit()
		return

	var enemy_count := 5 + _current_wave * 3
	_enemies_alive = enemy_count
	wave_started.emit(_current_wave)
	GameBus.wave_cleared.emit(_current_wave - 1) if _current_wave > 1 else null

	for i in enemy_count:
		_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return
	var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy := scene.instantiate() as EnemyBase
	enemy.global_position = _random_edge_position()
	enemy.initialize(_player)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func _on_enemy_died(_enemy: EnemyBase) -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		if _current_wave >= _total_waves:
			all_waves_cleared.emit()
		else:
			get_tree().create_timer(1.0).timeout.connect(start_next_wave)

func _random_edge_position() -> Vector2:
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(_arena_rect.position.x, _arena_rect.end.x), _arena_rect.position.y - spawn_margin)
		1: return Vector2(randf_range(_arena_rect.position.x, _arena_rect.end.x), _arena_rect.end.y + spawn_margin)
		2: return Vector2(_arena_rect.position.x - spawn_margin, randf_range(_arena_rect.position.y, _arena_rect.end.y))
		_: return Vector2(_arena_rect.end.x + spawn_margin, randf_range(_arena_rect.position.y, _arena_rect.end.y))
```

- [ ] **Step 5: Test manually**

Create temp scene: Player + Spawner + a few walls. Assign basic_melee.tscn to enemy_scenes. Call `spawner.setup(player, Rect2(-200, -300, 400, 600), 3)` then `spawner.start_next_wave()`. Verify enemies spawn from edges, chase player, and waves advance.

- [ ] **Step 6: Commit**

```bash
cd D:/syntax-breaker
git add scripts/enemies/ scenes/enemies/
git commit -m "feat: add base enemy, basic melee, and wave spawner"
```

---

## Task 11: Arena Stage & Game Loop

**Files:**
- Create: `scenes/stages/arena.tscn`
- Create: `scripts/stages/arena.gd`
- Create: `scenes/main/game_manager.tscn`
- Create: `scripts/main/game_manager.gd`

- [ ] **Step 1: Create Arena script**

Create `scripts/stages/arena.gd`:

```gdscript
class_name Arena
extends Node2D

@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var joystick: VirtualJoystick = $CanvasLayer/VirtualJoystick
@onready var hud: Control = $CanvasLayer/HUD

@export var arena_size := Vector2(1080, 1400)

var _waves_for_stage: int = 3

signal stage_completed

func start_stage(stage_number: int, skill_instances: Array[SkillInstance]) -> void:
	_waves_for_stage = 3 + stage_number
	player.global_position = Vector2(arena_size.x / 2, arena_size.y * 0.7)

	var caster := player.get_node("SkillCaster") as SkillCaster
	caster.set_skills(skill_instances)

	var arena_rect := Rect2(Vector2.ZERO, arena_size)
	spawner.setup(player, arena_rect, _waves_for_stage)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared, CONNECT_ONE_SHOT)
	spawner.start_next_wave()

func _on_all_waves_cleared() -> void:
	GameBus.stage_cleared.emit()
	stage_completed.emit()
```

- [ ] **Step 2: Create Arena scene**

Create `scenes/stages/arena.tscn`:

```
[gd_scene load_steps=5 format=3 uid="uid://arena_scene"]

[ext_resource type="Script" path="res://scripts/stages/arena.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/virtual_joystick.tscn" id="3"]

[node name="Arena" type="Node2D"]
script = ExtResource("1")

[node name="Player" parent="." instance=ExtResource("2")]

[node name="Spawner" type="Node2D" parent="."]
script = preload("res://scripts/enemies/spawner.gd")

[node name="Camera2D" type="Camera2D" parent="Player"]
zoom = Vector2(2, 2)

[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="VirtualJoystick" parent="CanvasLayer" instance=ExtResource("3")]

[node name="HUD" type="Control" parent="CanvasLayer"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
```

Note: In the editor, assign basic_melee.tscn to the Spawner's `enemy_scenes` array.

- [ ] **Step 3: Create GameManager script**

Create `scripts/main/game_manager.gd`:

```gdscript
class_name GameManager
extends Node

enum State { MENU, COMBAT, SHOP, BOSS, RUN_END }

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")

var _state: State = State.MENU
var _arena: Arena
var _skill_instances: Array[SkillInstance] = []

signal state_changed(new_state: State)
signal run_completed(victory: bool)

func start_run() -> void:
	RunManager.start_run()
	_setup_starter_skills()
	_advance_to_combat()

func _setup_starter_skills() -> void:
	_skill_instances.clear()
	var fireball_res := load("res://resources/skills/fireball.tres") as SkillResource
	if fireball_res:
		_skill_instances.append(SkillInstance.new(fireball_res))

func _advance_to_combat() -> void:
	RunManager.advance_stage()
	_state = State.COMBAT
	state_changed.emit(_state)

	if _arena:
		_arena.queue_free()

	_arena = ARENA_SCENE.instantiate() as Arena
	add_child(_arena)
	_arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	_arena.start_stage(RunManager.current_stage, _skill_instances)

func _on_stage_completed() -> void:
	if RunManager.current_stage >= 5:
		_start_boss()
	else:
		_open_shop()

func _open_shop() -> void:
	_state = State.SHOP
	state_changed.emit(_state)

func close_shop() -> void:
	_advance_to_combat()

func _start_boss() -> void:
	_state = State.BOSS
	state_changed.emit(_state)
	_advance_to_combat()

func end_run(victory: bool) -> void:
	_state = State.RUN_END
	state_changed.emit(_state)
	GameBus.run_ended.emit(victory)
	run_completed.emit(victory)

func get_skill_instances() -> Array[SkillInstance]:
	return _skill_instances

func add_skill_instance(si: SkillInstance) -> bool:
	if _skill_instances.size() >= RunManager.skill_slots_unlocked:
		return false
	_skill_instances.append(si)
	return true
```

- [ ] **Step 4: Create GameManager scene**

Create `scenes/main/game_manager.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://game_manager_scene"]

[ext_resource type="Script" path="res://scripts/main/game_manager.gd" id="1"]

[node name="GameManager" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 5: Wire up main.tscn**

Update `scenes/main/main.tscn` to instance GameManager and auto-start a run for now:

```
[gd_scene load_steps=2 format=3 uid="uid://main_scene"]

[ext_resource type="PackedScene" path="res://scenes/main/game_manager.tscn" id="1"]

[node name="Main" type="Node"]

[node name="GameManager" parent="." instance=ExtResource("1")]
```

Create `scripts/main/main.gd`:

```gdscript
extends Node

@onready var game_manager: GameManager = $GameManager

func _ready() -> void:
	game_manager.start_run()
```

- [ ] **Step 6: Test manually — run the game**

Press F5. Verify:
- Player appears in arena
- Enemies spawn from edges and chase
- Fireball auto-fires at nearest enemy
- Enemies die, new waves spawn
- After all waves: stage_completed signal fires

- [ ] **Step 7: Commit**

```bash
cd D:/syntax-breaker
git add scripts/stages/ scripts/main/ scenes/stages/ scenes/main/
git commit -m "feat: add arena stage, game manager, and core gameplay loop"
```

---

## Task 12: HUD

**Files:**
- Create: `scripts/ui/hud.gd`
- Create: `scenes/ui/hud.tscn`

- [ ] **Step 1: Create HUD script**

Create `scripts/ui/hud.gd`:

```gdscript
class_name HUD
extends Control

@onready var hp_bar: ProgressBar = $TopBar/HPBar
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var stage_label: Label = $TopBar/StageLabel
@onready var cooldown_container: HBoxContainer = $BottomBar/CooldownContainer

var _player: Player

func setup(player: Player) -> void:
	_player = player
	_player.hp_changed.connect(_on_hp_changed)
	GameBus.gold_changed.connect(_on_gold_changed)
	_update_stage()

func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current

func _on_gold_changed(amount: int) -> void:
	gold_label.text = str(amount)

func _update_stage() -> void:
	stage_label.text = "Stage %d" % RunManager.current_stage

func update_cooldowns(skill_instances: Array[SkillInstance], timers: Array[float]) -> void:
	for i in mini(skill_instances.size(), cooldown_container.get_child_count()):
		var bar: ProgressBar = cooldown_container.get_child(i) as ProgressBar
		if bar:
			bar.max_value = skill_instances[i].computed_stats.get("cooldown", 1.0)
			bar.value = max(timers[i], 0.0)
```

- [ ] **Step 2: Create HUD scene**

Create `scenes/ui/hud.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://hud_scene"]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]

[node name="HUD" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
script = ExtResource("1")

[node name="TopBar" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 60.0
theme_override_constants/separation = 20

[node name="HPBar" type="ProgressBar" parent="TopBar"]
layout_mode = 2
size_flags_horizontal = 3
max_value = 100.0
value = 100.0
show_percentage = false

[node name="GoldLabel" type="Label" parent="TopBar"]
layout_mode = 2
text = "0"
horizontal_alignment = 2

[node name="StageLabel" type="Label" parent="TopBar"]
layout_mode = 2
text = "Stage 1"
horizontal_alignment = 2

[node name="BottomBar" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -100.0
offset_top = -80.0
offset_right = 100.0

[node name="CooldownContainer" type="HBoxContainer" parent="BottomBar"]
layout_mode = 2
theme_override_constants/separation = 10
```

- [ ] **Step 3: Wire HUD into Arena**

Edit `scripts/stages/arena.gd` — in `start_stage()`, after setting up the player, add:

```gdscript
	if hud and hud.has_method("setup"):
		hud.setup(player)
```

Update the Arena scene to instance the HUD scene at `CanvasLayer/HUD`.

- [ ] **Step 4: Test manually**

Run the game. Verify HP bar shows at top, gold counter updates when enemies die, stage label is correct.

- [ ] **Step 5: Commit**

```bash
cd D:/syntax-breaker
git add scripts/ui/hud.gd scenes/ui/hud.tscn scripts/stages/arena.gd scenes/stages/arena.tscn
git commit -m "feat: add HUD with HP bar, gold counter, and stage label"
```

---

## Task 13: Remaining Skills

**Files:**
- Create: `scenes/skills/lightning_bolt.tscn`
- Create: `scenes/skills/poison_dart.tscn`
- Create: `scripts/skills/aoe_skill_base.gd`
- Create: `scenes/skills/flame_wave.tscn`
- Create: `scenes/skills/static_field.tscn`
- Create: `scripts/skills/orbit_skill.gd`
- Create: `scenes/skills/blade_spin.tscn`
- Create: `resources/skills/lightning_bolt.tres`
- Create: `resources/skills/poison_dart.tres`
- Create: `resources/skills/flame_wave.tres`
- Create: `resources/skills/static_field.tres`
- Create: `resources/skills/blade_spin.tres`

- [ ] **Step 1: Create Lightning Bolt and Poison Dart scenes**

Both use `ProjectileBase`. Create `scenes/skills/lightning_bolt.tscn` — same structure as fireball.tscn but with different sprite (blue/yellow, smaller) and uid.

Create `scenes/skills/poison_dart.tscn` — same structure, green sprite.

- [ ] **Step 2: Create Lightning Bolt and Poison Dart resources**

Create `resources/skills/lightning_bolt.tres`:
- id: `"lightning_bolt"`, name: `"Lightning Bolt"`, tags: `["projectile", "lightning"]`
- base_damage: `8.0`, base_cooldown: `0.5`, base_speed: `500.0`, base_range: `450.0`
- base_pierce: `0`, max_supports: `2`, scene_path: `"res://scenes/skills/lightning_bolt.tscn"`
- rarity: `"common"`

Create `resources/skills/poison_dart.tres`:
- id: `"poison_dart"`, name: `"Poison Dart"`, tags: `["projectile", "poison"]`
- base_damage: `5.0`, base_cooldown: `1.2`, base_speed: `200.0`, base_range: `350.0`
- base_pierce: `0`, max_supports: `2`, scene_path: `"res://scenes/skills/poison_dart.tscn"`
- rarity: `"uncommon"`

- [ ] **Step 3: Create AoeSkillBase script**

Create `scripts/skills/aoe_skill_base.gd`:

```gdscript
class_name AoeSkillBase
extends Area2D

var skill_instance: SkillInstance
var damage: float = 10.0
var area_radius: float = 100.0
var pool_ref: ObjectPool
var _lifetime: float = 0.3
var _timer: float = 0.0
var _has_hit: bool = false

func initialize(si: SkillInstance, _direction: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	damage = si.computed_stats.get("damage", 10.0)
	area_radius = si.computed_stats.get("range", 100.0) * si.computed_stats.get("area_mult", 1.0)
	pool_ref = pool
	_timer = 0.0
	_has_hit = false
	scale = Vector2.ONE * (area_radius / 100.0)

func _physics_process(delta: float) -> void:
	_timer += delta
	if not _has_hit:
		_has_hit = true
		_hit_enemies()
	if _timer >= _lifetime:
		_return_to_pool()

func _hit_enemies() -> void:
	var enemies := Targeting.find_enemies_in_range(global_position, area_radius, 50)
	var kill_count := 0
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			GameBus.enemy_hit.emit(enemy, damage, skill_instance.base if skill_instance else null)
			if skill_instance:
				skill_instance.notify_hit(enemy, self)
				if enemy.has_method("is_alive") and not enemy.is_alive():
					skill_instance.notify_kill(enemy, self)
					kill_count += 1
	if kill_count > RunManager.run_stats.get("max_aoe_kill", 0):
		RunManager.run_stats["max_aoe_kill"] = kill_count

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_timer = 0.0
	_has_hit = false
	scale = Vector2.ONE

func _return_to_pool() -> void:
	if pool_ref:
		pool_ref.release(self)
```

- [ ] **Step 4: Create Flame Wave and Static Field scenes**

Create `scenes/skills/flame_wave.tscn` — Area2D with AoeSkillBase script, CollisionShape2D (CircleShape2D, radius 80), orange sprite.

Create `scenes/skills/static_field.tscn` — Area2D with AoeSkillBase script, CollisionShape2D (CircleShape2D, radius 100), blue/yellow sprite.

- [ ] **Step 5: Create Flame Wave and Static Field resources**

Create `resources/skills/flame_wave.tres`:
- id: `"flame_wave"`, name: `"Flame Wave"`, tags: `["aoe", "fire"]`
- base_damage: `15.0`, base_cooldown: `1.5`, base_speed: `0.0`, base_range: `120.0`
- max_supports: `2`, scene_path: `"res://scenes/skills/flame_wave.tscn"`
- rarity: `"uncommon"`

Create `resources/skills/static_field.tres`:
- id: `"static_field"`, name: `"Static Field"`, tags: `["aoe", "lightning"]`
- base_damage: `12.0`, base_cooldown: `2.0`, base_speed: `0.0`, base_range: `150.0`
- max_supports: `2`, scene_path: `"res://scenes/skills/static_field.tscn"`
- rarity: `"uncommon"`

- [ ] **Step 6: Create OrbitSkill script**

Create `scripts/skills/orbit_skill.gd`:

```gdscript
class_name OrbitSkill
extends Area2D

var skill_instance: SkillInstance
var damage: float = 8.0
var orbit_radius: float = 60.0
var orbit_speed: float = 4.0
var pool_ref: ObjectPool
var _angle: float = 0.0
var _parent_node: Node2D
var _hit_cooldowns: Dictionary = {}

const HIT_COOLDOWN := 0.5

func initialize(si: SkillInstance, _direction: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	damage = si.computed_stats.get("damage", 8.0)
	orbit_radius = si.computed_stats.get("range", 60.0) * si.computed_stats.get("area_mult", 1.0)
	orbit_speed = si.computed_stats.get("speed", 300.0) / 75.0
	pool_ref = pool
	_hit_cooldowns.clear()

func set_orbit_parent(parent: Node2D) -> void:
	_parent_node = parent

func _physics_process(delta: float) -> void:
	_angle += orbit_speed * delta
	if _parent_node and is_instance_valid(_parent_node):
		global_position = _parent_node.global_position + Vector2(cos(_angle), sin(_angle)) * orbit_radius

	var expired_keys: Array = []
	for key in _hit_cooldowns:
		_hit_cooldowns[key] -= delta
		if _hit_cooldowns[key] <= 0.0:
			expired_keys.append(key)
	for key in expired_keys:
		_hit_cooldowns.erase(key)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	var body_id := body.get_instance_id()
	if _hit_cooldowns.has(body_id):
		return
	_hit_cooldowns[body_id] = HIT_COOLDOWN

	if body.has_method("take_damage"):
		body.take_damage(damage)
		GameBus.enemy_hit.emit(body, damage, skill_instance.base if skill_instance else null)
	if skill_instance:
		skill_instance.notify_hit(body, self)
		if body.has_method("is_alive") and not body.is_alive():
			skill_instance.notify_kill(body, self)

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_hit_cooldowns.clear()
	_angle = 0.0
	_parent_node = null
```

- [ ] **Step 7: Create Blade Spin scene and resource**

Create `scenes/skills/blade_spin.tscn` — Area2D with OrbitSkill script, CollisionShape2D (CircleShape2D, radius 12), white/silver sprite.

Create `resources/skills/blade_spin.tres`:
- id: `"blade_spin"`, name: `"Blade Spin"`, tags: `["melee", "aoe"]`
- base_damage: `8.0`, base_cooldown: `0.1` (orbits continuously, cooldown is hit rate), base_speed: `300.0`, base_range: `60.0`
- max_supports: `2`, scene_path: `"res://scenes/skills/blade_spin.tscn"`
- rarity: `"common"`

- [ ] **Step 8: Update SkillCaster to handle AoE and Orbit skills**

Edit `scripts/skills/skill_caster.gd` — update `_spawn_skill` to position AoE at player and set orbit parent for orbit skills:

```gdscript
func _spawn_skill(si: SkillInstance, direction: Vector2, _target: Node2D) -> void:
	if si.base.scene_path.is_empty():
		return
	var pool: ObjectPool = _pools.get(si.base.scene_path)
	if pool == null:
		return

	var projectile := pool.get_instance()
	projectile.global_position = global_position

	if projectile.has_method("initialize"):
		projectile.initialize(si, direction, pool)

	if projectile.has_method("set_orbit_parent"):
		projectile.set_orbit_parent(get_parent())

	si.notify_spawn(projectile)
```

Also update `_try_cast` — AoE skills don't need a target (they cast at player position). Check if skill has `aoe` or `melee` tag:

```gdscript
func _try_cast(si: SkillInstance) -> bool:
	var is_self_cast := si.base.has_tag("aoe") or si.base.has_tag("melee")

	if is_self_cast:
		_spawn_skill(si, Vector2.ZERO, null)
		return true

	var target := Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
	if target == null:
		return false

	var direction := global_position.direction_to(target.global_position)
	_spawn_skill(si, direction, target)
	RunManager.record_stat("projectiles_fired", 1)
	return true
```

- [ ] **Step 9: Test manually**

Temporarily modify `_setup_starter_skills()` in game_manager.gd to equip multiple skills. Run and verify each skill type works: projectiles fly at enemies, AoE pulses around player, blade spin orbits.

- [ ] **Step 10: Commit**

```bash
cd D:/syntax-breaker
git add scripts/skills/ scenes/skills/ resources/skills/
git commit -m "feat: add all 6 MVP skills — projectiles, AoE, and orbit"
```

---

## Task 14: Support Behaviors

**Files:**
- Create: `scripts/behaviors/chain_behavior.gd`
- Create: `scripts/behaviors/split_behavior.gd`
- Create: `scripts/behaviors/increased_area_behavior.gd`
- Create: `scripts/behaviors/faster_casting_behavior.gd`
- Create: `scripts/behaviors/crit_explosion_behavior.gd`
- Create: `scripts/behaviors/poison_on_hit_behavior.gd`
- Create: `scripts/behaviors/elemental_proliferation_behavior.gd`
- Create: `resources/supports/*.tres` (all 8)
- Modify: `scripts/autoloads/behavior_registry.gd`

- [ ] **Step 1: Create ChainBehavior**

Create `scripts/behaviors/chain_behavior.gd`:

```gdscript
class_name ChainBehavior
extends BehaviorBase

func on_hit(skill_instance, target: Node2D, projectile: Node2D) -> void:
	var chain_count: int = skill_instance.computed_stats.get("chain_count", 3)
	if not projectile.has_meta("chains_remaining"):
		projectile.set_meta("chains_remaining", chain_count)

	var remaining: int = projectile.get_meta("chains_remaining")
	if remaining <= 0:
		return

	projectile.set_meta("chains_remaining", remaining - 1)

	var next_target := Targeting.find_nearest_enemy(
		target.global_position,
		skill_instance.computed_stats.get("range", 400.0),
	)
	# Skip the target we just hit
	if next_target == target:
		var enemies := Targeting.find_enemies_in_range(target.global_position, skill_instance.computed_stats.get("range", 400.0), 2)
		next_target = enemies[1] if enemies.size() > 1 else null

	if next_target and projectile.has_method("_return_to_pool"):
		# Redirect projectile instead of returning to pool
		if projectile is ProjectileBase:
			projectile.direction = target.global_position.direction_to(next_target.global_position)
			projectile.rotation = projectile.direction.angle()
			projectile._distance_traveled = 0.0
			projectile.damage *= skill_instance.computed_stats.get("damage_mult", 0.8)
```

- [ ] **Step 2: Create SplitBehavior**

Create `scripts/behaviors/split_behavior.gd`:

```gdscript
class_name SplitBehavior
extends BehaviorBase

const SPLIT_ANGLE := 0.3

func modify_spawn(skill_instance, projectile: Node2D) -> void:
	if projectile.has_meta("is_split"):
		return

	var split_count: int = skill_instance.computed_stats.get("split_count", 2)
	if not projectile is ProjectileBase:
		return

	var base_dir: Vector2 = projectile.direction
	var pool: ObjectPool = projectile.pool_ref
	if pool == null:
		return

	for i in split_count:
		var angle_offset := SPLIT_ANGLE * (i + 1) * (1 if i % 2 == 0 else -1)
		var split_dir := base_dir.rotated(angle_offset)
		var split := pool.get_instance()
		split.global_position = projectile.global_position
		split.set_meta("is_split", true)
		if split.has_method("initialize"):
			split.initialize(skill_instance, split_dir, pool)
		split.damage *= 0.7
```

- [ ] **Step 3: Create remaining stat-modifier behaviors**

Create `scripts/behaviors/increased_area_behavior.gd`:

```gdscript
class_name IncreasedAreaBehavior
extends BehaviorBase

func modify_stats(stats: Dictionary) -> Dictionary:
	stats["area_mult"] = stats.get("area_mult", 1.0) * 1.4
	return stats
```

Create `scripts/behaviors/faster_casting_behavior.gd`:

```gdscript
class_name FasterCastingBehavior
extends BehaviorBase

func modify_stats(stats: Dictionary) -> Dictionary:
	stats["cooldown"] = stats.get("cooldown", 1.0) * 0.75
	return stats
```

- [ ] **Step 4: Create CritExplosionBehavior**

Create `scripts/behaviors/crit_explosion_behavior.gd`:

```gdscript
class_name CritExplosionBehavior
extends BehaviorBase

func on_hit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var crit_chance: float = skill_instance.computed_stats.get("crit_chance", 0.05)
	if randf() > crit_chance:
		return

	RunManager.record_stat("crits_landed", 1)
	var explosion_damage: float = skill_instance.computed_stats.get("damage", 10.0) * 0.5
	var explosion_radius: float = 60.0
	var enemies := Targeting.find_enemies_in_range(target.global_position, explosion_radius, 20)
	for enemy in enemies:
		if enemy != target and enemy.has_method("take_damage"):
			enemy.take_damage(explosion_damage)
```

- [ ] **Step 5: Create PoisonOnHitBehavior**

Create `scripts/behaviors/poison_on_hit_behavior.gd`:

```gdscript
class_name PoisonOnHitBehavior
extends BehaviorBase

const POISON_DAMAGE := 3.0
const POISON_DURATION := 3.0
const POISON_TICK := 0.5

func on_hit(_skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if target.has_method("apply_dot"):
		target.apply_dot("poison", POISON_DAMAGE, POISON_DURATION, POISON_TICK)
		RunManager.record_stat("poison_applied", 1)
```

- [ ] **Step 6: Create ElementalProliferationBehavior**

Create `scripts/behaviors/elemental_proliferation_behavior.gd`:

```gdscript
class_name ElementalProliferationBehavior
extends BehaviorBase

const SPREAD_RADIUS := 100.0

func on_kill(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var tags := skill_instance.get_all_tags() if skill_instance.has_method("get_all_tags") else skill_instance.base.tags
	var nearby := Targeting.find_enemies_in_range(target.global_position, SPREAD_RADIUS, 10)
	var spread_count := 0

	for enemy in nearby:
		if enemy == target:
			continue
		if not enemy.has_method("apply_dot"):
			continue

		if "fire" in tags:
			enemy.apply_dot("fire", 5.0, 2.0, 0.5)
			spread_count += 1
		if "lightning" in tags:
			enemy.apply_dot("shock", 3.0, 1.5, 0.3)
			spread_count += 1
		if "poison" in tags:
			enemy.apply_dot("poison", 3.0, 3.0, 0.5)
			spread_count += 1

	if spread_count > RunManager.run_stats.get("max_dot_spread_kill", 0):
		RunManager.run_stats["max_dot_spread_kill"] = spread_count
```

- [ ] **Step 7: Add DoT system to EnemyBase**

Edit `scripts/enemies/enemy_base.gd` — add DoT handling:

```gdscript
var _dots: Dictionary = {}

func apply_dot(dot_type: String, damage_per_tick: float, duration: float, tick_interval: float) -> void:
	_dots[dot_type] = {
		"damage": damage_per_tick,
		"remaining": duration,
		"interval": tick_interval,
		"timer": 0.0,
	}

func _process(delta: float) -> void:
	var expired: Array = []
	for dot_type in _dots:
		var dot: Dictionary = _dots[dot_type]
		dot["timer"] += delta
		dot["remaining"] -= delta
		if dot["timer"] >= dot["interval"]:
			dot["timer"] -= dot["interval"]
			take_damage(dot["damage"])
		if dot["remaining"] <= 0.0:
			expired.append(dot_type)
	for key in expired:
		_dots.erase(key)
```

- [ ] **Step 8: Register all behaviors**

Edit `scripts/autoloads/behavior_registry.gd` — update `_ready()`:

```gdscript
func _ready() -> void:
	register("pierce", preload("res://scripts/behaviors/pierce_behavior.gd"))
	register("chain", preload("res://scripts/behaviors/chain_behavior.gd"))
	register("split", preload("res://scripts/behaviors/split_behavior.gd"))
	register("increased_area", preload("res://scripts/behaviors/increased_area_behavior.gd"))
	register("faster_casting", preload("res://scripts/behaviors/faster_casting_behavior.gd"))
	register("crit_explosion", preload("res://scripts/behaviors/crit_explosion_behavior.gd"))
	register("poison_on_hit", preload("res://scripts/behaviors/poison_on_hit_behavior.gd"))
	register("elemental_proliferation", preload("res://scripts/behaviors/elemental_proliferation_behavior.gd"))
```

- [ ] **Step 9: Create all support .tres resources**

Create each in `resources/supports/`:

`chain.tres`: id `"chain"`, required_tags `["projectile"]`, excluded_tags `["beam"]`, stat_modifiers `{"damage_mult": 0.8, "chain_count": 3}`, added_tags `["chain"]`, behavior_key `"chain"`, rarity `"uncommon"`

`split.tres`: id `"split"`, required_tags `["projectile"]`, stat_modifiers `{"damage_mult": 0.7, "split_count": 2}`, behavior_key `"split"`, rarity `"uncommon"`

`pierce.tres`: id `"pierce"`, required_tags `["projectile"]`, stat_modifiers `{"pierce": 2}`, behavior_key `"pierce"`, rarity `"common"`

`increased_area.tres`: id `"increased_area"`, required_tags `["aoe"]`, stat_modifiers `{"area_mult": 1.4}`, behavior_key `"increased_area"`, rarity `"common"`

`faster_casting.tres`: id `"faster_casting"`, required_tags `[]` (universal), stat_modifiers `{"cooldown_mult": 0.75}`, behavior_key `"faster_casting"`, rarity `"common"`

`elemental_proliferation.tres`: id `"elemental_proliferation"`, required_tags `["fire", "lightning", "poison"]`, behavior_key `"elemental_proliferation"`, rarity `"rare"`

`crit_explosion.tres`: id `"crit_explosion"`, required_tags `[]` (universal), stat_modifiers `{"crit_chance_add": 0.1}`, behavior_key `"crit_explosion"`, rarity `"uncommon"`

`poison_on_hit.tres`: id `"poison_on_hit"`, required_tags `["projectile", "melee"]`, behavior_key `"poison_on_hit"`, rarity `"common"`

- [ ] **Step 10: Create all passive .tres resources**

Create each in `resources/passives/`:

`fire_mastery.tres`: id `"fire_mastery"`, affected_tags `["fire"]`, stat_modifiers `{"damage_mult": 1.2, "cooldown_mult": 0.9}`, rarity `"uncommon"`

`storm_conduit.tres`: id `"storm_conduit"`, affected_tags `["lightning"]`, stat_modifiers `{"damage_mult": 1.15, "area_mult": 1.1}`, rarity `"uncommon"`

`toxic_resilience.tres`: id `"toxic_resilience"`, affected_tags `["poison"]`, stat_modifiers `{"damage_mult": 1.15}`, rarity `"uncommon"`

`projectile_expert.tres`: id `"projectile_expert"`, affected_tags `["projectile"]`, stat_modifiers `{"speed_mult": 1.1, "pierce": 1}`, rarity `"uncommon"`

`thick_skin.tres`: id `"thick_skin"`, affected_tags `[]` (global), stat_modifiers `{}`, rarity `"common"` — Note: Thick Skin modifies player HP, not skill stats. Handle in Player: `max_hp *= 1.15` when passive is acquired.

- [ ] **Step 11: Test manually — link supports to skills**

In `_setup_starter_skills()`, create a SkillInstance with fireball, link Chain and Pierce supports. Run. Verify:
- Fireball pierces through enemies
- After hitting, fireball redirects to bounce to nearby enemy
- Damage decreases per bounce

- [ ] **Step 12: Commit**

```bash
cd D:/syntax-breaker
git add scripts/behaviors/ resources/supports/ resources/passives/ scripts/autoloads/behavior_registry.gd scripts/enemies/enemy_base.gd
git commit -m "feat: add all 8 support behaviors, 5 passives, and DoT system"
```

---

## Task 15: Enemy Variants — Basic Ranged & Mini-Boss

**Files:**
- Create: `scripts/enemies/basic_ranged.gd`
- Create: `scenes/enemies/basic_ranged.tscn`
- Create: `scripts/enemies/mini_boss.gd`
- Create: `scenes/enemies/mini_boss.tscn`
- Create: `scripts/enemies/enemy_projectile.gd`
- Create: `scenes/enemies/enemy_projectile.tscn`

- [ ] **Step 1: Create enemy projectile**

Create `scripts/enemies/enemy_projectile.gd`:

```gdscript
class_name EnemyProjectile
extends Area2D

var speed: float = 150.0
var damage: float = 8.0
var direction: Vector2 = Vector2.ZERO
var _distance: float = 0.0
var _max_range: float = 500.0

func setup(dir: Vector2, dmg: float, spd: float = 150.0) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd
	_distance = 0.0
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var dist := speed * delta
	position += direction * dist
	_distance += dist
	if _distance >= _max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()
```

Create `scenes/enemies/enemy_projectile.tscn`: Area2D with EnemyProjectile script, CircleShape2D (radius 6), small red sprite. Connect `body_entered` signal. Collision layer 8 (enemy projectiles), mask 1 (player).

- [ ] **Step 2: Create BasicRanged**

Create `scripts/enemies/basic_ranged.gd`:

```gdscript
class_name BasicRanged
extends EnemyBase

@export var preferred_distance: float = 200.0
@export var shoot_cooldown: float = 2.0
@export var projectile_damage: float = 8.0

var _shoot_timer: float = 0.0
var _projectile_scene: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	var dist := global_position.distance_to(_target.global_position)
	var dir := global_position.direction_to(_target.global_position)

	if dist > preferred_distance + 30.0:
		velocity = dir * move_speed
	elif dist < preferred_distance - 30.0:
		velocity = -dir * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and dist < preferred_distance + 100.0:
		_shoot()
		_shoot_timer = shoot_cooldown

func _shoot() -> void:
	var proj := _projectile_scene.instantiate() as EnemyProjectile
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(global_position.direction_to(_target.global_position), projectile_damage)
```

Create `scenes/enemies/basic_ranged.tscn`: Same structure as basic_melee but with BasicRanged script. Different color sprite (red). `max_hp = 15.0`, `move_speed = 60.0`, `preferred_distance = 200.0`.

- [ ] **Step 3: Create MiniBoss**

Create `scripts/enemies/mini_boss.gd`:

```gdscript
class_name MiniBoss
extends EnemyBase

@export var charge_speed: float = 300.0
@export var telegraph_time: float = 1.0
@export var charge_cooldown: float = 4.0

var _charge_timer: float = 0.0
var _is_telegraphing: bool = false
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_distance: float = 0.0
var _telegraph_timer: float = 0.0

func _ready() -> void:
	super._ready()
	max_hp = 150.0
	current_hp = max_hp
	move_speed = 50.0
	contact_damage = 20.0
	gold_value = 10

func _physics_process(delta: float) -> void:
	if _is_telegraphing:
		_telegraph_timer -= delta
		modulate = Color(1, 0.3, 0.3) if fmod(_telegraph_timer, 0.2) < 0.1 else Color.WHITE
		if _telegraph_timer <= 0.0:
			_start_charge()
		return

	if _is_charging:
		velocity = _charge_dir * charge_speed
		move_and_slide()
		_charge_distance -= charge_speed * delta
		if _charge_distance <= 0.0:
			_is_charging = false
			modulate = Color.WHITE
		return

	if _target and is_instance_valid(_target):
		var dir := global_position.direction_to(_target.global_position)
		velocity = dir * move_speed
		move_and_slide()

	_charge_timer -= delta
	if _charge_timer <= 0.0:
		_begin_telegraph()
		_charge_timer = charge_cooldown

func _begin_telegraph() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_is_telegraphing = true
	_telegraph_timer = telegraph_time
	_charge_dir = global_position.direction_to(_target.global_position)
	velocity = Vector2.ZERO

func _start_charge() -> void:
	_is_telegraphing = false
	_is_charging = true
	_charge_distance = 300.0
	modulate = Color(1, 0.5, 0.5)

func _die() -> void:
	RunManager.record_stat("mini_bosses_killed", 1)
	super._die()
```

Create `scenes/enemies/mini_boss.tscn`: CharacterBody2D with MiniBoss script. Larger collision (radius 24). Larger sprite. Collision layer 2, mask 5.

- [ ] **Step 4: Update Spawner to use ranged enemies and mini-boss**

Edit `scripts/enemies/spawner.gd` — add mini-boss support:

```gdscript
@export var mini_boss_scene: PackedScene

var _is_boss_stage: bool = false

func setup(player: Node2D, arena_rect: Rect2, total_waves: int, boss_stage: bool = false) -> void:
	_player = player
	_arena_rect = arena_rect
	_total_waves = total_waves
	_current_wave = 0
	_is_boss_stage = boss_stage
```

In `_on_enemy_died`, after all waves cleared, if `_is_boss_stage` and `mini_boss_scene`, spawn the mini-boss:

```gdscript
func _on_enemy_died(_enemy: EnemyBase) -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		if _current_wave >= _total_waves:
			if _is_boss_stage and mini_boss_scene:
				_spawn_mini_boss()
			else:
				all_waves_cleared.emit()
		else:
			get_tree().create_timer(1.0).timeout.connect(start_next_wave)

func _spawn_mini_boss() -> void:
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.global_position = Vector2(_arena_rect.get_center().x, _arena_rect.position.y + 100)
	boss.initialize(_player)
	boss.died.connect(func(_e): all_waves_cleared.emit(), CONNECT_ONE_SHOT)
	_enemies_alive = 1
	add_child(boss)
```

- [ ] **Step 5: Test manually**

Run game, verify ranged enemies keep distance and shoot. Set stage 3 as boss stage in arena.gd, verify mini-boss spawns after waves, telegraphs charge, drops gold.

- [ ] **Step 6: Commit**

```bash
cd D:/syntax-breaker
git add scripts/enemies/ scenes/enemies/
git commit -m "feat: add ranged enemy, mini-boss with charge attack, and enemy projectiles"
```

---

## Task 16: Gold, Drops & Shop UI

**Files:**
- Create: `scripts/ui/shop.gd`
- Create: `scenes/ui/shop.tscn`
- Create: `scripts/ui/shop_card.gd`
- Create: `scenes/ui/shop_card.tscn`

- [ ] **Step 1: Create ShopCard**

Create `scripts/ui/shop_card.gd`:

```gdscript
class_name ShopCard
extends PanelContainer

@onready var name_label: Label = $VBox/NameLabel
@onready var desc_label: Label = $VBox/DescLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var tags_label: Label = $VBox/TagsLabel
@onready var buy_button: Button = $VBox/BuyButton

var item_resource: Resource
var cost: int

signal purchased(item: Resource)

func setup(item: Resource, price: int) -> void:
	item_resource = item
	cost = price

	if item is SkillResource:
		name_label.text = item.name
		desc_label.text = item.description
		tags_label.text = ", ".join(item.tags)
	elif item is SupportResource:
		name_label.text = item.name
		desc_label.text = item.description
		tags_label.text = "Req: " + ", ".join(item.required_tags) if not item.required_tags.is_empty() else "Universal"
	elif item is PassiveResource:
		name_label.text = item.name
		desc_label.text = item.description
		tags_label.text = ", ".join(item.affected_tags) if not item.affected_tags.is_empty() else "Global"

	cost_label.text = "%d gold" % cost
	buy_button.pressed.connect(_on_buy)

func _on_buy() -> void:
	if RunManager.spend_gold(cost):
		purchased.emit(item_resource)
		queue_free()

func update_affordability() -> void:
	buy_button.disabled = RunManager.gold < cost
```

Create `scenes/ui/shop_card.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://shop_card_scene"]

[ext_resource type="Script" path="res://scripts/ui/shop_card.gd" id="1"]

[node name="ShopCard" type="PanelContainer"]
custom_minimum_size = Vector2(0, 120)
script = ExtResource("1")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="NameLabel" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 24

[node name="TagsLabel" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14

[node name="DescLabel" type="Label" parent="VBox"]
layout_mode = 2
autowrap_mode = 2

[node name="CostLabel" type="Label" parent="VBox"]
layout_mode = 2

[node name="BuyButton" type="Button" parent="VBox"]
layout_mode = 2
text = "Buy"
```

- [ ] **Step 2: Create Shop script**

Create `scripts/ui/shop.gd`:

```gdscript
class_name Shop
extends Control

@onready var item_list: VBoxContainer = $Panel/ScrollContainer/ItemList
@onready var gold_label: Label = $Panel/TopBar/GoldLabel
@onready var reroll_button: Button = $Panel/TopBar/RerollButton
@onready var continue_button: Button = $Panel/ContinueButton

const SHOP_CARD_SCENE := preload("res://scenes/ui/shop_card.tscn")
const ITEMS_PER_SHOP := 4
const REROLL_COST := 5

var _all_skills: Array[SkillResource] = []
var _all_supports: Array[SupportResource] = []
var _all_passives: Array[PassiveResource] = []

signal shop_closed

func _ready() -> void:
	continue_button.pressed.connect(_on_continue)
	reroll_button.pressed.connect(_on_reroll)
	GameBus.gold_changed.connect(func(g): gold_label.text = "Gold: %d" % g)

func open(skills: Array[SkillResource], supports: Array[SupportResource], passives: Array[PassiveResource]) -> void:
	_all_skills = skills
	_all_supports = supports
	_all_passives = passives
	gold_label.text = "Gold: %d" % RunManager.gold
	_populate_items()
	show()

func _populate_items() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var pool: Array[Resource] = []
	pool.append_array(_all_skills)
	pool.append_array(_all_supports)
	pool.append_array(_all_passives)
	pool.shuffle()

	var count := mini(ITEMS_PER_SHOP, pool.size())
	for i in count:
		var item := pool[i]
		var price := _get_price(item)
		var card := SHOP_CARD_SCENE.instantiate() as ShopCard
		item_list.add_child(card)
		card.setup(item, price)
		card.purchased.connect(_on_item_purchased)

func _get_price(item: Resource) -> int:
	var rarity: String = item.get("rarity") if item.get("rarity") else "common"
	match rarity:
		"common": return 3
		"uncommon": return 6
		"rare": return 10
	return 5

func _on_item_purchased(item: Resource) -> void:
	if item is SkillResource:
		GameBus.skill_acquired.emit(item)
	elif item is SupportResource:
		GameBus.support_acquired.emit(item)
	elif item is PassiveResource:
		GameBus.passive_acquired.emit(item)
	_update_affordability()

func _on_reroll() -> void:
	if RunManager.spend_gold(REROLL_COST):
		_populate_items()

func _on_continue() -> void:
	hide()
	shop_closed.emit()

func _update_affordability() -> void:
	for card in item_list.get_children():
		if card is ShopCard:
			card.update_affordability()
```

Create `scenes/ui/shop.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://shop_scene"]

[ext_resource type="Script" path="res://scripts/ui/shop.gd" id="1"]

[node name="Shop" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = 40.0
offset_right = -20.0
offset_bottom = -40.0

[node name="TopBar" type="HBoxContainer" parent="Panel"]
layout_mode = 2
size_flags_vertical = 0

[node name="GoldLabel" type="Label" parent="Panel/TopBar"]
layout_mode = 2
text = "Gold: 0"

[node name="RerollButton" type="Button" parent="Panel/TopBar"]
layout_mode = 2
text = "Reroll (5g)"

[node name="ScrollContainer" type="ScrollContainer" parent="Panel"]
layout_mode = 2
size_flags_vertical = 3

[node name="ItemList" type="VBoxContainer" parent="Panel/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 10

[node name="ContinueButton" type="Button" parent="Panel"]
layout_mode = 2
size_flags_vertical = 8
text = "Continue"
```

- [ ] **Step 3: Wire shop into GameManager**

Edit `scripts/main/game_manager.gd` — add shop handling:

```gdscript
var _shop: Shop

func _open_shop() -> void:
	_state = State.SHOP
	state_changed.emit(_state)

	if not _shop:
		_shop = preload("res://scenes/ui/shop.tscn").instantiate() as Shop
		add_child(_shop)
		_shop.shop_closed.connect(_on_shop_closed)
		GameBus.skill_acquired.connect(_on_skill_acquired)
		GameBus.support_acquired.connect(_on_support_acquired)
		GameBus.passive_acquired.connect(_on_passive_acquired)

	var skills := _get_unlocked_resources("res://resources/skills/", "skills") as Array[SkillResource]
	var supports := _get_unlocked_resources("res://resources/supports/", "supports") as Array[SupportResource]
	var passives := _get_unlocked_resources("res://resources/passives/", "passives") as Array[PassiveResource]
	_shop.open(skills, supports, passives)

func _on_shop_closed() -> void:
	close_shop()

func _on_skill_acquired(skill: Resource) -> void:
	if skill is SkillResource:
		var si := SkillInstance.new(skill)
		add_skill_instance(si)

func _on_support_acquired(support: Resource) -> void:
	if support is SupportResource:
		RunManager.owned_supports.append(support)

func _on_passive_acquired(passive: Resource) -> void:
	if passive is PassiveResource:
		RunManager.owned_passives.append(passive)
		for si in _skill_instances:
			si.recompute(RunManager.owned_passives)

func _get_unlocked_resources(dir_path: String, item_type: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(dir_path)
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(dir_path + file_name)
			if res and MetaProgression.is_unlocked(item_type, res.get("id")):
				result.append(res)
		file_name = dir.get_next()
	return result
```

- [ ] **Step 4: Test manually**

Run game. Kill enemies to earn gold. After stage clears, shop should appear. Verify: items display with correct info, buying deducts gold, reroll works, continue advances to next stage.

- [ ] **Step 5: Commit**

```bash
cd D:/syntax-breaker
git add scripts/ui/shop*.gd scenes/ui/shop*.tscn scripts/main/game_manager.gd
git commit -m "feat: add shop UI with card-based item purchasing and reroll"
```

---

## Task 17: Skill Manager UI (Support Linking)

**Files:**
- Create: `scripts/ui/skill_manager.gd`
- Create: `scenes/ui/skill_manager.tscn`

- [ ] **Step 1: Create SkillManager script**

Create `scripts/ui/skill_manager.gd`:

```gdscript
class_name SkillManagerUI
extends Control

@onready var skill_slots: VBoxContainer = $Panel/SkillSlots
@onready var support_pool: VBoxContainer = $Panel/SupportPool
@onready var close_button: Button = $Panel/CloseButton

var _skill_instances: Array[SkillInstance] = []
var _available_supports: Array[SupportResource] = []

signal closed

func _ready() -> void:
	close_button.pressed.connect(func(): closed.emit(); hide())

func open(skill_instances: Array[SkillInstance], supports: Array[SupportResource]) -> void:
	_skill_instances = skill_instances
	_available_supports = supports
	_rebuild_ui()
	show()

func _rebuild_ui() -> void:
	_clear_children(skill_slots)
	_clear_children(support_pool)

	for si in _skill_instances:
		var skill_panel := _create_skill_panel(si)
		skill_slots.add_child(skill_panel)

	for support in _available_supports:
		var btn := Button.new()
		btn.text = support.name
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(func(): _on_support_selected(support))
		support_pool.add_child(btn)

var _selected_support: SupportResource = null
var _linking_to: SkillInstance = null

func _on_support_selected(support: SupportResource) -> void:
	_selected_support = support

func _create_skill_panel(si: SkillInstance) -> VBoxContainer:
	var panel := VBoxContainer.new()
	var name_label := Label.new()
	name_label.text = si.base.name + " [" + ", ".join(si.base.tags) + "]"
	panel.add_child(name_label)

	for i in si.base.max_supports:
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(0, 40)
		if i < si.linked_supports.size():
			var linked := si.linked_supports[i]
			slot_btn.text = linked.name
			slot_btn.pressed.connect(func(): _unlink_support(si, linked))
		else:
			slot_btn.text = "[Empty Slot]"
			slot_btn.pressed.connect(func(): _link_selected_to(si))
		panel.add_child(slot_btn)

	return panel

func _link_selected_to(si: SkillInstance) -> void:
	if _selected_support == null:
		return
	if si.link_support(_selected_support):
		_available_supports.erase(_selected_support)
		si.recompute(RunManager.owned_passives)
		_selected_support = null
		_rebuild_ui()

func _unlink_support(si: SkillInstance, support: SupportResource) -> void:
	si.unlink_support(support)
	_available_supports.append(support)
	si.recompute(RunManager.owned_passives)
	_rebuild_ui()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
```

- [ ] **Step 2: Create SkillManager scene**

Create `scenes/ui/skill_manager.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://skill_manager_scene"]

[ext_resource type="Script" path="res://scripts/ui/skill_manager.gd" id="1"]

[node name="SkillManager" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 30.0
offset_right = -10.0
offset_bottom = -30.0

[node name="HSplit" type="HSplitContainer" parent="Panel"]
layout_mode = 2

[node name="SkillSlots" type="VBoxContainer" parent="Panel"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 15

[node name="SupportPool" type="VBoxContainer" parent="Panel"]
layout_mode = 2
size_flags_horizontal = 3

[node name="CloseButton" type="Button" parent="Panel"]
layout_mode = 2
size_flags_vertical = 8
text = "Done"
```

- [ ] **Step 3: Wire into Shop — add "Manage Skills" button**

Edit `scripts/ui/shop.gd` — add a manage button that opens the skill manager:

```gdscript
@onready var manage_button: Button = $Panel/TopBar/ManageButton

var _skill_manager: SkillManagerUI

func _ready() -> void:
	continue_button.pressed.connect(_on_continue)
	reroll_button.pressed.connect(_on_reroll)
	manage_button.pressed.connect(_on_manage)
	GameBus.gold_changed.connect(func(g): gold_label.text = "Gold: %d" % g)

func _on_manage() -> void:
	if not _skill_manager:
		_skill_manager = preload("res://scenes/ui/skill_manager.tscn").instantiate() as SkillManagerUI
		add_child(_skill_manager)
	var game_manager := get_tree().current_scene.get_node("GameManager") as GameManager
	if game_manager:
		_skill_manager.open(game_manager.get_skill_instances(), RunManager.owned_supports)
```

Add `ManageButton` node in `scenes/ui/shop.tscn` inside the TopBar HBoxContainer.

- [ ] **Step 4: Test manually**

Run game. Earn gold, reach shop. Buy a support. Click "Manage Skills". Verify: skills shown with empty slots, support pool shows owned supports, tap support then tap slot to link, tap linked support to unlink.

- [ ] **Step 5: Commit**

```bash
cd D:/syntax-breaker
git add scripts/ui/skill_manager.gd scenes/ui/skill_manager.tscn scripts/ui/shop.gd scenes/ui/shop.tscn
git commit -m "feat: add skill manager UI for linking supports to skills"
```

---

## Task 18: Meta-Progression — Unlock Checking

**Files:**
- Create: `resources/unlocks/*.tres` (all unlock conditions)
- Create: `tests/test_meta_progression.gd`
- Modify: `scripts/autoloads/meta_progression.gd`

- [ ] **Step 1: Add unlock checking to MetaProgression**

Edit `scripts/autoloads/meta_progression.gd` — add unlock condition loading and checking:

```gdscript
var _unlock_conditions: Array[UnlockConditionResource] = []

func _ready() -> void:
	load_progress()
	_load_unlock_conditions()

func _load_unlock_conditions() -> void:
	var dir := DirAccess.open("res://resources/unlocks/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/unlocks/" + file_name) as UnlockConditionResource
			if res:
				_unlock_conditions.append(res)
		file_name = dir.get_next()

func check_unlocks(run_stats: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	for condition in _unlock_conditions:
		if is_unlocked(condition.item_type, condition.item_id):
			continue
		if condition.check(run_stats):
			unlock_item(condition.item_type, condition.item_id)
			newly_unlocked.append(condition.item_id)
	return newly_unlocked
```

- [ ] **Step 2: Create unlock condition resources**

Create `resources/unlocks/` directory. Create one `.tres` per unlock:

`unlock_poison_dart.tres`:
```
id: "unlock_poison_dart"
item_type: "skills"
item_id: "poison_dart"
condition_type: "reach_stage"
condition_params: { "stage": 3 }
description: "Reach Stage 3"
```

`unlock_flame_wave.tres`:
```
id: "unlock_flame_wave"
item_type: "skills"
item_id: "flame_wave"
condition_type: "kill_count"
condition_params: { "count": 50 }
description: "Kill 50 enemies in one run"
```

`unlock_static_field.tres`:
```
id: "unlock_static_field"
item_type: "skills"
item_id: "static_field"
condition_type: "kill_mini_boss"
condition_params: {}
description: "Kill a mini-boss"
```

`unlock_chain.tres`:
```
id: "unlock_chain"
item_type: "supports"
item_id: "chain"
condition_type: "complete_run"
condition_params: {}
description: "Complete a full run"
```

`unlock_split.tres`:
```
id: "unlock_split"
item_type: "supports"
item_id: "split"
condition_type: "skills_used_count"
condition_params: { "count": 3 }
description: "Use 3 different projectile skills in one run"
```

`unlock_increased_area.tres`:
```
id: "unlock_increased_area"
item_type: "supports"
item_id: "increased_area"
condition_type: "max_event"
condition_params: { "event": "max_aoe_kill", "count": 10 }
description: "Kill 10 enemies with a single AoE cast"
```

`unlock_crit_explosion.tres`:
```
id: "unlock_crit_explosion"
item_type: "supports"
item_id: "crit_explosion"
condition_type: "stat_threshold"
condition_params: { "stat": "crits_landed", "threshold": 50 }
description: "Land 50 critical hits in one run"
```

`unlock_elemental_proliferation.tres`:
```
id: "unlock_elemental_proliferation"
item_type: "supports"
item_id: "elemental_proliferation"
condition_type: "max_event"
condition_params: { "event": "max_dot_spread_kill", "count": 3 }
description: "Kill 3 enemies with a single DoT spread"
```

`unlock_fire_mastery.tres`:
```
id: "unlock_fire_mastery"
item_type: "passives"
item_id: "fire_mastery"
condition_type: "stat_threshold"
condition_params: { "stat": "damage_by_tag.fire", "threshold": 1000 }
description: "Deal 1000 cumulative fire damage"
```

`unlock_storm_conduit.tres`:
```
id: "unlock_storm_conduit"
item_type: "passives"
item_id: "storm_conduit"
condition_type: "stat_threshold"
condition_params: { "stat": "damage_by_tag.lightning", "threshold": 1000 }
description: "Deal 1000 cumulative lightning damage"
```

`unlock_toxic_resilience.tres`:
```
id: "unlock_toxic_resilience"
item_type: "passives"
item_id: "toxic_resilience"
condition_type: "stat_threshold"
condition_params: { "stat": "poison_applied", "threshold": 100 }
description: "Apply poison to 100 enemies"
```

`unlock_projectile_expert.tres`:
```
id: "unlock_projectile_expert"
item_type: "passives"
item_id: "projectile_expert"
condition_type: "stat_threshold"
condition_params: { "stat": "projectiles_fired", "threshold": 500 }
description: "Fire 500 projectiles"
```

- [ ] **Step 3: Write tests for unlock checking**

Create `tests/test_meta_progression.gd`:

```gdscript
extends GutTest

var _condition: UnlockConditionResource

func test_reach_stage_condition_met() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "reach_stage"
	_condition.condition_params = {"stage": 3}
	var stats := {"stages_reached": 3}
	assert_true(_condition.check(stats))

func test_reach_stage_condition_not_met() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "reach_stage"
	_condition.condition_params = {"stage": 3}
	var stats := {"stages_reached": 2}
	assert_false(_condition.check(stats))

func test_kill_count_condition() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "kill_count"
	_condition.condition_params = {"count": 50}
	assert_true(_condition.check({"enemies_killed": 50}))
	assert_false(_condition.check({"enemies_killed": 49}))

func test_complete_run_condition() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "complete_run"
	assert_true(_condition.check({"run_completed": true}))
	assert_false(_condition.check({"run_completed": false}))

func test_stat_threshold_with_tag_damage() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "stat_threshold"
	_condition.condition_params = {"stat": "damage_by_tag.fire", "threshold": 1000}
	assert_true(_condition.check({"damage_by_tag": {"fire": 1200}}))
	assert_false(_condition.check({"damage_by_tag": {"fire": 500}}))
```

- [ ] **Step 4: Run tests**

Run: GUT panel → Run `tests/test_meta_progression.gd`
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd D:/syntax-breaker
git add scripts/autoloads/meta_progression.gd resources/unlocks/ tests/test_meta_progression.gd
git commit -m "feat: add meta-progression unlock system with 12 unlock conditions"
```

---

## Task 19: Main Menu, Run Summary & Full Integration

**Files:**
- Create: `scripts/ui/main_menu.gd`
- Create: `scenes/ui/main_menu.tscn`
- Create: `scripts/ui/run_summary.gd`
- Create: `scenes/ui/run_summary.tscn`
- Modify: `scripts/main/main.gd`
- Modify: `scripts/main/game_manager.gd`

- [ ] **Step 1: Create MainMenu**

Create `scripts/ui/main_menu.gd`:

```gdscript
class_name MainMenu
extends Control

@onready var start_button: Button = $VBox/StartButton
@onready var title_label: Label = $VBox/TitleLabel

signal start_pressed

func _ready() -> void:
	start_button.pressed.connect(func(): start_pressed.emit())
	title_label.text = "SYNTAX BREAKER"
```

Create `scenes/ui/main_menu.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://main_menu_scene"]

[ext_resource type="Script" path="res://scripts/ui/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -100.0
offset_right = 150.0
offset_bottom = 100.0
alignment = 1

[node name="TitleLabel" type="Label" parent="VBox"]
layout_mode = 2
text = "SYNTAX BREAKER"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 40

[node name="StartButton" type="Button" parent="VBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 60)
text = "Start Run"
```

- [ ] **Step 2: Create RunSummary**

Create `scripts/ui/run_summary.gd`:

```gdscript
class_name RunSummary
extends Control

@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var unlocks_label: Label = $Panel/VBox/UnlocksLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton

signal continue_pressed

func _ready() -> void:
	continue_button.pressed.connect(func(): continue_pressed.emit())

func show_summary(victory: bool, run_stats: Dictionary, new_unlocks: Array[String]) -> void:
	result_label.text = "VICTORY!" if victory else "DEFEATED"
	result_label.modulate = Color.GOLD if victory else Color.RED

	stats_label.text = "Enemies killed: %d\nStages reached: %d\nGold earned: %d" % [
		run_stats.get("enemies_killed", 0),
		run_stats.get("stages_reached", 0),
		RunManager.gold,
	]

	if new_unlocks.is_empty():
		unlocks_label.text = "No new unlocks"
	else:
		unlocks_label.text = "NEW UNLOCKS:\n" + "\n".join(new_unlocks)

	show()
```

Create `scenes/ui/run_summary.tscn`:

```
[gd_scene load_steps=2 format=3 uid="uid://run_summary_scene"]

[ext_resource type="Script" path="res://scripts/ui/run_summary.gd" id="1"]

[node name="RunSummary" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = 100.0
offset_right = -40.0
offset_bottom = -100.0

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 2
alignment = 1

[node name="ResultLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 48

[node name="StatsLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 20

[node name="UnlocksLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 18

[node name="ContinueButton" type="Button" parent="Panel/VBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 60)
text = "Return to Menu"
```

- [ ] **Step 3: Wire everything together in Main**

Update `scripts/main/main.gd`:

```gdscript
extends Node

@onready var game_manager: GameManager = $GameManager

var _main_menu: MainMenu
var _run_summary: RunSummary
var _canvas: CanvasLayer

func _ready() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	_main_menu = preload("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
	_canvas.add_child(_main_menu)
	_main_menu.start_pressed.connect(_on_start_run)

	_run_summary = preload("res://scenes/ui/run_summary.tscn").instantiate() as RunSummary
	_canvas.add_child(_run_summary)
	_run_summary.hide()
	_run_summary.continue_pressed.connect(_on_return_to_menu)

	game_manager.run_completed.connect(_on_run_completed)
	GameBus.player_died.connect(func(): game_manager.end_run(false))

func _on_start_run() -> void:
	_main_menu.hide()
	game_manager.start_run()

func _on_run_completed(victory: bool) -> void:
	var new_unlocks := MetaProgression.check_unlocks(RunManager.run_stats)
	if victory:
		RunManager.run_stats["run_completed"] = true
		new_unlocks.append_array(MetaProgression.check_unlocks(RunManager.run_stats))
	_run_summary.show_summary(victory, RunManager.run_stats, new_unlocks)

func _on_return_to_menu() -> void:
	_run_summary.hide()
	_main_menu.show()
```

- [ ] **Step 4: Update GameManager — handle boss stage and victory**

Edit `scripts/main/game_manager.gd` — update `_advance_to_combat` to mark stages 3 and 5 as boss stages:

```gdscript
func _advance_to_combat() -> void:
	RunManager.advance_stage()
	_state = State.COMBAT
	state_changed.emit(_state)

	if _arena:
		_arena.queue_free()
		await _arena.tree_exited

	_arena = ARENA_SCENE.instantiate() as Arena
	add_child(_arena)
	_arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	var is_boss_stage := RunManager.current_stage == 3 or RunManager.current_stage == 5
	_arena.start_stage(RunManager.current_stage, _skill_instances, is_boss_stage)
```

Update `Arena.start_stage` to accept the boss flag:

```gdscript
func start_stage(stage_number: int, skill_instances: Array[SkillInstance], boss_stage: bool = false) -> void:
	_waves_for_stage = 3 + stage_number
	player.global_position = Vector2(arena_size.x / 2, arena_size.y * 0.7)

	var caster := player.get_node("SkillCaster") as SkillCaster
	caster.set_skills(skill_instances)

	var arena_rect := Rect2(Vector2.ZERO, arena_size)
	spawner.setup(player, arena_rect, _waves_for_stage, boss_stage)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared, CONNECT_ONE_SHOT)
	spawner.start_next_wave()

	if hud and hud.has_method("setup"):
		hud.setup(player)
```

Handle the final boss (stage 5 boss):

```gdscript
func _on_stage_completed() -> void:
	if RunManager.current_stage >= 5:
		end_run(true)
	else:
		_open_shop()
```

- [ ] **Step 5: Full end-to-end test**

Run the game. Verify:
1. Main menu appears with "Start Run" button
2. Tap Start → Stage 1 begins, player can move, fireballs fire
3. Kill enemies → gold drops, HP bar updates
4. Clear all waves → shop opens with items
5. Buy support → manage skills → link support → close shop → Stage 2
6. Stage 3: mini-boss spawns after waves, telegraphs charge
7. Continue through stages 4, 5
8. Stage 5 boss defeated → victory screen with stats and unlocks
9. Return to menu → start another run, new items available in shop
10. Player death → defeat screen → return to menu

- [ ] **Step 6: Commit**

```bash
cd D:/syntax-breaker
git add scripts/ui/main_menu.gd scripts/ui/run_summary.gd scenes/ui/main_menu.tscn scenes/ui/run_summary.tscn scripts/main/main.gd scripts/main/game_manager.gd scripts/stages/arena.gd
git commit -m "feat: add main menu, run summary, and full game loop integration"
```

---

## Post-Implementation Checklist

After all tasks are complete, verify these end-to-end:

- [ ] Full run from menu → 5 stages → boss → victory screen works
- [ ] Player death triggers defeat screen
- [ ] All 6 skills fire correctly (projectile, AoE, orbit)
- [ ] Support linking works in skill manager (link, unlink, re-link)
- [ ] Tag matching prevents invalid support links
- [ ] At least 2 combo builds work (e.g., Fireball + Chain, Poison Dart + Split)
- [ ] Shop items are filtered by meta-progression unlocks
- [ ] Save/load persists unlocks between game sessions
- [ ] Mini-boss appears on stages 3 and 5 with telegraph attack
- [ ] Gold economy works: earn from kills, spend in shop, reroll costs gold
- [ ] Virtual joystick is responsive, floating, left-side only
- [ ] Portrait orientation, touch-friendly UI
- [ ] No crashes or orphan nodes (check Godot debugger for node count)
- [ ] Object pooling working (projectile count doesn't grow unbounded)
- [ ] GUT tests pass: tag matcher, stat calculator, skill instance, object pool, behavior registry, meta progression
