# Syntax Breaker — Design Overview

> 2D top-down roguelite. Auto-aim combat, tag-based skill/support system inspired by Path of Exile.
> Godot 4.4+ / GDScript. Mobile-first portrait (1080x1920).

> **Status:** Post-MVP. All 19 MVP tasks plus migration phases 1–7 complete (pooling, tag
> interactions, branching stage map, build identity, meta-progression, mobile/perf, content expansion).
> Phase 8 (first public demo) is the current focus. See `CLAUDE.md` for phase tracking.

---

## Game Loop

```
Main Menu → (pick Region) → Skill Picker → Stage Map ⇄ Stages → Run Summary
                                              │
              ┌───────────────────────────────┼────────────────────────────┐
           Combat/Elite/Boss              Treasure                        Shop
              │                              │                              │
        Reward Picker / Chest          free reward                    spend gold
        (+ boss: Mutation → Legendary)
```

- **Branching stage tree** (`StageTree` / `StageGenerator`): 10 depths, up to 3 nodes per row,
  edges connect adjacent nodes. Player chooses a path through the map. Bosses are fixed at
  **depths 5 and 10**; reaching depth 10's completion ends the run in victory.
- **Node types** (`StageData.Type`): `COMBAT`, `ELITE` (fewer/tougher, better loot),
  `SHOP`, `TREASURE` (free reward), `BOSS`.
- **Stage modifiers** rolled from depth 3+ (`swift`, `tough`, `swarming`, `deadly`, `enriched`,
  `cursed`); regions inject their own. 1 modifier at depth 3–6, 2 at depth 7+.
- **Combat stage**: player spawns in a 3200×3200 arena. Skills auto-fire at nearest target.
  Enemies stream in over the stage duration (density curve scales 80 → 700 enemies, ~50–90s).
  Mini-bosses appear on the depth-4 and depth-7 density curves.
- **Rewards**: normal combat → reward picker then a mandatory shop; treasure → free reward then
  back to map; elite/boss → chest with rolled loot. Boss clears additionally grant a **mutation**
  (per-skill stat graft) followed by a **legendary passive** choice.
- **Run end**: victory at depth 10 or on death. Unlock conditions are checked against `run_stats`;
  newly satisfied unlocks persist (meta-progression).

Run auto-saves on every stage-map visit (`user://active_run.json`) and can be resumed from the menu.

---

## Architecture

### Singletons (autoloads)

| Singleton | Role |
|---|---|
| **GameBus** | Global signal bus — `enemy_killed`, `enemy_hit`, `stage_cleared`, `gold_changed`, `player_died`, `run_ended`, `skill_acquired`, `support_acquired`, `passive_acquired` |
| **RunManager** | Run state — stage tree, gold, equipped skills, owned supports/passives/consumables, skill slots, region, ascension, run-stat tracking, save/resume |
| **InputManager** | Touch/keyboard abstraction — exposes `movement_vector` |
| **BehaviorRegistry** | Maps behavior keys → GDScript classes. **20 registered behaviors** (see Behavior System) |
| **MetaProgression** | Persistent unlocks, ascension level (0–20), codex discovery. Saved to JSON |
| **QualitySettings** | Mobile/perf quality tier (particle/effect density, shake) |

### Entry point

`main.tscn` → `Main` node holds `GameManager`, which owns a `State` machine
(`MENU`, `STAGE_MAP`, `COMBAT`, `SHOP`, `REWARD`, `RUN_END`) and drives the loop above.

### Scene / script split

- `scenes/` — `.tscn` files for visuals/physics
- `scripts/` — `.gd` logic, grouped by domain (`autoloads`, `behaviors`, `combat`, `enemies`,
  `skills`, `stages`, `ui`, `util`, `resources`)
- `resources/` — `.tres` data: skills, supports, passives, unlocks, regions, consumables, config

---

## Resource System

### SkillResource
`id, name, tags[], base_damage, base_cooldown, base_speed, base_range, base_pierce,
base_projectile_count, max_supports (3), scene_path, icon, rarity, description`

### SupportResource
`id, name, required_tags[], excluded_tags[], stat_modifiers{}, added_tags[], behavior_key,
icon, rarity, description`

Linking rule: a support links to a skill if (a) the skill has none of the support's `excluded_tags`,
and (b) the support is universal (`required_tags` empty) or the skill has any `required_tags`.

### PassiveResource
`id, name, affected_tags[], stat_modifiers{}, behavior_key, rarity, description`

Global passives (`affected_tags` empty) apply to all skills; tag-specific passives apply only to
matching skills. Passives may carry a `behavior_key` for runtime engine effects (see Engine Systems).

### RegionResource
`id, name, description, bg_color, grid_color, border_color, enemy_tint, ambient_particle_color,
stage_modifiers[], hp_mult, damage_mult, rarity` — themes the arena and biases the modifier pool.

