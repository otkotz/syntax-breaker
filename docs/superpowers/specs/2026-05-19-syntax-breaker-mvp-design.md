# Syntax Breaker — Design Spec

## Overview

2D top-down roguelite with auto-aim combat, inspired by Binding of Isaac (run structure), Brotato (auto-aim pacing), and Path of Exile (skill/support/tag system). The core hook is emergent build variety through a tag-based skill + support modifier system where supports link to skills via tag matching, creating thousands of possible combinations from a small content set.

**Engine:** Godot 4.4+ / GDScript
**Platform:** Mobile-first (Android/iOS), PC port later
**Orientation:** Portrait (1080x1920)
**Target run time:** 15–25 minutes (10 stages)
**Scope:** Solo developer

---

## Core Gameplay Loop

```
Main Menu → Skill Picker → Stage Map → Combat/Elite/Shop/Treasure → ... → Boss (Stage 5) → ... → Boss (Stage 10) → Run Summary
```

### Stage Map (PoE-style tree)

Between stages, the player chooses a path through a branching tree (10 depths). Each node is one of:

| Node type | Description |
|-----------|-------------|
| **Combat** | Clear waves of enemies |
| **Elite** | Fewer but tougher foes, better loot (0.4x count, 2.5x HP, 1.5x damage, 1.5x gold) |
| **Shop** | Spend gold on skills, supports, passives, stat upgrades |
| **Treasure** | Pick a free reward |
| **Boss** | Defeat the boss to advance (depths 5 and 10) |

Stage modifiers (swift, tough, swarming, deadly, enriched, cursed) apply from depth 3+, adding risk/reward variety.

### Within a Stage

1. Player spawns in a 3200x3200 arena
2. All enemies spawn at once in groups of 4–6, scattered across the map (min 200px from player)
3. Player's equipped skills auto-fire at targets based on proximity
4. Enemies drop gold; kills build a combo multiplier (2s window, up to 2x at 50 kills)
5. Stage ends when all enemies are cleared
6. Reward picker → Shop → Stage Map

### Post-Combat Flow

- **Reward picker**: choose from skills, supports, passives, support quality upgrades, mutations, or gold
- **Shop**: spend gold on offerings (8 items) — skills, supports, passives, stat upgrades. Reroll starts at 2g, +1g each reroll (cost persists across stages, resets on new run). Only unlocked content appears.
- **Boss rewards**: mutation picker (permanent skill upgrade) → legendary passive picker → reward → shop

### Pacing

- Each stage: ~90 seconds of combat
- Shop phase: ~30 seconds
- Full run (10 stages): ~15–25 minutes
- Death = run over, earn meta-unlocks based on progress

---

## Controls & Input

### Mobile (Primary)

- **Movement:** Floating virtual joystick, left thumb area (bottom-left quadrant). Appears where thumb touches.
- **Aiming:** Auto-aim — skills target nearest enemies automatically
- **Casting:** Auto-cast — skills fire when off cooldown
- **Consumables:** Tap HUD buttons to use

### Input Architecture

`InputManager` autoload abstracts input source. Emits a normalized movement vector regardless of source (joystick, keyboard). Makes PC port trivial.

### Screen Layout (Portrait)

```
┌─────────────┐
│   HP / Gold  │  ← top HUD
│   Combo      │  ← combo counter
│             │
│   ARENA     │  ← upper ~70%, gameplay
│             │
│ [minimap]   │  ← corner minimap
│ [consumable]│  ← consumable buttons
│ [joy]       │  ← joystick zone, bottom-left
└─────────────┘
```

---

## Skill Architecture (Resource-Driven)

### Design Philosophy

Skills and supports are defined as Godot Resource files (`.tres`). Resources hold data (stats, tags, modifiers). Scenes hold visuals and physics. At runtime, a `SkillInstance` composes a skill resource + its linked supports + mutations into computed stats and behaviors.

Adding a new skill = create 1 `.tres` + 1 `.tscn`. No other files touched.
Adding a stat-only support = create 1 `.tres`. No script needed.

### SkillResource

