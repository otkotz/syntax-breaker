# Mobile-First Evolutions and Memetic Supports Design

**Date:** 2026-10-10  
**Status:** Awaiting written-spec review  
**Target:** Mobile-first top-down 2D build, portrait 1080×1920

## Goal

Make Syntax Breaker's build crafting immediately visible, surprising, and shareable. The first
milestone replaces Blade Spin with a positional boomerang skill, adds behavior-changing supports,
introduces three-tier capstone evolutions for every skill, and makes terminal risk determine reward
quality. Touch UI, portrait readability, and phone performance are first-class constraints. Safety
limits against infinite recursion and runaway entity counts remain mandatory on every platform.

Success means that a viewer can distinguish strong builds without opening a statistics screen,
terminal risk is legible before combat begins, and every offered evolution is an upgrade rather than
a sidegrade or downgrade.

## Scope

This milestone includes:

- randomized, tiered terminal difficulty and corresponding encounter composition;
- a dedicated evolution state and catalog with tiers I–III;
- save, resume, telemetry, UI, and damage-attribution support for evolutions;
- replacement of Blade Spin's gameplay with the Rollback boomerang while preserving its internal ID;
- six universal behavior-changing supports;
- one signature support for each of the seven skills;
- one three-tier evolution path for each of the seven skills;
- a portrait test gallery for rapidly previewing every terminal, support, skill, and evolution tier;
- automated coverage for compatibility, recursion limits, persistence, and build validity.

This milestone does not include arena devices beyond the compilation terminal, dash/near-miss
movement, challenge progression, wholesale renaming of the existing support catalog, or a 3D
conversion. Those remain later roadmap items.

## Design Principles

Every new support must satisfy at least two of these conditions:

1. It changes player positioning or target selection.
2. It creates a new interaction with another support or evolution.
3. Its effect is immediately recognizable while watching gameplay.

Flat statistics may support a behavior, but cannot be the entire new mechanic. Effects must retain
clear ownership for damage reports and must not recursively trigger themselves without an explicit,
bounded rule.

## Terminal Difficulty

### Test mode

During initial testing, every terminal independently selects one difficulty with equal probability:

- `Compile`
- `Overclock`
- `Kernel Breach`

The selected difficulty is displayed before proximity activation commits the player to the event.
The player cannot reroll or change it. The uniform distribution exists to expose all content quickly;
it is not the production balance.

### Production weighting

Production weights will later depend on run depth, node type, and Ascension. Initial target weights:

| Difficulty | Early run | Mid run | Late run |
|---|---:|---:|---:|
| Compile | 75% | 40% | 15% |
| Overclock | 23% | 45% | 45% |
| Kernel Breach | 2% | 15% | 40% |

Elite and boss nodes promote the result by one tier, capped at Kernel Breach. Ascension shifts weight
toward harder results but never reduces reward quality for equivalent risk.

### Encounter definitions

| Difficulty | Composition | Zone | Outside grace | Reward quality |
|---|---|---|---:|---|
| Compile | 24 normal/special enemies | Current size | 3 s | Mostly tier I |
| Overclock | 32 enemies including elites | Smaller | 2 s | Mostly tier II; small tier III chance |
| Kernel Breach | 40 enemies, elites, and a miniboss | Smallest | 1 s | Tier II–III only |

Activating a terminal starts its wave. Remaining outside the zone beyond the grace period destroys
the terminal permanently. A failed terminal never grants a reward and cannot be retried. Normal stage
budget and terminal-wave budget remain separately tracked, while every living terminal enemy blocks
encounter completion.

Telemetry records difficulty, stage depth and type, Ascension, wave size, result, completion time,
time spent outside, offered evolution tiers, chosen skill, and chosen tier.

## Evolution Model

Evolutions are separate from mutations and supports. `SkillInstance` gains:

- `evolution_id: String`
- `evolution_tier: int` constrained to `0..3`

`EvolutionData` owns definitions, compatibility rules, offer generation, and tier payloads. Evolution
effects are applied after supports and mutations, then final stat bounds are enforced. Behavior-level
effects are built as isolated components rather than added to one central match statement.

Offer rules:

- a skill has at most one main evolution;
- an offer must improve the current tier;
- duplicate and downgrade offers are forbidden;
- Kernel Breach may award tier III directly;
- if every owned skill is tier III, terminal fallback rewards are rare supports or an additional
  support slot; the picker must never be empty;
