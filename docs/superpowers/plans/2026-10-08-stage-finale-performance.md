# Stage Finale and Completion Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make stage completion bounded and turn the final regional stage into a boss-only, three-phase encounter that ends immediately on boss death.

**Architecture:** `Spawner` owns encounter lifecycle and exposes one idempotent completion boundary. `RegionalBoss` owns phase/attack selection, while a focused projectile-volley helper owns hostile bullet creation and cleanup. `Arena` performs one bounded transient-effects cleanup before emitting its completion signal.

**Tech Stack:** Godot 4.6.2, GDScript, native headless scene tests, Android debug export.

**Spec:** `docs/superpowers/specs/2026-10-08-stage-finale-art-shop-design.md`

## Global Constraints

- Preserve existing player saves and regional identities.
- Final stages spawn no ordinary waves; mechanic adds are capped at four and never gate victory.
- Boss death completes the map exactly once and clears adds, hostile projectiles, hazards, and deferred spawns.
- Final boss uses approximately 5x stage-scaled HP, approximately 25% more movement than the current configuration, a 35–45% larger visual footprint, and phases at 65% and 30% HP.
- Every damaging boss action retains a harmless warning; active hazards remain capped.
- Real-device observation is required for the reported end-of-stage hitch.

## Review Focus

- Boss and final add dying in the same physics frame must emit completion and rewards once; Task 2 tests the simultaneous callback path.
- A deferred split/add callback after completion must not recreate an enemy; Task 1 tests generation invalidation.
- Forced/debug completion during a final boss fight must clear the boss without awarding boss points; Task 1 tests cleanup-versus-death semantics.
- Player death on the same frame as boss death must follow the existing game-manager terminal-state guard; Task 2 pins the accepted precedence.
- Projectile volleys at arena edges must stay in bounds long enough to be readable and must always release; Task 3 tests edge origins and pool cleanup.

---

### Task 1: Idempotent bounded encounter cleanup

**Files:**
- Modify: `scripts/enemies/spawner.gd`
- Modify: `scripts/stages/arena.gd`
- Modify: `scripts/effects/hit_effect.gd`
- Modify: `scripts/effects/aftermath_effect.gd`
- Modify: `scripts/effects/death_effect.gd`
- Modify: `scripts/ui/damage_number.gd`
- Test: `tests/encounter_native.gd`

**Interfaces:**
- Produces: `Spawner.complete_encounter(reason: String, boss_killed: bool = false) -> bool`
- Produces: `Spawner.clear_transients() -> void`
- Consumes: existing effect `clear_all()` methods and pool `release_all()` semantics.

- [ ] **Step 1: Write the failing lifecycle tests**

Add a focused fixture to `tests/encounter_native.gd`:

```gdscript
var completions := 0
spawner.all_waves_cleared.connect(func(): completions += 1)
spawner._pending_split_fragments = 2
var old_generation := spawner._spawn_generation
check(spawner.complete_encounter("cleared"), "First completion owns the transition")
check(not spawner.complete_encounter("cleared"), "Repeated completion is ignored")
spawner._materialize_split_fragments(Vector2.ZERO, 2, old_generation, false, 0)
check(completions == 1 and spawner._pending_split_fragments == 0,
	"Completion emits once and invalidates deferred fragments")
check(spawner.get_remaining_enemies() == 0, "Completion leaves no active encounter entities")
```

Also construct one active hostile projectile/hazard/effect and assert `Arena._on_all_waves_cleared()` clears each collection without invoking enemy `_die()` rewards.

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
& $godot --headless --path . --scene res://tests/encounter_native.tscn --log-file .godot/finale_cleanup_red.log
```

Expected: FAIL because `complete_encounter` and bounded transient cleanup do not exist.

- [ ] **Step 3: Implement the single completion boundary**

In `Spawner`:

```gdscript
func complete_encounter(_reason: String, boss_killed: bool = false) -> bool:
	if _completed:
		return false
	_completed = true
	_active = false
	_suppress_split_spawns = true
	_spawn_generation += 1
	_pending_split_fragments = 0
	_pending_boss_add_requests.clear()
	clear_transients()
	all_waves_cleared.emit()
	return true

func clear_transients() -> void:
	for pool: Array in _pools.values():
		for enemy: Node in pool.duplicate():
			if is_instance_valid(enemy) and enemy.visible:
				_release_enemy_without_rewards(enemy)
	_enemies_alive = 0
	_active_role_counts.clear()
