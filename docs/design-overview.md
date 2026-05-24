# Syntax Breaker — Design Overview

> 2D top-down roguelite. Auto-aim combat, tag-based skill/support system inspired by Path of Exile.
> Godot 4.4+ / GDScript. Mobile-first portrait (1080x1920).

---

## Game Loop

```
Main Menu → Skill Picker → Stage 1 → Shop → Stage 2 → Shop → ... → Stage 5 → Run Summary
                                         mini-boss on stages 3 & 5
```

- **Stage**: player spawns in a 3200x3200 arena, enemies spawn in groups of 4-6 (40 per stage, scaling +5/stage). Skills auto-fire at nearest target. Enemies drop gold. Clear all waves to advance.
- **Shop**: spend gold on skills, supports, passives, or reroll. Link supports to skills. Manage loadout.
- **Run end**: victory after stage 5 or death. Unlocks persist across runs (meta-progression).

Target run time: 12-15 minutes (90s combat + 30s shop per stage).

---

## Architecture

### Singletons (autoloads)

| Singleton | Role |
|---|---|
| **GameBus** | Global signal bus — `enemy_killed`, `enemy_hit`, `stage_cleared`, `gold_changed`, `player_died`, `run_ended`, `skill_acquired`, `support_acquired`, `passive_acquired` |
| **RunManager** | Run state — stage counter, gold, owned supports/passives, skill slots, run stats tracking |
| **InputManager** | Touch/keyboard abstraction — exposes `movement_vector` |
| **BehaviorRegistry** | Maps behavior keys to GDScript classes. 8 registered behaviors: `pierce`, `chain`, `split`, `increased_area`, `faster_casting`, `crit_explosion`, `poison_on_hit`, `elemental_proliferation` |
| **MetaProgression** | Persistent unlock state saved to JSON. Starter unlocks: fireball, lightning_bolt, blade_spin, pierce, faster_casting, poison_on_hit, thick_skin. Other content unlocks via run conditions |

### Entry point

`main.tscn` → `Main` node holds `GameManager`. Main menu triggers `GameManager.start_run()`, which opens skill picker then loops combat → shop stages.

### Scene / script split

- `scenes/` — .tscn files for visuals/physics
- `scripts/` — .gd files for logic
- `resources/` — .tres data files for skills, supports, passives, unlocks, config

---

## Resource System

### SkillResource

```
id, name, tags[], base_damage, base_cooldown, base_speed, base_range,
base_pierce, base_projectile_count, max_supports (2), scene_path, rarity, description
```

### SupportResource

```
id, name, required_tags[], excluded_tags[], stat_modifiers{},
added_tags[], behavior_key, rarity, description
```

Linking rule: a support links to a skill if (a) the skill has none of the support's `excluded_tags`, and (b) the support is universal (`required_tags` empty) or the skill has any of the `required_tags`.

### PassiveResource

```
id, name, affected_tags[], stat_modifiers{}, rarity, description
```

Global passives (`affected_tags` empty) apply to all skills. Tag-specific passives apply only to skills with matching tags.

---

## Content

### Skills (6)

| Skill | Tags | Damage | Cooldown | Special |
|---|---|---|---|---|
| Fireball | projectile, fire | 10 | 0.8s | — |
| Lightning Bolt | projectile, lightning | 8 | 0.5s | Fast (speed 500) |
| Poison Dart | projectile, poison | 5 | 1.2s | 3 projectiles |
| Flame Wave | aoe, fire | 15 | 1.5s | Self-cast AoE |
| Static Field | aoe, lightning | 12 | 2.0s | Self-cast AoE |
| Blade Spin | melee, aoe, physical | 8 | 3.0s | Orbiting blades, causes bleed |

### Supports (11)

