# Mobile-First Evolutions and Memetic Supports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship portrait-mobile terminal difficulty, Rollback, thirteen behavior-changing supports, and three evolution tiers for all seven skills without breaking saves, touch usability, or device performance.

**Architecture:** Extend the current terminal implementation with data-driven encounter tiers and add a separate `EvolutionData` catalog plus explicit evolution state on `SkillInstance`. Derived attacks carry bounded provenance metadata so supports and evolutions compose without recursive loops; each effect remains a focused behavior or effect node registered through existing combat boundaries.

**Tech Stack:** Godot 4.6, GDScript, `.tres` resources, native headless Godot test scenes, Android portrait export.

**Spec:** `docs/superpowers/specs/2026-10-10-mobile-evolutions-supports-design.md`

## Global Constraints

- Target mobile-first top-down 2D at portrait `1080×1920`.
- Keep the saved skill ID `blade_spin`; only its display identity and runtime behavior become Rollback.
- Test-mode terminal difficulties are uniformly random: Compile, Overclock, Kernel Breach.
- A failed terminal is permanently unavailable and grants no reward.
- Evolution tier is constrained to `0..3`; offers never duplicate or downgrade current state.
- Touch targets are at least 96 px at the design resolution and never require hover.
- Device-quality caps remain; cosmetic particles degrade before gameplay objects.
- Derived attacks cannot recursively reproduce themselves without an explicit generation limit.
- Preserve unrelated dirty-worktree changes in `scripts/ui/skill_picker.gd`, `tests/item_art_native.gd`, `tests/skill_picker_touch_native.gd`, and existing untracked docs.
- In every PowerShell test block, first resolve the engine with `$godot = 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'`; stop if that path is absent rather than silently using another engine version.

## Review Focus

- Corrupt or obsolete saved evolution IDs must leave the base skill usable and normalize the tier to zero; Task 3 pins this.
- Exhausted evolution pools must return a legal fallback instead of opening an empty picker; Task 4 pins this.
- Death, stage cleanup, or terminal destruction during a slowed reward transition must restore `Engine.time_scale` and prevent duplicate rewards; Tasks 1 and 4 pin this.
- `Copy / Paste + Reply All + Recursive Rollback` must stop at declared generations and active-object caps; Tasks 2, 6, 8, and 9 pin this.
- Low device quality must preserve one recognizable instance of each gameplay effect while removing cosmetic work first; Tasks 2 and 10 pin this.

---

### Task 1: Stabilize the Existing One-Shot Terminal Baseline

**Files:**
- Modify: `scripts/stages/compilation_terminal.gd`
- Modify: `scripts/stages/arena.gd`
- Modify: `scripts/enemies/spawner.gd`
- Modify: `scripts/ui/compilation_picker.gd`
- Modify: `scripts/combat/mutation_data.gd`
- Modify: `scripts/skills/skill_instance.gd`
- Test: `tests/compilation_terminal_native.gd`
- Test: `tests/compilation_terminal_native.tscn`

**Interfaces:**
- Produces: `CompilationTerminal.activate() -> bool`, `register_wave_kill()`, `spawn_compilation_wave(origin, count) -> int`.
- Produces: one-shot terminal states `READY`, `ACTIVE`, `COMPLETED`, `FAILED` used by Task 4.

- [ ] **Step 1: Extend the existing terminal regression with interrupted-transition coverage**

```gdscript
var interrupted := CompilationTerminalScript.new()
add_child(interrupted)
interrupted.wave_size = 1
check(interrupted.activate(), "Terminal begins before cleanup")
interrupted._fail()
interrupted.register_wave_kill()
check(interrupted.state == CompilationTerminalScript.State.FAILED,
	"Late kills cannot reward a failed terminal")
Engine.time_scale = 0.08
interrupted.queue_free()
await get_tree().process_frame
Engine.time_scale = 1.0
```

- [ ] **Step 2: Run the baseline test and verify the new assertion fails if late kills can complete**

Run:

```powershell
& $godot --headless --path . --scene res://tests/compilation_terminal_native.tscn --log-file .godot/terminal_baseline_red.log
```

Expected: FAIL on the interrupted terminal assertion before the late-event guard is present, or document that the current state guard already satisfies it and retain the test as characterization.

- [ ] **Step 3: Make terminal cleanup idempotent and centralize time-scale restoration**

```gdscript
func _restore_combat_time() -> void:
	Engine.time_scale = 1.0
	_compilation_open = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		_restore_combat_time()
		_clear_transient_effects()
```

Ensure `register_wave_kill()` returns immediately unless state is `ACTIVE`, and reused pooled enemies have `compilation_wave` metadata removed before normal spawning.

- [ ] **Step 4: Run terminal and encounter regressions**

```powershell
& $godot --headless --path . --scene res://tests/compilation_terminal_native.tscn --log-file .godot/terminal_baseline_green.log
& $godot --headless --path . --scene res://tests/encounter_native.tscn --log-file .godot/terminal_encounter_green.log
```

Expected: both exit `0`, with explicit PASS output.

- [ ] **Step 5: Commit only the terminal baseline files**