- support behavior remains active after evolution;
- evolution tier and ID persist through save/resume and are included in run summaries.

## Evolution Catalog

### Fireball — Solar Flare

- **I:** Impact creates a short-lived miniature sun that damages nearby enemies.
- **II:** The sun orbits locally and fires at nearby targets.
- **III:** Expiration triggers a supernova, with source attribution preserved as Solar Flare.

### Flame Wave — Firewall Breach

- **I:** The wave leaves a burning path.
- **II:** It returns once after reaching the arena boundary.
- **III:** Returning waves create intersecting firewalls across the arena.

### Frost Nova — Absolute Zero

- **I:** Frozen enemies shatter on death.
- **II:** Shards chill and freeze new targets.
- **III:** Shattering may propagate through an entire packed group, subject to a generation cap.

### Lightning Bolt — Cloud Outage

- **I:** Hits leave temporary lightning rods.
- **II:** Nearby rods connect with damaging arcs.
- **III:** The full network periodically strikes every enemy crossing its links.

### Poison Dart — Ransomware

- **I:** Poisoned enemies become visible carriers that spread poison.
- **II:** Carrier death fires poisoned darts at nearby targets.
- **III:** Eligible elites below a health threshold are briefly hijacked and attack enemies. Bosses
  cannot be hijacked.

### Static Field — Daemon Process

- **I:** The field detaches from the player.
- **II:** It seeks the densest nearby enemy group.
- **III:** Kills periodically spawn capped, short-lived child fields.

### Rollback — Recursive Rollback

- **I:** Return travel deals increased damage.
- **II:** Return travel replays recorded hits in reverse order.
- **III:** Catching the boomerang launches two smaller bounded copies in opposite directions.

## Blade Spin Migration to Rollback

The resource ID remains `blade_spin` to preserve saved builds and unlock references. Its display name,
description, icon, tags, scene, and behavior change. New tags are `projectile`, `aoe`, and `physical`.

Rollback follows an explicit state machine:

`outbound -> turn -> returning -> caught`

It travels toward an automatically selected enemy group, pierces targets, turns at maximum range,
and can hit a target once outbound and once returning. Return damage is higher. The player can move
to reshape the return line. The projectile records its path and ordered hits for Undo History and
Recursive Rollback.

The existing `Returning` support causes a second outbound-return cycle instead of becoming redundant.
The old orbit scene remains available until save migration and regression tests pass, then becomes
unused rather than being destructively deleted during the first implementation pass.

## New Universal Supports

### Copy / Paste

Replays the last eligible cast after a short delay along its original direction. Copies carry a
generation marker and cannot create further Copy / Paste copies.

### Spaghetti Code

On hit, a projectile redirects toward a random valid target. Each redirect increases damage and size.
Redirect count is capped and cannot revisit the immediately previous target.

### Lag Spike

An eligible hit briefly stops a normal enemy and repeats part of the hit after one second. Bosses use
a slow instead of a full stop. The delayed hit cannot schedule another Lag Spike.

### Alt + F4

Executes normal enemies below 12% health and elites/bosses below 3%. Execution is based on health
after the triggering hit and is recorded as support damage. Scripted invulnerability phases override
execution.

### Works on My Machine

Each cast randomly receives exactly one positive mode: increased size, additional projectiles,
guaranteed critical hit, or immediate cooldown recovery. It never rolls a penalty. The chosen mode is
visually announced and stored with the cast so every spawned child uses the same result.

### Rubber Duck Debugging

Three consecutive eligible hits from the linked skill mark a target as debugged. Debugged targets
receive increased damage from all sources for a limited duration and display a pixel duck marker.
Changing targets resets that skill's hit streak. Boss duration is reduced, but the effect remains
useful.

## Signature Supports

| Skill | Support | Behavior |
|---|---|---|
| Fireball | Firewall | Connects the player-to-impact line with a temporary burning wall. |
| Flame Wave | Reply All | The first enemy hit by a cast emits one smaller wave in a new direction. |
| Frost Nova | Frozen Process | Frost stores part of each hit and repeats the stored damage when the freeze ends. |
| Lightning Bolt | Wi-Fi Extender | Each chain step gains range; the last valid target receives a stronger discharge. |
| Poison Dart | Malware | Poison gains damage whenever its host attacks, casts, or charges. |
| Static Field | Background Process | An expired field continues briefly as a weaker ghost process. |
| Rollback | Undo History | The returning boomerang retraces its exact recorded route; evolution II additionally replays its original targets. |