```
SkillResource (.tres):
  id: String                    # "fireball"
  name: String                  # "Fireball"
  tags: Array[String]           # ["projectile", "fire"]
  base_damage: float            # 10.0
  base_cooldown: float          # 0.8
  base_speed: float             # 300.0 (projectile speed, etc.)
  base_range: float             # 400.0
  base_pierce: int              # 0
  base_projectile_count: int    # 1
  max_supports: int             # 2 (support slot count)
  scene_path: String            # "res://scenes/skills/fireball.tscn"
  rarity: String                # "common", "uncommon", "rare"
  description: String
```

### SupportResource

```
SupportResource (.tres):
  id: String                    # "chain"
  name: String                  # "Chain"
  required_tags: Array[String]  # ["projectile"] — skill must have ANY
  excluded_tags: Array[String]  # ["beam"] — skill must NOT have
  stat_modifiers: Dictionary    # { "damage_mult": 0.8, "chain_count": 3 }
  added_tags: Array[String]     # tags added to skill when linked
  behavior_key: String          # "chain" — maps to behavior script, or "" for stat-only
  rarity: String
  description: String
```

### PassiveResource

```
PassiveResource (.tres):
  id: String                    # "fire_mastery"
  name: String                  # "Fire Mastery"
  affected_tags: Array[String]  # ["fire"] — boosts skills with ANY of these
  stat_modifiers: Dictionary    # { "damage_mult": 1.2, "cooldown_mult": 0.9 }
  rarity: String                # "common", "uncommon", "rare", "legendary"
  description: String
```

### SkillInstance (Runtime)

Composes base skill + linked supports + mutations at runtime:

```
SkillInstance:
  base: SkillResource
  linked_supports: Array[SupportResource]
  computed_stats: Dictionary        # recalculated when supports change
  behaviors: Array[BehaviorBase]
  mutations: Array[Dictionary]      # boss reward upgrades
```

### Mutations

Boss rewards that permanently modify a specific skill for the rest of the run. Rolled from MutationData pool:

| Mutation | Effect |
|----------|--------|
| Piercing | +3 pierce |
| Rapid Fire | -40% cooldown |
| Giant | +80% area |
| Sniper | +60% range, +30% damage |
| Scatter Shot | +3 projectiles |
| Vampiric | Heal 2 HP per kill |
| Explosive | Kills deal 30% damage nearby |
| Critical Mastery | +20% crit chance, +0.5 crit multiplier |

### Stat Computation Pipeline

1. Start with base skill stats
2. Apply each linked support's `stat_modifiers` (multiplicative stacking)
3. Apply global passives that match the skill's tags
4. Apply shop bonuses (flat damage, cooldown reduction, crit chance)
5. Apply mutations
6. Apply engine bonuses (crit streak from Sharpened Edge, tempo from Arcane Tempo)
7. Clamp to min/max bounds

Modifier types:
- **Flat** (`key`): directly added (e.g., `"pierce": 2`)
- **Flat add** (`key_add`): added to base (e.g., `"crit_chance_add": 0.1`)
- **Multiplicative** (`key_mult`): collected additively then applied as `base * (1 + sum_of_bonuses)` (e.g., `"damage_mult": 0.8` means -20%)

Clamping: damage min 1, cooldown 0.1–10, speed min 50, pierce 0–20, area_mult 0.1–5, projectile_count 1–8, chain_count max 10, split_count max 5, crit_chance max 80%.

Base stats: 5% crit chance, 1.5x crit multiplier.

---

## Tag System

### Tags