| Support | Required tags | Effect | Behavior |
|---|---|---|---|
| Pierce | projectile | +2 pierce | pierce |
| Chain | projectile (excl. beam) | +3 chain, -20% dmg | chain |
| Split | projectile | +2 split, -30% dmg | split |
| Shotgun | projectile | +3 proj, -30% dmg, -40% range | stat-only |
| Increased Area | aoe | +40% area | increased_area |
| Faster Casting | universal | -25% cooldown | faster_casting |
| Crit Explosion | universal | +10% crit chance, AoE on crit | crit_explosion |
| Poison on Hit | projectile or melee | Applies poison DoT | poison_on_hit |
| Elemental Proliferation | fire or lightning or poison | Spreads element on kill | elemental_proliferation |
| Glass Cannon | universal | +50% dmg, -30% speed | stat-only |
| Overcharge | universal | +100% dmg, +60% cooldown | stat-only |

### Passives (5)

| Passive | Affects | Effect |
|---|---|---|
| Thick Skin | global | +15% max HP |
| Fire Mastery | fire | +20% dmg, -10% cooldown |
| Storm Conduit | lightning | +15% dmg, +10% area |
| Projectile Expert | projectile | +10% speed, +1 pierce |
| Toxic Resilience | poison | +15% dmg |

---

## Stat Computation

`StatCalculator.compute(skill, supports, passives)` builds final stats from base skill values.

Modifier types:
- **Flat** (`key`): directly added (e.g., `"pierce": 2`)
- **Flat add** (`key_add`): added to base (e.g., `"crit_chance_add": 0.1`)
- **Multiplicative** (`key_mult`): collected additively then applied as `base * (1 + sum_of_bonuses)` (e.g., `"damage_mult": 0.8` means -20%)

Clamping enforced: damage min 1, cooldown 0.1-10, speed min 50, pierce 0-20, area_mult 0.1-5, projectile_count 1-8, chain_count max 10, split_count max 5, crit_chance max 80%.

Base stats: 5% crit chance, 1.5x crit multiplier.

---

## Combat

### Skill Runtime

- **SkillInstance** (RefCounted): composes a `SkillResource` + array of `SupportResource`. Holds `computed_stats` and instantiated `behaviors[]`. Notifies behaviors on spawn/hit/kill.
- **SkillCaster** (Node2D on player): holds all active `SkillInstance`s. Auto-casts each skill when cooldown expires. Self-cast (aoe/melee) needs no target; projectile skills find nearest enemy via `Targeting`.
- **ObjectPool**: recycles projectile/skill scene instances.

### Behavior System

`BehaviorBase` interface: `modify_spawn()`, `on_hit()`, `on_kill()`, `modify_stats()`.

8 concrete behaviors registered in `BehaviorRegistry`. Support resources reference a behavior by `behavior_key`. Stat-only supports (glass_cannon, shotgun, overcharge) have no behavior.

### Tag Interactions

`TagInteractions.process_hit()` checks cross-element combos on each hit:

| Combo | Trigger | Effect |
|---|---|---|
| **Ignite** | Fire hits poisoned target | Consumes poison, deals burst = tick_dmg * remaining * 2 |
| **Lightning Arc** | Lightning hits any target | 30% damage arcs to 1 nearby enemy within 100px |
| **Toxic Cloud** | Poison hits burning target | Spreads poison DoT to up to 8 enemies within 80px |

### Damage

`CombatUtils.roll_damage()` — rolls crit based on `crit_chance`, applies `crit_mult`.

### DoT System

`EnemyBase._dots{}` — dictionary of active DoTs keyed by type (e.g., "poison", "burn"). Each tick applies damage; expired DoTs auto-remove. `apply_dot()` overwrites same-type DoT.

---

## Enemies

### Types

| Type | HP | Speed | Damage | Behavior |
|---|---|---|---|---|
| Base (melee) | 20 | 80 | 10 contact | Wander outside aggro (200px), chase inside aggro, back off <30px |
| Basic Ranged | — | — | — | Fires enemy projectiles |
| Mini-boss | — | — | — | Spawns on stages 3 & 5 |

All enemies: health bar overhead, hit flash, pool recycling, arena boundary clamping.

### Spawner

All enemies for a stage spawn at once in groups of 4-6 scattered across the map (min 200px from player). Pool-based recycling: dead enemies return to pool, re-initialized on next spawn.