```

Route `_complete_stage()` and `force_complete()` through this function. Keep reward-bearing boss death separate via `boss_killed` so force cleanup never grants boss credit. In `Arena`, call each global transient `clear_all()` once before emitting `stage_completed`.

- [ ] **Step 4: Run focused tests GREEN**

Run the encounter, telemetry, node-route, and returning native scenes. Expected: all exit 0 and their logs contain no `SCRIPT ERROR` or non-certificate `ERROR:`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/enemies/spawner.gd scripts/stages/arena.gd scripts/effects scripts/ui/damage_number.gd tests/encounter_native.gd
git commit -m "perf: bound stage completion cleanup"
```

### Task 2: Boss-only final-stage victory flow

**Files:**
- Modify: `scripts/enemies/spawner.gd`
- Modify: `scripts/enemies/regional_boss.gd`
- Modify: `scripts/main/game_manager.gd`
- Modify: `tests/boss_native.gd`
- Modify: `tests/node_routes_native.gd`

**Interfaces:**
- Consumes: `Spawner.complete_encounter(reason, boss_killed)` from Task 1.
- Produces: `Spawner.is_final_boss_encounter() -> bool`
- Produces: `RegionalBoss.final_defeated` signal.

- [ ] **Step 1: Write failing boss-only and immediate-victory tests**

Add final-depth `StageData` fixtures and assert:

```gdscript
spawner.setup(player, arena_rect, final_stage)
spawner.start_next_wave()
spawner._process(20.0)
check(spawner._spawned_count == 0, "Final boss stage never spawns ordinary waves")
check(spawner.get_children().filter(func(n): return n.get_meta("combat_role", "") == "boss").size() == 1,
	"Final encounter starts with exactly one boss")
boss.take_damage(boss.current_hp + 1.0)
check(completions == 1, "Boss death immediately completes final map")
check(spawner.get_remaining_enemies() == 0, "Mechanic adds do not gate final victory")
```

Trigger add death and boss death in the same frame and assert one completion. Add a `GameManager` route assertion that player death already accepted before boss death retains the loss state.

- [ ] **Step 2: Run tests and verify RED**

Expected failures: ordinary pulses still spawn and completion remains timer/enemy-count gated.

- [ ] **Step 3: Implement final encounter mode**

Set `_is_final_boss_stage = _is_boss_stage and _stage_depth >= 10`. In `_process`, bypass timer/pulse spawning for this mode. Connect the regional boss death through a dedicated callback:

```gdscript
func _on_final_boss_died(_boss: EnemyBase) -> void:
	if complete_encounter("boss_defeated", true):
		for child: Node in get_children():
			if child is EnemyBase and child.get_meta("combat_role", "") != "boss":
				_release_enemy_without_rewards(child)
```

Keep mechanic add reservation capped at four, and cancel all outstanding add requests during completion.

- [ ] **Step 4: Run boss and route tests GREEN**

Run `boss_native.tscn`, `node_routes_native.tscn`, `encounter_native.tscn`, and `telemetry_native.tscn`. Expected: all pass with one terminal transition.

- [ ] **Step 5: Commit**

```powershell
git add scripts/enemies/spawner.gd scripts/enemies/regional_boss.gd scripts/main/game_manager.gd tests/boss_native.gd tests/node_routes_native.gd
git commit -m "feat: make final map a boss-only encounter"
```

### Task 3: Three-phase boss movement and avoidable projectile volleys

**Files:**
- Create: `scripts/enemies/boss_projectile_volley.gd`
- Create: `scenes/enemies/boss_projectile_volley.tscn`
- Modify: `scripts/enemies/regional_boss.gd`
- Modify: `scripts/enemies/spawner.gd`
- Modify: `scripts/enemies/boss_hazard.gd`
- Modify: `tests/boss_native.gd`
- Modify: `tests/combat_readability_native.gd`

**Interfaces:**
- Produces: `BossProjectileVolley.spawn(parent: Node, origin: Vector2, target: Vector2, pattern: String, count: int, speed: float, damage: float, source: String) -> Array[EnemyProjectile]`
- Consumes: existing `EnemyProjectile.setup(direction, damage, ...)` contract or extends it with explicit lifetime/range while preserving normal ranged enemies.