### ConsumableResource
`id, name, effect_type, duration, magnitude, cost, description`

---

## Content

### Skills (7)

| Skill | Tags | Damage | Cooldown | Special |
|---|---|---|---|---|
| Fireball | projectile, fire | 10 | 0.8s | — |
| Lightning Bolt | projectile, lightning | 8 | 0.5s | Fast |
| Poison Dart | projectile, poison | 5 | 1.2s | Multi-projectile |
| Flame Wave | aoe, fire | 15 | 1.5s | Expanding-ring AoE, scorch aftermath |
| Static Field | aoe, lightning | 12 | 2.0s | Self-cast AoE, arc strikes |
| Frost Nova | aoe, cold | — | — | Expanding-ring AoE, applies slow + frostblight, frost-patch aftermath |
| Blade Spin | melee, aoe, physical | 8 | 3.0s | Orbiting blades, causes bleed |

### Supports (25)

Stat-and-behavior modules linked into skill slots. Includes:
`pierce`, `chain`, `split`, `shotgun`, `returning`, `ricochet_amplifier`, `increased_area`,
`faster_casting`, `spell_echo`, `crit_explosion`, `crit_cascade`, `arc_burst`, `poison_on_hit`,
`plague_carrier`, `toxic_burst`, `corpse_bloom`, `elemental_proliferation`, `hypothermia`,
`echo_trigger`, `cast_on_kill`, `void_rift`, `totem`, `mine`, plus tradeoff supports
`glass_cannon` (+dmg/−speed) and `overcharge` (+dmg/+cooldown).

Stat-only supports have an empty `behavior_key`; the rest reference one of the 20 behaviors.

### Passives (57)

Grouped into:
- **Base stat passives** — e.g. `thick_skin`, `swift_feet`, `sharp_eyes`, `heavy_hitter`,
  `rapid_fire`, `iron_will`, `extra_shot`, `wide_impact`.
- **Tag/element masteries** — `fire_mastery`, `storm_conduit`, `toxic_resilience`, `conduction`,
  `lightning_rod`, `ring_of_fire`, `blast_radius`, etc.
- **Support masteries** (`<support>_mastery`) — each upgrades a specific support's behavior with
  extra stats (bonus table in `StatCalculator._mastery_bonuses`).
- **Engine-keystone passives** — toggle the runtime Engine Systems: `sharpened_edge`,
  `arcane_tempo`, `virulence`, `detonation_expert`, `deep_freeze`.
- **Legendary passives** (`rarity == "legendary"`) — offered only via boss-clear chests, e.g.
  `executioner`, `overflowing_power`, `glass_body`, `no_crit_juggernaut`, `chain_reaction`,
  `trigger_on_death`.

---

## Stat Computation

`StatCalculator.compute(skill, supports, passives)` builds final stats from base skill values.

Modifier types:
- **Flat** (`key`): added directly (e.g. `"pierce": 2`)
- **Flat add** (`key_add`): added to base (e.g. `"crit_chance_add": 0.1`)
- **Multiplicative** (`key_mult`): collected additively then applied as `base * (1 + Σbonuses)`
  (e.g. `"damage_mult": 0.8` ⇒ −20%)

A support whose matching `<id>_mastery` passive is owned also contributes the mastery bonus.
Run-wide `shop_bonuses` are added after multipliers, then stats are clamped.

Clamps: damage ≥1, cooldown 0.05–10, speed ≥50, range ≥50, pierce 0–20, area_mult 0.1–5,
projectile_count 1–8, chain_count ≤10, split_count ≤5, crit_chance ≤80%.
Base: 5% crit chance, 1.5× crit multiplier. Extra computed keys: `echo_count`, `is_totem`, `is_mine`.

---

## Combat

### Skill Runtime
- **SkillInstance** (RefCounted): composes a `SkillResource` + linked supports + mutations.
  Holds `computed_stats`, instantiated `behaviors[]`, and applies matching passives via
  `recompute()`. Notifies behaviors on spawn/hit/kill/crit and on status apply.
- **SkillCaster** (on player): holds active instances, auto-casts on cooldown. Projectiles target
  nearest enemy via `Targeting`; aoe/melee self-cast; totem/mine spawn deployables.
- **ObjectPool**: recycles projectiles, AoE scenes, and enemies.
- **Deployables**: `SkillTotem` (re-casts a skill on a timer) and `SkillMine` (proximity detonation).