```powershell
git add scripts/stages/compilation_terminal.gd scripts/stages/arena.gd scripts/enemies/spawner.gd scripts/ui/compilation_picker.gd scripts/combat/mutation_data.gd scripts/skills/skill_instance.gd tests/compilation_terminal_native.gd tests/compilation_terminal_native.tscn
git commit -m "feat: replace forced compilation with one-shot terminal"
```

### Task 2: Add Bounded Derived-Attack Provenance

**Files:**
- Create: `scripts/combat/attack_context.gd`
- Modify: `scripts/skills/skill_instance.gd`
- Modify: `scripts/resources/game_balance.gd`
- Modify: `resources/config/game_balance.tres`
- Test: `tests/attack_context_native.gd`
- Test: `tests/attack_context_native.tscn`

**Interfaces:**
- Produces: `AttackContext.root(skill_id, cast_id)`, `derive(source_id, flag)`, `can_spawn_child(kind, active_count, quality_cap) -> bool`.
- Produces metadata consumed by all support and evolution behaviors in Tasks 6–9.

- [ ] **Step 1: Write a failing native test for generation, flags, and low-quality caps**

```gdscript
var root := AttackContext.root("fireball", 17)
var copy := root.derive("copy_paste", "copied")
check(copy.root_cast_id == 17 and copy.generation == 1, "Child preserves root and increments generation")
check(copy.has_flag("copied"), "Child records copied provenance")
check(not copy.can_derive("copy_paste", "copied"), "Copy cannot recursively copy itself")
check(AttackContext.can_spawn_child("projectile", 19, 20), "Low preset preserves one remaining gameplay slot")
check(not AttackContext.can_spawn_child("projectile", 20, 20), "Low preset enforces gameplay cap")
```

- [ ] **Step 2: Run the test to verify RED**

```powershell
& $godot --headless --path . --scene res://tests/attack_context_native.tscn --log-file .godot/attack_context_red.log
```

Expected: parse failure because `AttackContext` does not exist.

- [ ] **Step 3: Implement the immutable context API**

```gdscript
class_name AttackContext
extends RefCounted

const MAX_GENERATION := 3
var root_cast_id: int
var skill_id: String
var source_chain: Array[String] = []
var flags: Dictionary = {}
var generation := 0

static func root(id: String, cast_id: int) -> AttackContext:
	var context := AttackContext.new()
	context.skill_id = id
	context.root_cast_id = cast_id
	return context

func derive(source_id: String, flag: String) -> AttackContext:
	var child := duplicate_context()
	child.generation += 1
	child.source_chain.append(source_id)
	child.flags[flag] = true
	return child

func can_derive(source_id: String, flag: String) -> bool:
	return generation < MAX_GENERATION and not flags.has(flag) and not source_chain.has(source_id)
```

Add per-quality gameplay caps to `GameBalance`; keep cosmetic counts separate so cosmetics are the first degradation point.

- [ ] **Step 4: Run provenance and damage tests**

```powershell
& $godot --headless --path . --scene res://tests/attack_context_native.tscn --log-file .godot/attack_context_green.log
& $godot --headless --path . --scene res://tests/damage_native.tscn --log-file .godot/attack_context_damage.log
```

Expected: both exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/combat/attack_context.gd scripts/skills/skill_instance.gd scripts/resources/game_balance.gd resources/config/game_balance.tres tests/attack_context_native.gd tests/attack_context_native.tscn
git commit -m "feat: track bounded derived attack provenance"
```

### Task 3: Add Evolution Data, State, and Save Migration

**Files:**
- Create: `scripts/combat/evolution_data.gd`
- Modify: `scripts/skills/skill_instance.gd`
- Modify: `scripts/main/game_manager.gd`
- Modify: `scripts/autoloads/run_manager.gd`
- Test: `tests/evolution_state_native.gd`
- Test: `tests/evolution_state_native.tscn`
- Modify: `tests/run_integrity.gd`

**Interfaces:**
- Produces: `EvolutionData.get_for_skill(skill_id) -> Dictionary`.
- Produces: `SkillInstance.set_evolution(id: String, tier: int) -> bool` and fields `evolution_id`, `evolution_tier`.
- Produces serialized keys `evolution_id` and `evolution_tier` consumed by Task 4 and UI tasks.

- [ ] **Step 1: Write failing tests for upgrade-only state and corrupt saves**

```gdscript
var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
check(fireball.set_evolution("solar_flare", 1), "First evolution applies")
check(not fireball.set_evolution("solar_flare", 1), "Duplicate tier is rejected")
check(not fireball.set_evolution("solar_flare", 0), "Downgrade is rejected")
check(fireball.set_evolution("solar_flare", 3), "Direct tier III upgrade is legal")
check(not fireball.set_evolution("daemon_process", 3), "Wrong-skill evolution is rejected")

var corrupt := {"skill_id": "fireball", "evolution_id": "removed_id", "evolution_tier": 99}
var restored := GameManager.deserialize_skill_entry(corrupt)
check(restored != null and restored.evolution_id.is_empty() and restored.evolution_tier == 0,
	"Invalid saved evolution falls back to a usable base skill")