- [ ] **Step 1: Write failing phase, scale, movement, and volley tests**

Assert phase thresholds, visual scale/hitbox independence, final scaling, cooldown progression, projectile count/cap, edge cleanup, and regional pattern selection:

```gdscript
boss.configure_encounter(10)
check(boss.phase_index == 1, "Final boss starts in phase one")
boss.current_hp = boss.max_hp * 0.64
boss._physics_process(0.01)
check(boss.phase_index == 2, "Phase two begins below 65 percent")
boss.current_hp = boss.max_hp * 0.29
boss._physics_process(0.01)
check(boss.phase_index == 3, "Phase three begins below 30 percent")
check(boss._sprite.scale.x >= 1.35 and boss.get_node("CollisionShape2D").scale.x < boss._sprite.scale.x,
	"Final boss is visibly larger without proportional hitbox inflation")
```

Spawn a volley at each arena edge, advance until expiry, and assert all projectiles release and never exceed the configured cap.

- [ ] **Step 2: Run tests and verify RED**

Expected: two-phase state, missing volley helper, current slow boss scaling, and missing opacity contract.

- [ ] **Step 3: Implement phase state and shared volley helper**

Use `phase_index` values 1–3 and a data table per region:

```gdscript
const PHASE_COOLDOWNS := [4.0, 3.1, 2.4]
const VOLLEY_COUNTS := [5, 7, 9]

func _update_phase() -> void:
	var ratio := current_hp / maxf(1.0, max_hp)
	var next_phase := 3 if ratio <= 0.30 else (2 if ratio <= 0.65 else 1)
	if next_phase != phase_index:
		phase_index = next_phase
		announce_phase()
```

Alternate the existing regional hazard attack with aimed fan/spiral volleys. Use opaque cores, telegraphed emission points, fixed lifetimes, z-index above hazards, and a hard active-projectile cap. Configure final boss art scale to 1.4, collision scale to at most 1.15, spawn scaling HP to 5.0, and speed to 1.0 relative to stage speed (replacing the current 0.8 multiplier).

- [ ] **Step 4: Reduce active ground fill opacity without weakening warnings**

In `boss_hazard.gd`, centralize colors:

```gdscript
const ACTIVE_FILL_ALPHA := 0.18
const ACTIVE_BORDER_ALPHA := 0.72
const WARNING_FILL_ALPHA := 0.24
```

Keep warning outlines and activation flash at their present or higher contrast; only lower persistent fill alpha.

- [ ] **Step 5: Run focused tests GREEN**

Run boss, combat-readability, encounter, and player-shield tests. Expected: all pass; projectile cores remain alpha >= 0.99 and every warning precedes damage.

- [ ] **Step 6: Commit**

```powershell
git add scripts/enemies/boss_projectile_volley.gd scenes/enemies/boss_projectile_volley.tscn scripts/enemies/regional_boss.gd scripts/enemies/spawner.gd scripts/enemies/boss_hazard.gd tests/boss_native.gd tests/combat_readability_native.gd
git commit -m "feat: expand final boss phases and projectile attacks"
```

### Task 4: Full regression and device performance verification

**Files:**
- Modify: `docs/progress-2026-10-08.md`

**Interfaces:** None.

- [ ] **Step 1: Run every native scene sequentially after one editor import**

Run Godot editor import once, then all `tests/*_native.tscn`. Scan logs for `SCRIPT ERROR` and non-certificate `ERROR:`. Expected: zero failures.

- [ ] **Step 2: Run balance, economy, and save integrity checks**

Expected: no invalid catalog/build variants, economy conservation intact, and 100 save/restore cycles passing.

- [ ] **Step 3: Export and install Android build**

Export the `Android` preset, run `adb install -r`, and launch `com.example.syntaxbreaker`. Do not uninstall or clear data.

- [ ] **Step 4: Observe end-stage and final-boss behavior on device**

Record: no ordinary final waves, boss/add counts, immediate victory on boss death, no lingering hazards, and whether the prior end-stage hitch is perceptible. Include device/model and build commit in `docs/progress-2026-10-08.md`.

- [ ] **Step 5: Commit evidence**

```powershell
git add docs/progress-2026-10-08.md
git commit -m "docs: verify final encounter and stage cleanup"
```
