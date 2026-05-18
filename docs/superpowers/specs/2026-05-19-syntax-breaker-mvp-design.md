# Syntax Breaker — MVP Design Spec

## Overview

2D top-down roguelite with auto-aim combat, inspired by Binding of Isaac (run structure), Brotato (auto-aim pacing), and Path of Exile (skill/support/tag system). The core hook is emergent build variety through a tag-based skill + support modifier system where supports link to skills via tag matching, creating thousands of possible combinations from a small content set.

**Engine:** Godot 4 / GDScript
**Platform:** Mobile-first (Android/iOS), PC port later
**Orientation:** Portrait (1080×1920)
**Target run time:** 12–15 minutes
**Scope:** Solo developer

---

## Core Gameplay Loop

```
Character Select → Stage 1 → Shop → Stage 2 → Shop → ... → Stage 5 → Final Boss → Run End
                                      ↑ mini-boss on stages 3 & 5
```

### Within a Stage

1. Player spawns in a portrait-oriented arena
2. Enemies spawn in waves (3–5 waves per stage, escalating)
3. Player's equipped skills auto-fire at targets based on proximity/priority
4. Enemies drop gold (shop currency) and occasionally consumables (health)
5. Stage ends when all waves are cleared
6. Mini-boss appears on stages 3 and 5

### Shop Phase (Between Stages)

- Spend gold on: new skills, support modifiers, passive upgrades, reroll
- Manage skill loadout: rearrange supports between skills, swap active skills
- Full-screen overlay with large tap targets, vertical scrollable card list
- New skill slots unlock at stages 2 and 4 (1 → 2 → 3; 4th slot from boss drop or late shop)

### Pacing

- Each stage: ~90 seconds of combat
- Shop phase: ~30 seconds
- Full run (5 stages + boss): ~12–15 minutes
- Death = run over, earn meta-currency based on progress

### Run End → Meta Screen

- See unlocked items (new skills/supports added to future run pools)
- Return to character select

---

## Controls & Input

### Mobile (Primary)

- **Movement:** Floating virtual joystick, left thumb area (bottom-left quadrant). Appears where thumb touches.
- **Aiming:** Auto-aim — skills target nearest/priority enemies automatically
- **Casting:** Auto-cast — skills fire when off cooldown, no buttons needed
- **Right thumb area:** Reserved for future manual abilities (post-MVP)
- **UI interaction:** Tap for shop/menus, drag-and-drop for support linking with generous hit areas

### Input Architecture

`InputManager` autoload abstracts input source. Emits a normalized movement vector regardless of source (joystick, keyboard). Makes PC port trivial — swap joystick for WASD/arrow keys, same API downstream.

### Screen Layout (Portrait)

```
┌─────────────┐
│   HP / Gold  │  ← top HUD
│             │
│             │
│   ARENA     │  ← upper ~70%, gameplay
│             │
│             │
│  cooldowns  │  ← bottom-center, visible
│ [joy]       │  ← joystick zone, bottom-left
└─────────────┘
```

---

## Skill Architecture (Resource-Driven)

### Design Philosophy

Skills and supports are defined as Godot Resource files (`.tres`). Resources hold data (stats, tags, modifiers). Scenes hold visuals and physics. At runtime, a `SkillInstance` composes a skill resource + its linked supports into computed stats and behaviors.

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
  max_supports: int             # 2 (support slot count)
  scene_path: String            # "res://scenes/skills/fireball.tscn"
  icon: Texture2D
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
  behavior_key: String          # "chain" — maps to behavior script, or "" for stat-only
  icon: Texture2D
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
  rarity: String
  description: String
```

### SkillInstance (Runtime)

Composes base skill + linked supports at runtime:

```
SkillInstance:
  base: SkillResource
  linked_supports: Array[SupportResource]
  computed_stats: Dictionary        # recalculated when supports change

  get_final_damage() → base.damage * support_mults * passive_mults
  get_behaviors() → Array[Behavior] # collected from base + all linked supports