```

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/evolution_state_native.tscn --log-file .godot/evolution_state_red.log
```

Expected: missing `EvolutionData`, `set_evolution`, and deserialization helper.

- [ ] **Step 3: Implement the catalog and state validation**

```gdscript
class_name EvolutionData
extends RefCounted

const BY_SKILL := {
	"fireball": {"id": "solar_flare", "name": "Solar Flare"},
	"flame_wave": {"id": "firewall_breach", "name": "Firewall Breach"},
	"frost_nova": {"id": "absolute_zero", "name": "Absolute Zero"},
	"lightning_bolt": {"id": "cloud_outage", "name": "Cloud Outage"},
	"poison_dart": {"id": "ransomware", "name": "Ransomware"},
	"static_field": {"id": "daemon_process", "name": "Daemon Process"},
	"blade_spin": {"id": "recursive_rollback", "name": "Recursive Rollback"},
}

static func is_valid_for_skill(skill_id: String, evolution_id: String) -> bool:
	return BY_SKILL.has(skill_id) and BY_SKILL[skill_id].id == evolution_id
```

```gdscript
func set_evolution(id: String, tier: int) -> bool:
	if tier < 1 or tier > 3 or tier <= evolution_tier:
		return false
	if not EvolutionData.is_valid_for_skill(base.id, id):
		return false
	evolution_id = id
	evolution_tier = tier
	recompute(RunManager.owned_passives)
	return true
```

Extract `GameManager.deserialize_skill_entry(entry) -> SkillInstance` from the existing loop so invalid IDs normalize in one testable boundary.

- [ ] **Step 4: Run state and save suites**

```powershell
& $godot --headless --path . --scene res://tests/evolution_state_native.tscn --log-file .godot/evolution_state_green.log
& $godot --headless --path . --scene res://tests/run_integrity.tscn --log-file .godot/evolution_save_green.log
```

Expected: both exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/combat/evolution_data.gd scripts/skills/skill_instance.gd scripts/main/game_manager.gd scripts/autoloads/run_manager.gd tests/evolution_state_native.gd tests/evolution_state_native.tscn tests/run_integrity.gd
git commit -m "feat: persist tiered skill evolutions"
```

### Task 4: Randomize Terminal Difficulty and Generate Upgrade-Only Rewards

**Files:**
- Modify: `scripts/stages/compilation_terminal.gd`
- Modify: `scripts/enemies/spawner.gd`
- Rewrite: `scripts/ui/compilation_picker.gd`
- Modify: `scripts/stages/arena.gd`
- Modify: `scripts/autoloads/run_telemetry.gd`
- Test: `tests/compilation_terminal_native.gd`

**Interfaces:**
- Produces: `CompilationTerminal.Difficulty`, `roll_difficulty(rng)`, `get_encounter_definition()`.
- Produces: `EvolutionData.roll_offers(skills, difficulty, rng) -> Array[Dictionary]`.
- Consumes: Task 3's `SkillInstance.set_evolution` and serialized evolution fields.

- [ ] **Step 1: Add failing seeded distribution, encounter, fallback, and cleanup tests**

```gdscript
var rng := RandomNumberGenerator.new()
rng.seed = 20261010
var counts := [0, 0, 0]
for i in 3000:
	counts[CompilationTerminalScript.roll_difficulty(rng)] += 1
for count in counts:
	check(count >= 900 and count <= 1100, "Test mode exposes each difficulty approximately equally")

var definitions := CompilationTerminalScript.ENCOUNTERS
check(definitions[0].enemy_count == 24 and definitions[0].outside_grace == 3.0, "Compile contract")
check(definitions[1].enemy_count == 32 and definitions[1].outside_grace == 2.0, "Overclock contract")
check(definitions[2].enemy_count == 40 and definitions[2].outside_grace == 1.0, "Kernel contract")

for skill in maxed_skills:
	skill.set_evolution(EvolutionData.get_for_skill(skill.base.id).id, 3)
var fallback := EvolutionData.roll_offers(maxed_skills, 2, rng)
check(fallback.size() == 3 and fallback.all(func(o): return o.type in ["support", "support_slot"]),
	"Exhausted evolution catalog returns legal fallback offers")
```

Also simulate stage cleanup while the picker is open and assert `Engine.time_scale == 1.0` and one telemetry result.

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/compilation_terminal_native.tscn --log-file .godot/terminal_tiers_red.log
```

Expected: missing difficulty enum, definitions, and evolution offers.

- [ ] **Step 3: Implement difficulty data and reward bands**

```gdscript
enum Difficulty { COMPILE, OVERCLOCK, KERNEL_BREACH }
const ENCOUNTERS := [
	{"enemy_count": 24, "elite_count": 0, "miniboss": false, "zone_radius": 260.0, "outside_grace": 3.0, "tiers": [1, 1, 1, 2]},
	{"enemy_count": 32, "elite_count": 3, "miniboss": false, "zone_radius": 220.0, "outside_grace": 2.0, "tiers": [1, 2, 2, 2, 3]},
	{"enemy_count": 40, "elite_count": 4, "miniboss": true, "zone_radius": 180.0, "outside_grace": 1.0, "tiers": [2, 2, 3, 3]},
]

static func roll_difficulty(rng: RandomNumberGenerator) -> Difficulty:
	return rng.randi_range(0, Difficulty.size() - 1)
```