The initial implementation adds these names and mechanics without immediately renaming every old
support. Candidate later renames include Faster Casting to Gaming Chair, Increased Area to Fullscreen
Mode, Pierce to Terms of Service, Split to Fork(), Shotgun to Reply All, Mine to Zip Bomb, Totem to
Remote Worker, Spell Echo to Double Click, Crit Explosion to Caps Lock, and Glass Cannon to Production
Build. Conflicts with the new signature `Reply All` name must be resolved before any catalog-wide
rename; the signature support owns that name in this milestone.

## Runtime Boundaries and Safety

Every derived attack carries:

- root cast ID;
- source skill ID;
- support/evolution source ID;
- recursion generation;
- flags for delayed, copied, reflected, or child effects.

Support behaviors declare whether they accept derived attacks. Copy and delayed effects do not
recursively reproduce themselves. Global caps remain for projectiles, fields, hazards, and child
effects. They scale with the existing device-quality preset, but every supported preset must preserve
the mechanic's identity. When a cap is reached, the game skips the least important new child effect
rather than removing an existing player-owned effect or blocking the main cast. Cosmetic particles
degrade before gameplay objects.

Boss invulnerability, missing targets, exhausted evolution pools, and destroyed terminals fail
closed: no reward duplication, no invalid attack, and no stuck picker. Invalid saved evolution IDs are
discarded with a warning while the base skill remains usable.

## UI and Feedback

The terminal displays its rolled difficulty before activation using color, name, encounter summary,
and likely reward tier. Activation remains proximity-based and irreversible, so no small interaction
button is required during movement.

Evolution offers display:

- skill artwork and name;
- evolution name;
- offered tier and current-to-new tier transition;
- concise behavior description rather than raw multipliers;
- a preview icon for the signature effect.

Combat feedback includes distinct source-colored effects, short labels for major procs, evolution
tier in the skill manager, and separate damage attribution in the run summary. Evolution cards use
the existing portrait card language, maintain touch targets of at least 96 px at the 1080×1920 design
resolution, and never require hover. Long descriptions wrap or scroll without shrinking body text.
Effects must remain distinguishable behind the player's thumbs and inside the portrait camera view.

## Test Gallery

A developer-only portrait scene provides touch selectors for:

- skill;
- linked support set;
- evolution tier;
- terminal difficulty;
- enemy formation and density.

It can trigger casts, terminal waves, and evolution upgrades without completing a run. It uses actual
production resources and behaviors rather than test doubles and is excluded from normal progression.
It supports mouse input in the editor and touch input on an Android device.

## Verification

Automated verification covers:

- approximately uniform test-mode terminal selection over a seeded sample;
- exact wave composition and terminal failure rules per difficulty;
- reward tiers compatible with terminal difficulty;
- no duplicate, downgrade, or empty evolution offer;
- save/resume of evolution ID and tier;
- Rollback outbound, turn, return, catch, double-hit, and moving-player trajectory;
- support compatibility and rejection reasons;
- damage ownership for copied, delayed, child, and evolution effects;
- recursion-generation and active-object caps;
- all legal skill/support/evolution combinations through the native build audit;
- existing encounter, damage, save-integrity, catalog, and route suites;
- project parse, Android export, installation on the test phone, and a manual portrait gallery pass;
- sustained device performance during the densest legal Kernel Breach build, including thermal and
  frame-time observation rather than only a desktop frame-rate check.

The initial terminal weights and balance numbers remain test hypotheses. Telemetry and playtests decide
production weights after all variants are observable.

## Implementation Order

1. Add evolution data, `SkillInstance` state, serialization, telemetry, and offer validation.
2. Add randomized terminal difficulty, three encounter definitions, and reward tier weighting.
3. Replace Blade Spin runtime behavior with Rollback while preserving resource identity.
4. Add the six universal supports and their recursion/source metadata.
5. Add the seven signature supports.
6. Add three evolution tiers for all seven skills.
7. Add the portrait test gallery, full catalog audit, Android export/install verification, and manual
   phone visual/performance pass.

Each step begins with failing behavior tests and ends with the relevant native regression suites. No
step may weaken compatibility validation, touch usability, portrait readability, or device safety
caps. PC-specific presentation and uncapped spectacle are deferred until the mobile milestone passes.