### Behavior System
`BehaviorBase` interface: `modify_spawn()`, `on_hit()`, `on_kill()`, `modify_stats()`.
**20 behaviors** registered in `BehaviorRegistry`: `pierce`, `chain`, `split`, `increased_area`,
`faster_casting`, `crit_explosion`, `poison_on_hit`, `elemental_proliferation`, `shotgun`,
`cast_on_kill`, `void_rift`, `corpse_bloom`, `toxic_burst`, `arc_burst`, `echo_trigger`,
`plague_carrier`, `ricochet_amplifier`, `crit_cascade`, `returning`, `hypothermia`.
`TriggerGuard` caps trigger recursion (depth 1) and per-target re-trigger cooldown (0.25s)
to prevent cast-on-X loops.

### Tag Interactions (`TagInteractions.process_hit`)
| Combo | Trigger | Effect |
|---|---|---|
| **Ignite** | Fire hits poisoned target | Consumes poison, burst = tick × remaining × 3 |
| **Lightning Arc** | Lightning hit | 30% damage arcs to up to 2 enemies within 120px |
| **Toxic Cloud** | Poison hits burning target | Spreads poison to up to 10 enemies within 120px |
| **Cauterize** | Fire hits bleeding target | Consumes bleed, burst = tick × remaining × 3.5 |

### Cross-Element Synergies (`SynergyTracker`, 1.5s window)
| Synergy | Elements | Effect |
|---|---|---|
| **Overload** | fire + lightning | 80% damage AoE burst within 130px |
| **Shatter** | lightning + cold | 200% damage single-target burst |
| **Frostblight** | cold + poison | Frostblight DoT on target + spread within 120px |

### Engine Systems (`EngineTracker`, gated by keystone passives)
- **Sharpened Edge** — crits build decaying crit-chance streak (+3%/crit, max +15%, 3s).
- **Arcane Tempo** — casting a *different* skill stacks cast speed (−8%/stack, max 3, 4s).
- **Virulence** — poison ticks scale with other DoTs on the target (+20%/DoT, max 3).
- **Detonation Expert** — AoE hitting 3+ enemies deals +20%.
- **Deep Freeze** — slowed/chilled enemies take +25% from all sources.

### Combo System (`ComboTracker`)
Kills within a 2s window build a combo; multiplier ramps 1.0→2.0 over 50 kills. Best combo recorded.

### Damage & DoT
`CombatUtils.roll_damage()` rolls crit and applies crit multiplier. `EnemyBase._dots{}` holds
active DoTs (`poison`, `burn`, `bleed`, `frostblight`, …) ticking on interval; `apply_slow()`
chills. Enemies render a health bar plus **status-indicator glyphs** (distinct shaped icons per
status: flame, droplet, diamond, bolt, snowflake, slow arrow).

---

## Enemies

Procedurally drawn sprites (see `scripts/util/*_sprite.gd`) — no PNG assets.

| Type | Role |
|---|---|
| Gremlin (base) | Melee trash; wanders outside aggro (200px), chases inside, backs off <30px |
| Swarm | Fast, fragile, spawns in numbers |
| Tank | Slow, high HP |
| Basic Ranged | Fires enemy projectiles |
| Mini-boss | Appears on depth-4 / depth-7 density curves; multi-phase patterns |
| Bosses | Fixed at depth 5 & 10 (distinct sprites: oracle, monarch, overseer, brute, demon, breaker, mote) |

All enemies: overhead health bar, status glyphs, hit flash, separation steering, pool recycling,
arena-boundary clamping. Per-stage difficulty comes from `StageData` multipliers (type + modifiers
+ region + ascension) layered onto the depth scaling curve.

---

## Player

- **Movement**: 250 base speed via `InputManager.movement_vector`, clamped to arena bounds
  (slowed 20% under the `cursed` modifier).
- **HP**: 100 base, 0.5s i-frames after hit, white flash on damage.
- **God mode**: debug toggle.

---

## UI

| Screen | Description |
|---|---|
| **Splash / Main Menu** | Start, region select, resume saved run |
| **Skill Picker** | Choose starting skill at run start |
| **Stage Map** | Branching node map; pick the next stage along reachable edges |
| **HUD** | HP bar, gold, stage/depth label, combo display, consumable bar |
| **Minimap** | Player + enemy dots over arena |
| **Reward Picker / Chest Reward** | Post-stage choices; chests for elite/boss loot |
| **Mutation Picker** | Assign a boss mutation to a skill |
| **Legendary Picker** | Choose a legendary passive after a boss |
| **Shop** | Rolled offerings, reroll, loadout management, support linking |
| **Skill Manager** | Move supports between skill slots |
| **Codex** | Discovered skills/supports/enemies/interactions |
| **Unlock Tree** | View meta-progression unlock conditions |
| **Run Summary** | Victory/defeat, new unlocks, return |
| **Debug Menu** (F1) | FPS/stats, kill all, +gold, heal, +crit, god mode, skip stage, grant content |
| **Damage Numbers** | Floating hit text (crit emphasized) |