Have `Spawner.spawn_compilation_wave(origin, definition)` return an exact tagged count and spawn the declared elites/miniboss without consuming normal stage budget. Display rolled difficulty before proximity activation.

- [ ] **Step 4: Run terminal, telemetry, route, and touch suites**

```powershell
& $godot --headless --path . --scene res://tests/compilation_terminal_native.tscn --log-file .godot/terminal_tiers_green.log
& $godot --headless --path . --scene res://tests/telemetry_native.tscn --log-file .godot/terminal_telemetry.log
& $godot --headless --path . --scene res://tests/node_routes_native.tscn --log-file .godot/terminal_routes.log
& $godot --headless --path . --scene res://tests/test_controls_native.tscn --log-file .godot/terminal_touch.log
```

Expected: all exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/stages/compilation_terminal.gd scripts/enemies/spawner.gd scripts/ui/compilation_picker.gd scripts/stages/arena.gd scripts/autoloads/run_telemetry.gd scripts/combat/evolution_data.gd tests/compilation_terminal_native.gd
git commit -m "feat: scale terminal risk and evolution rewards"
```

### Task 5: Replace Blade Spin with Rollback

**Files:**
- Create: `scripts/skills/rollback.gd`
- Create: `scenes/skills/rollback.tscn`
- Modify: `resources/skills/blade_spin.tres`
- Modify: `scripts/skills/skill_caster.gd`
- Create: `assets/icons/skills/rollback-v1.png`
- Test: `tests/rollback_native.gd`
- Test: `tests/rollback_native.tscn`

**Interfaces:**
- Produces: `Rollback.initialize(si, direction, pool, context)`, state enum `OUTBOUND`, `TURNING`, `RETURNING`, `CAUGHT`.
- Produces: `get_recorded_path()` and `get_ordered_hits()` consumed by Undo History and Recursive Rollback.

- [ ] **Step 1: Write failing state-machine and moving-owner tests**

```gdscript
var rollback := preload("res://scenes/skills/rollback.tscn").instantiate()
add_child(rollback)
rollback.initialize(skill, Vector2.RIGHT, null, AttackContext.root("blade_spin", 1))
rollback.set_owner_node(player)
rollback.advance_simulation(0.6)
check(rollback.state == Rollback.State.RETURNING, "Rollback turns at maximum range")
player.position = Vector2(0, 120)
rollback.advance_simulation(0.6)
check(rollback.state == Rollback.State.CAUGHT, "Return trajectory follows the moving owner")
check(dummy.outbound_hits == 1 and dummy.return_hits == 1, "A target can be hit once in each direction")
```

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/rollback_native.tscn --log-file .godot/rollback_red.log
```

Expected: missing Rollback scene/script.

- [ ] **Step 3: Implement the explicit state machine and preserve the resource ID**

```gdscript
func _physics_process(delta: float) -> void:
	match state:
		State.OUTBOUND:
			_travel_outbound(delta)
		State.TURNING:
			state = State.RETURNING
		State.RETURNING:
			_travel_toward_owner(delta)
		State.CAUGHT:
			_release_to_pool()
```

Set the resource display name to `Rollback`, tags to `projectile`, `aoe`, `physical`, and scene path to `res://scenes/skills/rollback.tscn`; retain `id = "blade_spin"`.

- [ ] **Step 4: Run Rollback, build-option, catalog, and save tests**

```powershell
& $godot --headless --path . --scene res://tests/rollback_native.tscn --log-file .godot/rollback_green.log
& $godot --headless --path . --scene res://tests/damage_native.tscn --log-file .godot/rollback_damage.log
& $godot --headless --path . --scene res://tests/catalog_native.tscn --log-file .godot/rollback_catalog.log
& $godot --headless --path . --scene res://tests/run_integrity.tscn --log-file .godot/rollback_save.log
```

Expected: all exit `0` and old saved `blade_spin` entries load as Rollback.

- [ ] **Step 5: Commit**

```powershell
git add scripts/skills/rollback.gd scenes/skills/rollback.tscn resources/skills/blade_spin.tres scripts/skills/skill_caster.gd assets/icons/skills/rollback-v1.png tests/rollback_native.gd tests/rollback_native.tscn
git commit -m "feat: replace blade spin with rollback boomerang"
```

### Task 6: Add Cast and Projectile Universal Supports

**Files:**
- Create: `scripts/behaviors/copy_paste_behavior.gd`
- Create: `scripts/behaviors/spaghetti_code_behavior.gd`
- Create: `scripts/behaviors/works_on_my_machine_behavior.gd`
- Create: `resources/supports/copy_paste.tres`
- Create: `resources/supports/spaghetti_code.tres`
- Create: `resources/supports/works_on_my_machine.tres`
- Create: `assets/icons/supports/copy_paste-v1.png`
- Create: `assets/icons/supports/spaghetti_code-v1.png`
- Create: `assets/icons/supports/works_on_my_machine-v1.png`
- Modify: `scripts/autoloads/behavior_registry.gd`
- Modify: `scripts/skills/skill_caster.gd`
- Modify: `scripts/skills/projectile_base.gd`
- Test: `tests/memetic_supports_native.gd`
- Test: `tests/memetic_supports_native.tscn`