```

### Stat Computation Pipeline

1. Start with base skill stats
2. Apply each linked support's `stat_modifiers` (multiplicative stacking)
3. Apply global passives that match the skill's tags
4. Clamp to min/max bounds

---

## Tag Interaction System

### Tags (MVP)

| Tag | Meaning |
|-----|---------|
| `projectile` | Spawns a moving entity toward target |
| `fire` | Fire element |
| `lightning` | Lightning element |
| `poison` | Poison/DoT element |
| `aoe` | Area of effect |
| `melee` | Close-range / around player |
| `summon` | Creates persistent entity (post-MVP, tag exists for supports) |
| `chain` | Can bounce between targets (added by Chain support) |

### Matching Rules

- **Support → Skill:** A support can link to a skill if the skill has ANY of the support's `required_tags` AND NONE of the `excluded_tags`
- **Passive → Skill:** A passive boosts any skill with ANY of the passive's `affected_tags`
- **Tag addition:** Some supports add tags to a skill (e.g., Chain support adds `chain` tag), making it eligible for additional passives

### Emergent Combos

These emerge from tag matching + behavior hooks with zero special-case code:

- Fireball + Chain + Crit Explosion = bouncing fireballs that explode on crit
- Poison Dart + Split + Poison on Hit = triple poison darts stacking DoT
- Lightning Bolt + Chain + Faster Casting = rapid chain lightning
- Flame Wave + Increased Area + Elemental Proliferation = massive fire wave that spreads on kill
- Blade Spin + Crit Explosion + Faster Casting = spinning blades with explosions

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

### Registry

```
BehaviorRegistry (autoload):
  "chain"                    → ChainBehavior.gd
  "split"                    → SplitBehavior.gd
  "pierce"                   → PierceBehavior.gd
  "increased_area"           → IncreasedAreaBehavior.gd
  "crit_explosion"           → CritExplosionBehavior.gd
  "poison_on_hit"            → PoisonOnHitBehavior.gd
  "elemental_proliferation"  → ElementalProliferationBehavior.gd
```

---

## MVP Content

### Skills (6)

| Skill | Tags | Behavior |
|-------|------|----------|
| Fireball | projectile, fire | Single projectile, explodes on hit |
| Lightning Bolt | projectile, lightning | Fast projectile, small AoE on hit |
| Poison Dart | projectile, poison | Slow projectile, applies DoT |
| Flame Wave | aoe, fire | Cone/wave around player, short range |
| Static Field | aoe, lightning | Pulse around player, hits all nearby |
| Blade Spin | melee, aoe | Spinning blades orbit player |

### Supports (8)

| Support | Required Tags | Effect |
|---------|--------------|--------|
| Chain | projectile | Bounces to 3 nearby enemies, −20% dmg per bounce |
| Split | projectile | Fires 2 extra projectiles at slight angles, −30% dmg |
| Pierce | projectile | Passes through 2 enemies |
| Increased Area | aoe | +40% area radius |
| Faster Casting | (none — links to any skill) | −25% cooldown |
| Elemental Proliferation | fire, lightning, poison | On kill, spreads elemental debuff/DoT to nearby enemies |
| Crit Explosion | (none — links to any skill) | Crits create small AoE explosion |
| Poison on Hit | projectile, melee | Adds poison DoT to hits |

### Passives (5)

| Passive | Affected Tags | Effect |
|---------|--------------|--------|
| Fire Mastery | fire | +20% fire damage, −10% cooldown |
| Storm Conduit | lightning | +15% damage, +10% area |
| Toxic Resilience | poison | +15% poison damage, +5% heal on poison kill |
| Projectile Expert | projectile | +10% speed, +1 pierce |
| Thick Skin | (global) | +15% max HP |

### Enemies (MVP)

- **Basic Melee:** Walks toward player, deals contact damage
- **Basic Ranged:** Keeps distance, fires slow projectiles
- **Mini-Boss:** Larger enemy with telegraph attacks, guaranteed rare drop

---

## Meta-Progression

### Pool Expansion Model

New skills/supports/passives unlock into the run pool as the player achieves milestones. No permanent stat upgrades — veteran players have more options, not more power.

### Starter Pool (First Run)

- Skills: Fireball, Lightning Bolt, Blade Spin
- Supports: Pierce, Faster Casting, Poison on Hit
- Passives: Thick Skin

### Unlock Conditions

| Unlock | Condition |
|--------|-----------|
| Poison Dart | Reach Stage 3 |
| Flame Wave | Kill 50 enemies in one run |
| Static Field | Kill a mini-boss |
| Chain | Complete a run (beat final boss) |
| Split | Use 3 different projectile skills in one run |
| Increased Area | Kill 10 enemies with a single AoE cast |
| Crit Explosion | Land 50 critical hits in one run |
| Elemental Proliferation | Kill 3 enemies with a single DoT spread |
| Fire Mastery | Deal 1000 cumulative fire damage |
| Storm Conduit | Deal 1000 cumulative lightning damage |
| Toxic Resilience | Apply poison to 100 enemies |
| Projectile Expert | Fire 500 projectiles |

### Data Model

```
UnlockCondition (Resource):
  id: String
  item_type: String          # "skill", "support", "passive"
  item_id: String
  condition_type: String     # "complete_run", "reach_stage", "kill_count", etc.
  condition_params: Dictionary
  description: String