### Shop Economy
Run starts at **30 gold**. Skill slots unlock progressively (1 → up to 4, gained on the 1st and 4th
advance). Reroll starts at 2g, +1g each reroll (persists across stages, resets per run).
Only unlocked content appears. Prices scale by item type and rarity.

---

## Meta-Progression

- **Starter pool**: 3 skills (`fireball`, `lightning_bolt`, `blade_spin`), 10 supports, and a broad
  set of base + mastery passives. Remaining content unlocks via `UnlockConditionResource` checks
  against `run_stats` at run end (~20 unlock conditions).
- **Ascension** (0–20): per-level scaling — `hp_mult +15%`, `damage_mult +10%`, `speed_mult +3%`,
  `gold_mult −2%` (floor 0.5×) per level.
- **Codex**: discovery tracking per category.
- Persisted to `user://meta_progression.json`. Active run persisted to `user://active_run.json`.

---

## Regions (3)

`burning_grounds`, `storm_spire`, `toxic_depths` — each re-themes the arena (colors, enemy tint,
ambient particles), injects signature stage modifiers, and applies `hp_mult` / `damage_mult`.

## Consumables (8)

Slotted (max 4), charge-based, used mid-combat: `health_potion`, `damage_flask`, `cooldown_flask`,
`berserker_potion`, `time_slow` (enemy slow), `aoe_bomb`, `gold_magnet`, `auto_revive`.
Managed by `ConsumableManager`; effects are timed and surfaced on the consumable HUD.

## Mutations (8)

Per-skill stat grafts offered after boss clears (`MutationData.POOL`): `piercing`, `rapid_fire`,
`giant`, `sniper`, `scatter`, `crit_master`, plus specials `vampiric` (heal on kill) and
`explosive` (kills deal nearby damage).

---

## Visual Style

- **Tag colors**: fire `#FF6619`, lightning `#66B3FF`, poison `#4DE633`, cold `#99E6FF`,
  physical `#CCCCCC`, default `#FFCC19` (`TagColors`).
- **Screen shake**: 3.0 on hit, 1.5 on kill, 0.15s; **hit stop** 0.03s (`Engine.time_scale`).
- **Camera**: follows player with `CameraShake`.
- **Sprites**: fully procedural (player, enemies, bosses) via `pixel_sprite` / `*_sprite.gd` builders.
- Region palette overrides the arena background/grid/border at runtime.

---

## Balance Knobs (`resources/config/game_balance.tres`)

```
Player:    250 speed, 100 HP, 0.5s iframes
Enemies:   200px aggro, 80 speed, 20 HP, 10 contact dmg, 1 gold
Spawning:  groups 4–6, 40 spread, 50 margin, 200px min from player
Scaling:   +5 HP/stage, boss interval 3 (legacy knob; tree uses fixed depths 5 & 10)
Camera:    3.0/1.5 shake, 0.15s, 0.03s hit stop
```

Per-stage difficulty is the product of `game_balance` base × depth scaling (`StageGenerator`)
× `StageData` multipliers (type/modifier/region) × ascension scaling.

---

## File Structure

```
scripts/
  autoloads/  game_bus, run_manager, input_manager, behavior_registry, meta_progression, quality_settings
  behaviors/  behavior_base + 20 behaviors + passive_behaviors
  combat/     engine_tracker, combo_tracker, synergy_tracker, mutation_data, consumable_manager,
              skill_totem, skill_mine, trigger_guard
  enemies/    enemy_base, basic_ranged, swarm_enemy, tank_enemy, mini_boss, spawner, enemy_projectile
  main/       main, game_manager
  player/     player
  resources/  skill/support/passive/unlock/region/consumable_resource, game_balance
  skills/     skill_instance, skill_caster, targeting, projectile_base, orbit_skill, aoe_skill_base
  stages/     arena, camera_shake, spawn_formation, stage_data, stage_tree, stage_generator
  ui/         hud, shop, skill_manager, skill_picker, stage_map, stage_choice, reward_picker,
              reward_roller, chest_reward, mutation_picker, legendary_picker, combo_display,
              consumable_hud, codex, unlock_tree, run_summary, main_menu, splash_screen,
              minimap, virtual_joystick, damage_number, debug_menu, ui_theme
  util/       stat_calculator, tag_matcher, tag_colors, tag_interactions, combat_utils, combat_log,
              object_pool, spatial_grid, resource_listing, pixel_sprite + procedural *_sprite builders

resources/
  skills/ (7)   supports/ (25)   passives/ (57)   unlocks/ (~20)
  regions/ (3)  consumables/ (8) config/ (game_balance, default_theme)

scenes/
  main/  stages/ (arena)  player/  enemies/ (gremlin, swarm, tank, ranged, mini_boss, projectile)
  skills/ (7)  ui/ (menus, shop, pickers, hud, joystick)
```