**Interfaces:**
- Consumes: Task 2 `AttackContext` and Task 5 projectile initialization.
- Produces registered behavior keys `copy_paste`, `spaghetti_code`, `works_on_my_machine`.

- [ ] **Step 1: Write failing behavior tests**

```gdscript
check(simulate_copy_paste(1).spawn_count == 2, "Copy / Paste repeats one eligible cast")
check(simulate_copy_paste(3).spawn_count == 2, "Copied cast cannot copy itself")
var redirect := simulate_spaghetti(4)
check(redirect.unique_targets == 4 and redirect.damage_steps == [1.0, 1.25, 1.5, 1.75],
	"Spaghetti Code redirects with bounded growth")
for seed in 64:
	var mode := roll_works_mode(seed)
	check(mode in ["size", "projectiles", "critical", "cooldown"], "Works on My Machine has no penalty mode")
```

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/memetic_supports_native.tscn --log-file .godot/memetic_cast_red.log
```

Expected: missing resources and behaviors.

- [ ] **Step 3: Implement behaviors with provenance guards**

```gdscript
func on_cast(skill_instance, cast: Dictionary) -> void:
	var context: AttackContext = cast.context
	if not context.can_derive("copy_paste", "copied"):
		return
	skill_instance.request_recast.call_deferred(cast.direction, context.derive("copy_paste", "copied"))
```

Add `var request_recast: Callable` to `SkillInstance`; `SkillCaster.set_skills()` assigns a callable
that routes the original skill, direction, and derived context through the normal cast path. Spaghetti
Code uses a per-projectile visited-target list and a fixed redirect cap. Works on My Machine rolls once
at root cast creation and stores the mode in cast metadata inherited by every child.

- [ ] **Step 4: Run support, damage, and projectile-cap tests**

```powershell
& $godot --headless --path . --scene res://tests/memetic_supports_native.tscn --log-file .godot/memetic_cast_green.log
& $godot --headless --path . --scene res://tests/damage_native.tscn --log-file .godot/memetic_cast_damage.log
& $godot --headless --path . --scene res://tests/returning_performance_native.tscn --log-file .godot/memetic_cast_caps.log
```

Expected: all exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/behaviors/copy_paste_behavior.gd scripts/behaviors/spaghetti_code_behavior.gd scripts/behaviors/works_on_my_machine_behavior.gd resources/supports/copy_paste.tres resources/supports/spaghetti_code.tres resources/supports/works_on_my_machine.tres assets/icons/supports/copy_paste-v1.png assets/icons/supports/spaghetti_code-v1.png assets/icons/supports/works_on_my_machine-v1.png scripts/autoloads/behavior_registry.gd scripts/skills/skill_caster.gd scripts/skills/projectile_base.gd tests/memetic_supports_native.gd tests/memetic_supports_native.tscn
git commit -m "feat: add cast and projectile memetic supports"
```

### Task 7: Add Target-State Universal Supports

**Files:**
- Create: `scripts/behaviors/lag_spike_behavior.gd`
- Create: `scripts/behaviors/alt_f4_behavior.gd`
- Create: `scripts/behaviors/rubber_duck_behavior.gd`
- Create: `resources/supports/lag_spike.tres`
- Create: `resources/supports/alt_f4.tres`
- Create: `resources/supports/rubber_duck.tres`
- Create: `assets/icons/supports/lag_spike-v1.png`
- Create: `assets/icons/supports/alt_f4-v1.png`
- Create: `assets/icons/supports/rubber_duck-v1.png`
- Modify: `scripts/autoloads/behavior_registry.gd`
- Modify: `scripts/enemies/enemy_base.gd`
- Modify: `tests/memetic_supports_native.gd`

**Interfaces:**
- Consumes: Task 2 provenance metadata.
- Produces enemy APIs `apply_debugged(duration, multiplier, source)` and `is_execution_protected()`.

- [ ] **Step 1: Add failing tests for thresholds, boss treatment, delayed recursion, and streak reset**

```gdscript
check(not execute_at_ratio(normal, 0.121), "Alt + F4 does not execute above 12%")
check(execute_at_ratio(normal, 0.12), "Alt + F4 executes a normal enemy at 12%")
check(not execute_at_ratio(boss, 0.031), "Boss survives above 3%")
check(execute_at_ratio(boss, 0.03), "Eligible boss executes at 3%")
check(simulate_lag_spike().damage_events == 2, "Lag Spike repeats damage once")
check(simulate_lag_spike().derived_events == 1, "Delayed hit cannot schedule another Lag Spike")
check(simulate_duck_hits([a, a, b, a, a, a]).debugged_targets == [a], "Changing target resets the streak")
```

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/memetic_supports_native.tscn --log-file .godot/memetic_target_red.log
```

- [ ] **Step 3: Implement bounded target state and visible duck marker**

Use an enemy metadata dictionary keyed by source skill ID for streaks and debug duration. Apply a boss-duration multiplier, honor scripted invulnerability, and attribute execute/delayed damage to the support source.

```gdscript
func is_execution_protected() -> bool:
	return get_meta("scripted_invulnerable", false) or not is_alive()