```

### Implementation

`MetaProgression` autoload persists unlocked items as a JSON save file. Unlocks are checked at run-end against run statistics tracked by `RunManager` (enemies killed, damage by tag, stages reached, etc.). Shop and drop pools filter to only include unlocked items.

---

## Project Structure

```
syntax-breaker/
├── project.godot
├── CLAUDE.md
├── docs/
│
├── scenes/
│   ├── main/
│   │   ├── main.tscn                  # entry point, scene manager
│   │   └── game_manager.tscn          # run state, stage flow
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── skills/                        # one scene per skill
│   │   ├── fireball.tscn
│   │   ├── lightning_bolt.tscn
│   │   ├── poison_dart.tscn
│   │   ├── flame_wave.tscn
│   │   ├── static_field.tscn
│   │   └── blade_spin.tscn
│   ├── enemies/
│   │   ├── base_enemy.tscn
│   │   ├── basic_melee.tscn
│   │   ├── basic_ranged.tscn
│   │   └── mini_boss.tscn
│   ├── stages/
│   │   ├── arena.tscn                 # reusable arena template
│   │   └── boss_arena.tscn
│   └── ui/
│       ├── hud.tscn                   # HP, cooldowns, gold
│       ├── shop.tscn                  # between-stage shop
│       ├── skill_manager.tscn         # support linking UI
│       ├── virtual_joystick.tscn      # touch joystick
│       └── run_summary.tscn           # end-of-run screen
│
├── scripts/
│   ├── autoloads/
│   │   ├── game_bus.gd                # global signal bus
│   │   ├── run_manager.gd             # run state: stage, gold, inventory
│   │   ├── input_manager.gd           # abstracts joystick/keyboard → movement vector
│   │   ├── behavior_registry.gd       # maps behavior_key → script
│   │   └── meta_progression.gd        # unlock tracking, save/load
│   ├── skills/
│   │   ├── skill_instance.gd          # runtime: base + supports → computed stats
│   │   ├── skill_caster.gd            # attached to player, manages auto-fire
│   │   └── targeting.gd               # nearest-enemy, priority targeting
│   ├── behaviors/
│   │   ├── behavior_base.gd           # interface
│   │   ├── chain_behavior.gd
│   │   ├── split_behavior.gd
│   │   ├── pierce_behavior.gd
│   │   ├── increased_area_behavior.gd
│   │   ├── crit_explosion_behavior.gd
│   │   ├── poison_on_hit_behavior.gd
│   │   └── elemental_proliferation_behavior.gd
│   ├── enemies/
│   │   ├── enemy_base.gd
│   │   └── spawner.gd                 # wave spawning logic
│   └── util/
│       ├── stat_calculator.gd         # stat composition pipeline
│       └── object_pool.gd             # pooling for projectiles/enemies
│
├── resources/
│   ├── skills/                        # .tres data files
│   ├── supports/
│   ├── passives/
│   ├── enemies/
│   └── stages/
│
└── assets/
    ├── sprites/
    ├── audio/
    └── fonts/
```

---

## Performance (Mobile)

- **Object pooling** for all projectiles and enemies — never instantiate/free in hot path
- **Entity cap:** ~150 enemies on screen maximum
- **Particle budget:** Simpler effects than PC, fewer particles per effect
- **Target:** 60fps on mid-range Android/iOS devices
- **Resolution:** Design at 1080×1920 portrait, scale down for lower-end devices
- **Stat recomputation:** Only recalculate `SkillInstance` stats when supports change (shop phase), not per-frame

---

## Scope Boundaries (What's NOT in MVP)

- No summon skills (tag exists, skills are post-MVP)
- No character selection (1 default character)
- No permanent stat upgrades
- No daily challenges or leaderboards
- No PC input support (architecture ready, not wired)
- No tutorial (implicit learning through starter pool simplicity)
- No sound/music (placeholder or silent)
- No localization