---

## Player

- **Movement**: 250 speed via `InputManager.movement_vector`, clamped to arena bounds
- **HP**: 100 base, 0.5s invincibility frames after hit, white flash on damage
- **God mode**: debug toggle via meta flag
- **Visual**: blue circle (r=16)

---

## UI

| Screen | Description |
|---|---|
| **Main Menu** | Start button, title |
| **Skill Picker** | Choose starting skill at run start |
| **HUD** | HP bar, gold counter, stage label — in-arena overlay |
| **Minimap** | Player + enemy dots on arena overview |
| **Shop** | 4 random offerings (skills/supports/passives), reroll, manage button, link panel for newly bought supports |
| **Skill Manager** | Drag supports between skill slots |
| **Run Summary** | Victory/defeat, new unlocks, play again |
| **Debug Menu** (F1) | FPS, stats, kill all, +gold, heal, +crit, god mode, skip stage, add all supports |
| **Damage Numbers** | Floating text on hit (crit = larger/different color) |

### Shop Economy

| Type | Common | Uncommon | Rare |
|---|---|---|---|
| Skill | 15g | 20g | 25g |
| Support | 8g | 12g | 15g |
| Passive | 10g | 15g | 20g |

Reroll starts at 2g, +1g each reroll. Only unlocked content appears in shop.

---

## Meta-Progression

Starter pool: 3 skills, 3 supports, 1 passive. Remaining content (3 skills, 8 supports, 4 passives) unlocks via `UnlockConditionResource` checks against `run_stats` at run end.

Persisted to `user://meta_progression.json`.

---

## Visual Style

- **Tag colors**: fire=#FF6619, lightning=#66B3FF, poison=#4DE633, cold=#99E6FF, physical=#CCCCCC, default=#FFCC19
- **Screen shake**: 3.0 on hit, 1.5 on kill (0.15s duration)
- **Hit stop**: 0.03s (via `Engine.time_scale`)
- **Player**: blue circle. **Enemies**: red circle + green HP bar overhead.
- **Camera**: follows player with CameraShake node

---

## Balance Knobs (GameBalance resource)

All tunable from a single `game_balance.tres`:

```
Player:       250 speed, 100 HP, 0.5s iframes
Enemies:      200px aggro, 80 speed, 20 HP, 10 contact dmg, 1 gold
Spawning:     40/stage, groups 4-6, 50px margin, 200px min from player
Scaling:      +5 HP/stage, +5 enemies/stage, boss every 3 stages
Camera:       3.0/1.5 shake, 0.15s duration, 0.03s hit stop
```

---

## File Structure

```
scripts/
  autoloads/         game_bus, run_manager, input_manager, behavior_registry, meta_progression
  behaviors/         behavior_base + 8 concrete behaviors
  enemies/           enemy_base, basic_ranged, mini_boss, spawner, enemy_projectile
  main/              main, game_manager
  player/            player
  resources/         skill_resource, support_resource, passive_resource, unlock_condition_resource, game_balance
  skills/            skill_instance, skill_caster, targeting, projectile_base, orbit_skill, aoe_skill_base
  ui/                hud, shop, skill_manager, skill_picker, main_menu, run_summary, minimap,
                     virtual_joystick, damage_number, debug_menu
  util/              stat_calculator, tag_matcher, tag_colors, tag_interactions, combat_utils,
                     combat_log, object_pool

scenes/
  main/              main.tscn, game_manager.tscn
  stages/            arena.tscn
  player/            player.tscn
  enemies/           base_enemy, basic_melee, basic_ranged, mini_boss, enemy_projectile
  skills/            fireball, lightning_bolt, poison_dart, flame_wave, static_field, blade_spin
  ui/                shop, skill_manager, skill_picker, main_menu, run_summary, hud, virtual_joystick

resources/
  skills/            6 skill .tres
  supports/          11 support .tres
  passives/          5 passive .tres
  unlocks/           12 unlock condition .tres
  config/            game_balance.tres, default_theme.tres
```
notes:

not much to do with gold at stage 4+