func apply_debugged(duration: float, multiplier: float, source: String) -> void:
	_debugged_remaining = maxf(_debugged_remaining, duration)
	_debugged_multiplier = maxf(_debugged_multiplier, multiplier)
	_debugged_source = source
```

- [ ] **Step 4: Run support, boss, and damage tests**

```powershell
& $godot --headless --path . --scene res://tests/memetic_supports_native.tscn --log-file .godot/memetic_target_green.log
& $godot --headless --path . --scene res://tests/boss_native.tscn --log-file .godot/memetic_target_boss.log
& $godot --headless --path . --scene res://tests/damage_native.tscn --log-file .godot/memetic_target_damage.log
```

- [ ] **Step 5: Commit**

```powershell
git add scripts/behaviors/lag_spike_behavior.gd scripts/behaviors/alt_f4_behavior.gd scripts/behaviors/rubber_duck_behavior.gd resources/supports/lag_spike.tres resources/supports/alt_f4.tres resources/supports/rubber_duck.tres assets/icons/supports/lag_spike-v1.png assets/icons/supports/alt_f4-v1.png assets/icons/supports/rubber_duck-v1.png scripts/autoloads/behavior_registry.gd scripts/enemies/enemy_base.gd tests/memetic_supports_native.gd
git commit -m "feat: add target-state memetic supports"
```

### Task 8: Add Seven Signature Supports

**Files:**
- Create: `scripts/behaviors/firewall_behavior.gd`
- Create: `scripts/behaviors/reply_all_behavior.gd`
- Create: `scripts/behaviors/frozen_process_behavior.gd`
- Create: `scripts/behaviors/wifi_extender_behavior.gd`
- Create: `scripts/behaviors/malware_behavior.gd`
- Create: `scripts/behaviors/background_process_behavior.gd`
- Create: `scripts/behaviors/undo_history_behavior.gd`
- Create: `resources/supports/{firewall,reply_all,frozen_process,wifi_extender,malware,background_process,undo_history}.tres`
- Create: `assets/icons/supports/{firewall,reply_all,frozen_process,wifi_extender,malware,background_process,undo_history}-v1.png`
- Modify: `scripts/autoloads/behavior_registry.gd`
- Modify: `scripts/skills/skill_instance.gd`
- Test: `tests/signature_supports_native.gd`
- Test: `tests/signature_supports_native.tscn`

**Interfaces:**
- Consumes: Tasks 2, 5–7 attack context and Rollback history.
- Produces seven behavior keys matching the resource filenames.

- [ ] **Step 1: Write one failing contract per signature support**

```gdscript
check(firewall_segments_for_one_impact() == 1, "Firewall connects caster and impact once")
check(reply_all_children_after_many_hits() == 1, "Reply All emits once per root cast")
check(frozen_process_repeat_damage() == stored_damage, "Frozen Process repeats stored damage on thaw")
check(wifi_chain_ranges() == [base, base * 1.25, base * 1.5], "Wi-Fi Extender grows chain range")
check(malware_damage_after_actions(3) > malware_damage_after_actions(0), "Malware grows when host acts")
check(background_process_ghosts_after_expiry() == 1, "Background Process leaves one bounded ghost")
check(undo_history_path() == outbound_path.duplicate().reversed(), "Undo History retraces exact path")
```

Add a composite test with Copy / Paste, Reply All, and Recursive Rollback metadata and assert total generations never exceed `AttackContext.MAX_GENERATION` and live child effects never exceed the configured cap.

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/signature_supports_native.tscn --log-file .godot/signature_supports_red.log
```

- [ ] **Step 3: Implement focused behavior scripts and resources**

Each behavior accepts only its required base skill ID in addition to tag compatibility. Use provenance flags `firewall`, `reply_all_child`, `stored_frost`, `wifi_extended`, `malware_tick`, `background_ghost`, and `undo_retrace` so each behavior can reject its own derived effects.

```gdscript
func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID
```

- [ ] **Step 4: Run signature, build-options, catalog, and balance tests**

```powershell
& $godot --headless --path . --scene res://tests/signature_supports_native.tscn --log-file .godot/signature_supports_green.log
& $godot --headless --path . --scene res://tests/damage_native.tscn --log-file .godot/signature_damage.log
& $godot --headless --path . --scene res://tests/catalog_native.tscn --log-file .godot/signature_catalog.log
& $godot --headless --path . --scene res://tests/balance_native.tscn --log-file .godot/signature_balance.log
```

- [ ] **Step 5: Commit**

```powershell
git add scripts/behaviors resources/supports assets/icons/supports scripts/autoloads/behavior_registry.gd scripts/skills/skill_instance.gd tests/signature_supports_native.gd tests/signature_supports_native.tscn
git commit -m "feat: add signature support for every skill"
```