| Tag | Meaning |
|-----|---------|
| `projectile` | Spawns a moving entity toward target |
| `fire` | Fire element (color #FF6619) |
| `lightning` | Lightning element (color #66B3FF) |
| `poison` | Poison/DoT element (color #4DE633) |
| `cold` | Cold element (color #99E6FF) |
| `physical` | Physical damage (color #CCCCCC) |
| `aoe` | Area of effect |
| `melee` | Close-range / around player |

### Matching Rules

- **Support → Skill:** A support can link to a skill if the skill has ANY of the support's `required_tags` AND NONE of the `excluded_tags`
- **Passive → Skill:** A passive boosts any skill with ANY of the passive's `affected_tags`
- **Tag addition:** Some supports add tags to a skill, making it eligible for additional passives

### Tag Interactions (on hit)

`TagInteractions.process_hit()` checks cross-element combos:

| Combo | Trigger | Effect |
|-------|---------|--------|
| **Ignite** | Fire hits poisoned target | Consumes poison, burst = tick_dmg × remaining × 2 |
| **Lightning Arc** | Lightning hits any target | 30% damage arcs to 1 nearby enemy within 100px |
| **Toxic Cloud** | Poison hits burning target | Spreads poison DoT to up to 8 enemies within 80px |
| **Cauterize** | Fire hits bleeding target | Consumes bleed, burst = tick_dmg × remaining × 2.5 |

### Cross-Element Synergies (within 1s window)

`SynergyTracker` detects when two different elements hit the same target within 1 second:

| Synergy | Elements | Effect |
|---------|----------|--------|
| **Overload** | Fire + Lightning | 60% damage AoE to 15 nearby enemies within 100px |
| **Shatter** | Lightning + Cold | 150% damage burst on target |
| **Frostblight** | Cold + Poison | DoT on target + spread to 8 nearby enemies |

---

## Behavior System

Supports that change how a skill works (not just stats) use a behavior key mapped to a script via `BehaviorRegistry` (autoload singleton).

### Behavior Interface

Every behavior script implements:

- `modify_spawn(skill_instance, projectile)` — alter projectile/entity on creation
- `on_hit(skill_instance, target, projectile)` — react to hitting an enemy
- `on_kill(skill_instance, target, projectile)` — react to killing an enemy
- `modify_stats(base_stats) → modified_stats` — alter computed stats

Behaviors compose: if a skill has Chain + CritExplosion, both `on_hit` hooks fire sequentially.

### Trigger Guard

`TriggerGuard` prevents infinite cascades from trigger behaviors (e.g., on_crit spawning another projectile that crits). Max trigger depth: 1. Per-target cooldown: 0.25s.

### Registry (19 behaviors)

```
pierce, chain, split, increased_area, faster_casting, crit_explosion,
poison_on_hit, elemental_proliferation, shotgun, cast_on_kill, void_rift,
corpse_bloom, toxic_burst, arc_burst, echo_trigger, plague_carrier,
ricochet_amplifier, crit_cascade, returning
```

---

## Build Engines

Passive-driven scaling systems tracked by `EngineTracker`:

| Engine | Passive | Mechanic |
|--------|---------|----------|
| **Crit Streak** | Sharpened Edge | On crit: +3% crit chance (stacks to 15%, decays after 3s) |
| **Arcane Tempo** | Arcane Tempo | Casting different skills within 4s: +8% cast speed per stack (max 3) |

---

## Content

### Skills (6)

| Skill | Tags | Damage | Cooldown | Special |
|-------|------|--------|----------|---------|
| Fireball | projectile, fire | 10 | 0.8s | — |
| Lightning Bolt | projectile, lightning | 8 | 0.5s | Fast (speed 500) |
| Poison Dart | projectile, poison | 5 | 1.2s | 3 projectiles |
| Flame Wave | aoe, fire | 15 | 1.5s | Self-cast AoE |
| Static Field | aoe, lightning | 12 | 2.0s | Self-cast AoE |
| Blade Spin | melee, aoe, physical | 8 | 3.0s | Orbiting blades, causes bleed |

### Supports (24)

| Support | Required tags | Effect | Behavior |
|---------|--------------|--------|----------|
| Pierce | projectile | +2 pierce | pierce |
| Chain | projectile (excl. beam) | +3 chain, -20% dmg | chain |
| Split | projectile | +2 split, -30% dmg | split |
| Shotgun | projectile | +3 proj, -30% dmg, -40% range | shotgun |
| Returning | projectile | Projectiles return to player | returning |
| Increased Area | aoe | +40% area | increased_area |
| Faster Casting | universal | -25% cooldown | faster_casting |
| Crit Explosion | universal | +10% crit chance, AoE on crit | crit_explosion |
| Poison on Hit | projectile or melee | Applies poison DoT | poison_on_hit |
| Elemental Proliferation | fire or lightning or poison | Spreads element on kill | elemental_proliferation |
| Glass Cannon | universal | +50% dmg, -30% speed | stat-only |
| Overcharge | universal | +100% dmg, +60% cooldown | stat-only |
| Spell Echo | universal | — | stat-only |
| Cast on Kill | universal | — | cast_on_kill |
| Void Rift | universal | — | void_rift |
| Totem | universal | — | stat-only |
| Mine | universal | — | stat-only |
| Corpse Bloom | universal | — | corpse_bloom |
| Toxic Burst | poison | — | toxic_burst |
| Arc Burst | lightning | — | arc_burst |
| Echo Trigger | universal | — | echo_trigger |
| Plague Carrier | poison | — | plague_carrier |
| Ricochet Amplifier | projectile | — | ricochet_amplifier |
| Crit Cascade | universal | — | crit_cascade |

### Support Mastery Passives

Each support has a corresponding rare "mastery" passive (e.g., Pierce Mastery, Chain Mastery). Owning the passive enhances the linked support with bonus stats and upgraded behavior effects. Supports can be bought multiple times and equipped across different skills.

### Passives (29)

| Passive | Affects | Rarity |
|---------|---------|--------|
| Thick Skin | global | — |
| Fire Mastery | fire | — |
| Storm Conduit | lightning | — |
| Projectile Expert | projectile | — |
| Toxic Resilience | poison | — |
| Chain Reaction | — | — |
| Executioner | — | — |
| Extra Shot | — | — |
| Glass Body | — | — |
| Heavy Hitter | — | — |
| Iron Will | — | — |
| No Crit Juggernaut | — | — |
| Overflowing Power | — | — |
| Rapid Fire | — | — |
| Ring of Fire | fire | — |
| Sharp Eyes | — | — |
| Swift Feet | global | — |
| Trigger on Death | — | — |
| Wide Impact | aoe | — |
| Brutal Precision | — | — |
| Sharpened Edge | — | — |
| Virulence | poison | — |
| Patient Hunter | — | — |
| Conduction | lightning | — |
| Lightning Rod | lightning | — |
| Arcane Tempo | — | — |
| Overclocked | — | — |
| Blast Radius | aoe | — |
| Detonation Expert | — | — |

Legendary passives are offered after boss fights via dedicated picker.

### Consumables (8)

Single-use items dropped by enemies or found in treasure nodes:

| Consumable | Effect |
|------------|--------|
| Health Potion | Restore HP |
| Damage Flask | Temporary damage boost |
| Cooldown Flask | Temporary cooldown reduction |
| Berserker Potion | Temporary attack speed boost |
| AoE Bomb | Damage all nearby enemies |
| Gold Magnet | Pull all gold on screen |
| Time Slow | Slow enemies temporarily |
| Auto Revive | Revive once on death |

### Enemies (5 types)

| Type | Behavior |
|------|----------|
| Basic Melee | Wander outside aggro (200px), chase inside aggro, back off <30px |
| Basic Ranged | Keeps distance, fires enemy projectiles |
| Swarm | Fast, low HP, appears in groups |
| Tank | Slow, high HP |
| Mini-Boss | Spawns on boss stages, telegraph attacks |

All enemies: health bar overhead, hit flash, pool recycling, arena boundary clamping.

### Regions (3)

Themed areas that apply global modifiers to a run:

| Region | Effect |
|--------|--------|
| Burning Grounds | Fire-themed stage modifiers |
| Storm Spire | Lightning-themed stage modifiers |
| Toxic Depths | Poison-themed stage modifiers |

---

## Combo System

`ComboTracker` tracks consecutive kills within a 2-second window. Kill streak builds a damage multiplier from 1.0x to 2.0x (linear scaling, max at 50 kills). Displayed on HUD. Resets when the timer expires.

---

## DoT System

`EnemyBase._dots{}` — dictionary of active DoTs keyed by type (e.g., "poison", "burn", "bleed", "frostblight"). Each tick applies damage; expired DoTs auto-remove. `apply_dot()` overwrites same-type DoT.

---

## Meta-Progression

### Pool Expansion Model

New skills/supports/passives unlock into the run pool as the player achieves milestones. No permanent stat upgrades — veteran players have more options, not more power.

### Starter Pool (First Run)

- Skills: Fireball, Lightning Bolt, Blade Spin
- Supports: Pierce, Faster Casting, Poison on Hit, Spell Echo, Cast on Kill, Void Rift, Totem, Mine, Returning
- Passives: Thick Skin, Swift Feet, Sharp Eyes, Heavy Hitter, Rapid Fire, Iron Will, Extra Shot, Wide Impact

### Unlock Conditions (19 conditions)

Checked at run-end against run statistics tracked by `RunManager`.

### Ascension System

Up to 20 ascension levels that scale difficulty:
- Enemy HP: +15% per level
- Enemy damage: +10% per level
- Enemy speed: +3% per level
- Gold drops: -2% per level (min 50%)

### Codex

Discovery-based encyclopedia tracking skills, supports, passives, and enemies encountered during runs. Auto-discovers entries on acquisition/kill via GameBus signals.

### Save/Resume

Active runs are serialized to `user://active_run.json` including all state: stage, gold, skills with supports and mutations, passives, consumables, support quality, shop bonuses, reroll cost, run stats, and stage tree. Resume from main menu.

### Unlock Tree

Visual tree UI showing unlock paths and conditions.

---

## Architecture

### Singletons (autoloads)

| Singleton | Role |
|-----------|------|
| **GameBus** | Global signal bus — `enemy_killed`, `enemy_hit`, `stage_cleared`, `gold_changed`, `player_died`, `run_ended`, `skill_acquired`, `support_acquired`, `passive_acquired`, `codex_discovered` |
| **RunManager** | Run state — stage counter, gold, owned supports/passives/consumables, skill slots, support quality, shop bonuses, reroll cost, run stats, save/load |
| **InputManager** | Touch/keyboard abstraction — exposes `movement_vector` |
| **BehaviorRegistry** | Maps behavior keys to GDScript classes. 19 registered behaviors |
| **MetaProgression** | Persistent unlock state, ascension level, codex entries. Saved to JSON |

### Entry Point

`main.tscn` → `Main` node holds `GameManager`. Main menu triggers `GameManager.start_run()`, which opens skill picker then loops through the stage map tree.

### GameManager States

`MENU → STAGE_MAP → COMBAT → REWARD → SHOP → RUN_END`

### Scene / Script Split

- `scenes/` — .tscn files for visuals/physics
- `scripts/` — .gd files for logic
- `resources/` — .tres data files for skills, supports, passives, unlocks, consumables, regions, config

---

## Shop Economy

### Item Costs

| Type | Common | Uncommon | Rare | Legendary |
|------|--------|----------|------|-----------|
| Skill | 15g | 20g | 25g | — |
| Support | 8g | 12g | 15g | — |
| Passive | 10g | 15g | 20g | 40g |

### Stat Upgrades (repeatable)

| Upgrade | Base Cost | Cost Step | Amount |
|---------|-----------|-----------|--------|
| Flat Damage | 30g | +10g | +5 damage to all skills |
| Haste | 35g | +12g | -8% cooldown |
| Precision | 40g | +15g | +4% crit chance |

### Reroll

Starts at 2g, +1g each reroll. Cost persists across stages, resets on new run.

### Legendary Drops

From stage 5+, 1/15 chance a legendary passive appears in shop offerings.

---

## Player

- **Movement**: 250 speed via `InputManager.movement_vector`, clamped to arena bounds
- **HP**: 100 base, 0.5s invincibility frames after hit, white flash on damage
- **God mode**: debug toggle via meta flag
- **Visual**: blue circle (r=16)

---

## UI

| Screen | Description |
|--------|-------------|
| **Splash Screen** | Entry splash |
| **Main Menu** | Start, resume, region select, codex, unlock tree |
| **Skill Picker** | Choose starting skill at run start |
| **Stage Map** | Branching tree of stage nodes to choose path |
| **Stage Choice** | Node details before entering |
| **HUD** | HP bar, gold counter, stage label, combo counter, consumable buttons |
| **Minimap** | Player + enemy dots on arena overview |
| **Shop** | 8 offerings (skills/supports/passives/stat upgrades), reroll, manage button, link panel |
| **Skill Manager** | Drag supports between skill slots |
| **Reward Picker** | Post-combat reward selection |
| **Mutation Picker** | Post-boss skill mutation selection |
| **Legendary Picker** | Post-boss legendary passive selection |
| **Run Summary** | Victory/defeat, new unlocks, play again |
| **Codex** | Discovery encyclopedia |
| **Unlock Tree** | Visual unlock progression |
| **Debug Menu** (F1) | FPS, stats, kill all, +gold, heal, +crit, god mode, skip stage, add all supports |
| **Damage Numbers** | Floating text on hit (crit = larger/different color) |

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
Enemies:      200px aggro, 80 speed, 20 HP, 10 contact dmg, 1 gold, 0.3 wander mult
Spawning:     40/stage, groups 4-6, 40px spread, 50px margin, 200px min from player
Scaling:      +5 HP/stage, +5 enemies/stage, boss every 3 stages
Camera:       3.0/1.5 shake, 0.15s duration, 0.03s hit stop
Depth:        10 stages, bosses at 5 and 10
Modifiers:    swift +30% speed, tough +50% HP, swarming +50% count,
              deadly +40% dmg, enriched 2x gold, cursed -20% player speed
```

---

## Performance (Mobile)

- **Object pooling** for all projectiles and enemies — never instantiate/free in hot path
- **Trigger guard** prevents infinite cascade from on_hit/on_kill chains
- **Stat recomputation** only when supports/mutations change (shop phase), not per-frame
- **Target:** 60fps on mid-range Android/iOS devices
- **Resolution:** Design at 1080x1920 portrait

---

## Project Structure

```
scripts/
  autoloads/         game_bus, run_manager, input_manager, behavior_registry, meta_progression
  behaviors/         behavior_base + 19 concrete behaviors, passive_behaviors
  combat/            combo_tracker, synergy_tracker, mutation_data, engine_tracker,
                     trigger_guard, consumable_manager, skill_totem, skill_mine
  enemies/           enemy_base, basic_ranged, mini_boss, swarm_enemy, tank_enemy,
                     spawner, enemy_projectile
  main/              main, game_manager
  player/            player
  resources/         skill_resource, support_resource, passive_resource,
                     unlock_condition_resource, consumable_resource, region_resource, game_balance
  skills/            skill_instance, skill_caster, targeting, projectile_base,
                     orbit_skill, aoe_skill_base, vortex
  stages/            arena, camera_shake, spawn_formation, stage_data,
                     stage_generator, stage_tree
  ui/                hud, shop, skill_manager, skill_picker, main_menu, run_summary,
                     minimap, virtual_joystick, damage_number, debug_menu,
                     combo_display, stage_map, stage_choice, reward_picker,
                     mutation_picker, legendary_picker, consumable_hud,
                     unlock_tree, codex, splash_screen, ui_theme, divider_line
  util/              stat_calculator, tag_matcher, tag_colors, tag_interactions,
                     combat_utils, combat_log, object_pool, resource_listing

scenes/
  main/              main.tscn, game_manager.tscn
  stages/            arena.tscn
  player/            player.tscn
  enemies/           base_enemy, basic_melee, basic_ranged, mini_boss,
                     tank_enemy, swarm_enemy, enemy_projectile
  skills/            fireball, lightning_bolt, poison_dart, flame_wave,
                     static_field, blade_spin
  ui/                shop, skill_manager, skill_picker, main_menu, run_summary,
                     hud, virtual_joystick, codex, unlock_tree, stage_choice,
                     reward_picker, mutation_picker, legendary_picker

resources/
  skills/            6 skill .tres
  supports/          24 support .tres
  passives/          29 passive .tres
  unlocks/           19 unlock condition .tres
  consumables/       8 consumable .tres
  regions/           3 region .tres
  config/            game_balance.tres, default_theme.tres
```