### Task 9: Implement Three Evolution Tiers for All Skills

**Files:**
- Create: `scripts/evolutions/evolution_behavior.gd`
- Create: `scripts/evolutions/{solar_flare,firewall_breach,absolute_zero,cloud_outage,ransomware,daemon_process,recursive_rollback}.gd`
- Modify: `scripts/combat/evolution_data.gd`
- Modify: `scripts/skills/skill_instance.gd`
- Modify: `scripts/enemies/enemy_base.gd`
- Modify: `scripts/util/combat_log.gd`
- Test: `tests/evolutions_native.gd`
- Test: `tests/evolutions_native.tscn`

**Interfaces:**
- Consumes: `SkillInstance.evolution_id`, `evolution_tier`, Task 2 context, and Task 5 Rollback history.
- Produces lifecycle hooks `on_cast`, `on_spawn`, `on_hit`, `on_kill`, `on_expire` on `EvolutionBehavior`.

- [ ] **Step 1: Write tier-by-tier failing behavior tests**

```gdscript
check(simulate("solar_flare", 1).suns == 1, "Solar I creates one sun")
check(simulate("solar_flare", 2).sun_shots > 0, "Solar II fires from the sun")
check(simulate("solar_flare", 3).supernovas == 1, "Solar III expires in one supernova")
check(simulate("firewall_breach", 3).crossing_walls >= 2, "Firewall III crosses the arena")
check(simulate("absolute_zero", 3).max_generation <= 3, "Absolute Zero propagation is bounded")
check(simulate("cloud_outage", 3).network_pulses == 1, "Cloud III pulses the rod network")
check(not simulate_hijack(boss), "Ransomware never hijacks bosses")
check(simulate_hijack(elite).duration > 0.0, "Ransomware III hijacks eligible elites")
check(simulate("daemon_process", 3).child_fields <= configured_field_cap, "Daemon children respect cap")
check(simulate("recursive_rollback", 3).child_boomerangs == 2, "Rollback III launches two children")
```

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/evolutions_native.tscn --log-file .godot/evolutions_red.log
```

- [ ] **Step 3: Implement the base behavior boundary and seven focused scripts**

```gdscript
class_name EvolutionBehavior
extends RefCounted

var tier := 0
func configure(value: int) -> void:
	tier = clampi(value, 0, 3)
func on_cast(_skill: SkillInstance, _cast: Dictionary) -> void: pass
func on_hit(_skill: SkillInstance, _target: Node2D, _attack: Node2D) -> void: pass
func on_kill(_skill: SkillInstance, _target: Node2D, _attack: Node2D) -> void: pass
func on_expire(_skill: SkillInstance, _effect: Node2D) -> void: pass
```

`SkillInstance._rebuild_behaviors()` instantiates exactly one compatible evolution behavior and sends it the same lifecycle notifications as supports. Each child effect derives context with its evolution ID and refuses its own flag.

- [ ] **Step 4: Run evolution, composite recursion, damage, boss, and balance suites**

```powershell
& $godot --headless --path . --scene res://tests/evolutions_native.tscn --log-file .godot/evolutions_green.log
& $godot --headless --path . --scene res://tests/signature_supports_native.tscn --log-file .godot/evolution_composites.log
& $godot --headless --path . --scene res://tests/damage_native.tscn --log-file .godot/evolution_damage.log
& $godot --headless --path . --scene res://tests/boss_native.tscn --log-file .godot/evolution_boss.log
& $godot --headless --path . --scene res://tests/balance_native.tscn --log-file .godot/evolution_balance.log
```

- [ ] **Step 5: Commit**

```powershell
git add scripts/evolutions scripts/combat/evolution_data.gd scripts/skills/skill_instance.gd scripts/enemies/enemy_base.gd scripts/util/combat_log.gd tests/evolutions_native.gd tests/evolutions_native.tscn
git commit -m "feat: add three-tier evolutions for every skill"
```

### Task 10: Build Portrait Evolution UI and the Touch Test Gallery

**Files:**
- Modify: `scripts/ui/compilation_picker.gd`
- Modify: `scripts/ui/skill_manager.gd`
- Create: `scripts/debug/evolution_gallery.gd`
- Create: `scenes/debug/evolution_gallery.tscn`
- Create: `tests/evolution_ui_touch_native.gd`
- Create: `tests/evolution_ui_touch_native.tscn`
- Modify: `tests/combat_readability_native.gd`

**Interfaces:**
- Consumes: Task 4 offer dictionaries `{type, skill_index, evolution_id, current_tier, offered_tier, name, description}`.
- Produces: developer gallery selectors for skill, support set, tier, terminal difficulty, formation, and density.

- [ ] **Step 1: Write failing touch and low-quality identity tests**

```gdscript
var cards := find_offer_buttons(picker)
check(cards.size() == 3, "Evolution picker shows exactly three legal offers")
for card in cards:
	check(card.size.y >= 96.0, "Every portrait offer has a 96 px touch target")
	check(card.tooltip_text.is_empty(), "Critical information never depends on hover")
check(find_text(picker, "II → III"), "Upgrade card shows current-to-new tier")

QualitySettings.current_preset = "low"
gallery.show_effect("recursive_rollback", 3)
check(gallery.count_gameplay_effects("rollback") >= 1, "Low preset preserves mechanic identity")
check(gallery.count_gameplay_effects("rollback") <= QualitySettings.projectile_cap,
	"Low preset obeys gameplay cap")
```

- [ ] **Step 2: Run RED**

```powershell
& $godot --headless --path . --scene res://tests/evolution_ui_touch_native.tscn --log-file .godot/evolution_ui_red.log
```

- [ ] **Step 3: Implement portrait cards and gallery controls**

Build cards with existing `UITheme` styles, fixed minimum height `120`, wrapped descriptions, visible tier badges, skill artwork, and no hover-only content. Gallery controls are large buttons/dropdowns in a vertical scroll container and invoke production resources.

```gdscript
func format_tier_transition(current: int, offered: int) -> String:
	return "%s → %s" % [EvolutionData.roman(current), EvolutionData.roman(offered)]
```

- [ ] **Step 4: Run touch, readability, skill-manager, and item-art suites**

```powershell
& $godot --headless --path . --scene res://tests/evolution_ui_touch_native.tscn --log-file .godot/evolution_ui_green.log
& $godot --headless --path . --scene res://tests/combat_readability_native.tscn --log-file .godot/evolution_readability.log
& $godot --headless --path . --scene res://tests/skill_manager_art_native.tscn --log-file .godot/evolution_manager.log
& $godot --headless --path . --scene res://tests/item_art_native.tscn --log-file .godot/evolution_art.log
```

- [ ] **Step 5: Commit**

```powershell
git add scripts/ui/compilation_picker.gd scripts/ui/skill_manager.gd scripts/debug/evolution_gallery.gd scenes/debug/evolution_gallery.tscn tests/evolution_ui_touch_native.gd tests/evolution_ui_touch_native.tscn tests/combat_readability_native.gd
git commit -m "feat: add portrait evolution UI and touch gallery"
```

### Task 11: Full Verification, Android Export, and Phone Installation

**Files:**
- Modify: `docs/phone-playtest-protocol.md`
- Create: `docs/progress-2026-10-10.md`
- Modify only if required by verified export: `export_presets.cfg`

**Interfaces:**
- Consumes: all previous tasks.
- Produces: signed Android artifact, installed phone build, hash, and recorded manual results.

- [ ] **Step 1: Run project parse and every relevant native suite from a clean Godot process**

```powershell
& $godot --headless --path . --editor --quit --log-file .godot/evolutions_project_check.log
$scenes = @(
  'attack_context_native','evolution_state_native','compilation_terminal_native','rollback_native',
  'memetic_supports_native','signature_supports_native','evolutions_native','evolution_ui_touch_native',
  'encounter_native','damage_native','boss_native','run_integrity','node_routes_native','catalog_native',
  'balance_native','combat_readability_native','returning_performance_native'
)
foreach ($scene in $scenes) {
  & $godot --headless --path . --scene "res://tests/$scene.tscn" --log-file ".godot/${scene}_final.log"
  if ($LASTEXITCODE -ne 0) { throw "$scene failed with $LASTEXITCODE" }
}
```

Expected: project parse exits `0`; every suite exits `0`; balance reports no invalid combinations or final-stat-limit violations.

- [ ] **Step 2: Export the portrait Android build**

```powershell
& $godot --headless --path . --export-debug "Android" builds/SyntaxBreaker-evolutions.apk --log-file .godot/evolutions_android_export.log
if ($LASTEXITCODE -ne 0) { throw "Android export failed" }
Get-FileHash -Algorithm SHA256 builds/SyntaxBreaker-evolutions.apk
```

Expected: APK exists, export exits `0`, and a SHA-256 hash is printed.

- [ ] **Step 3: Install the exact APK on the connected test phone**

```powershell
adb devices
adb install -r builds/SyntaxBreaker-evolutions.apk
adb shell pm path org.godotengine.syntaxbreaker
```

Expected: one authorized device, `Success`, and a package path. If the application ID differs, read the exported manifest with `apkanalyzer manifest application-id` and use that exact ID.

- [ ] **Step 4: Run the manual portrait gallery protocol**

Verify on device:

1. All three terminal difficulties appear and are readable before activation.
2. Every offer card is selectable without accidental neighboring taps.
3. Rollback remains visible outbound and returning behind thumbs.
4. Each of thirteen supports has a distinguishable effect.
5. Each evolution tier I–III is visually distinguishable.
6. The densest Kernel Breach combination completes without a stuck wave, runaway recursion, or input loss.
7. Record frame-time/thermal observation for a sustained 10-minute gallery loop and note the quality preset.

- [ ] **Step 5: Record evidence and commit verification docs**

```powershell
git add docs/phone-playtest-protocol.md docs/progress-2026-10-10.md builds/SyntaxBreaker-evolutions.apk builds/SyntaxBreaker-evolutions.apk.idsig
git commit -m "test: verify evolutions milestone on Android"
```

Do not claim device completion if no authorized phone was connected or any manual checklist item remains unobserved; record that exact gap instead.
